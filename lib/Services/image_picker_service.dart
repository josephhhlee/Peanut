import 'dart:io';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'dart:developer';
import 'package:peanut/Models/file_model.dart';
import 'package:peanut/Models/message_model.dart';
import 'package:peanut/Services/firebase_storage_service.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;

class ImagePickerService {
  static const int _limit = 16777216;

  static Future<List<LocalFile>> openGallery() async {
    Future<String?> buildThumbnail(FileType type, String path) async {
      String? thumbnail;
      if (type == FileType.video) {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: path,
          imageFormat: ImageFormat.JPEG,
          quality: 25,
        );
        if (thumbnailPath != null) thumbnail = File(thumbnailPath).path;
      }
      return thumbnail;
    }

    try {
      final List<LocalFile> value = [];
      final result = await picker.FilePicker.platform.pickFiles(allowMultiple: true, type: picker.FileType.media, allowCompression: true);
      final pahts = result?.paths;
      if (result == null || pahts == null) return [];

      for (final selected in result.paths) {
        if (selected == null) continue;

        final mimeType = lookupMimeType(selected);

        final type = (mimeType?.contains("video") ?? false) ? FileType.video : FileType.image;

        value.add(LocalFile(path: selected, type: type, thumbnail: await buildThumbnail(type, selected)));
      }

      return value;
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  static Future<void> uploadToStorage(Message message) async {
    Future<void> buildAndUploadAttachment(Attachment attachment) async {
      try {
        final list = attachment.type == FileType.image ? await _compressImage(attachment.path!) : await _compressVideo(attachment.path!);
        if (list == null) {
          attachment.status = MessageStatus.failed;
          return;
        }

        final image = img.decodeImage(attachment.type == FileType.image ? list : File(attachment.thumbnail!).readAsBytesSync());
        if (image == null) {
          attachment.status = MessageStatus.failed;
          return;
        }
        attachment.blurHash = BlurHash.encode(image).hash;

        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final type = attachment.type == FileType.image ? FirebaseStorageService.imageType : FirebaseStorageService.videoType;
        final snapshot = await FirebaseStorageService.chatMediaRef(message.chatId, fileName).putData(list, type);
        final url = await snapshot.ref.getDownloadURL();
        attachment.url = url;
      } catch (e) {
        log(e.toString());
        attachment.status = MessageStatus.failed;
      }
    }

    for (Attachment attachment in message.attachments!) {
      await buildAndUploadAttachment(attachment);
    }

    final newAttachments = List<Attachment>.from(message.attachments!);
    newAttachments.retainWhere((element) => element.status != MessageStatus.failed);
    message.attachments = newAttachments;
  }

  static Future<Uint8List?> _compressImage(String path) async {
    try {
      Uint8List list = File(path).readAsBytesSync();
      if (list.lengthInBytes <= _limit) return list;

      while (list.lengthInBytes > _limit) {
        list = await FlutterImageCompress.compressWithList(
          list,
          quality: 80,
        );
      }

      return list;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  static Future<Uint8List?> _compressVideo(String path) async {
    try {
      Uint8List list = File(path).readAsBytesSync();
      if (list.lengthInBytes <= _limit) return list;

      MediaInfo? mediaInfo;
      while ((mediaInfo?.filesize ?? (_limit + 1)) > _limit) {
        mediaInfo = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.MediumQuality,
          includeAudio: true,
        );
        print("FILE SIZE IS ${mediaInfo?.filesize ?? 0}");
        if (mediaInfo == null) return null;
      }
      return mediaInfo?.file?.readAsBytesSync();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }
}
