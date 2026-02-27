import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:octo_image/octo_image.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Models/message_model.dart';
import 'package:peanut/Utils/common_utils.dart';

class PeanutFile {
  late final FileType type;
  late final String url;

  PeanutFile({required type});

  PeanutFile.fromJson(Map json) {
    type = FileType.values.firstWhere((element) => element.name == json["type"]);
    url = json["url"];
  }

  Map<String, dynamic> toJson() => {
        "type": type.name,
        "url": url,
      };

  void create(Transaction transaction, DocumentReference ref) {
    transaction.update(ref, {
      "attachment": FieldValue.arrayUnion([toJson()])
    });
  }
}

class PeanutMedia extends PeanutFile {
  late final String blurHash;

  PeanutMedia({required blurHash, required super.type});

  PeanutMedia.fromJson(Map json) : super.fromJson(json) {
    blurHash = json["blurHash"];
  }

  @override
  Map<String, dynamic> toJson() => {
        "type": type.name,
        "url": url,
        "blurHash": blurHash,
      };

  @override
  void create(Transaction transaction, DocumentReference ref) {
    transaction.update(ref, {
      "attachment": FieldValue.arrayUnion([toJson()])
    });
  }
}

class LocalFile {
  late final String? thumbnail;
  late final String path;
  late final FileType type;

  LocalFile({required this.path, required this.type, this.thumbnail});

  Attachment toAttachment() => Attachment(path: path, type: type, thumbnail: thumbnail);

  Widget toImage({double? size, BoxFit boxFit = BoxFit.cover}) {
    Widget placeHolder() => Container(
          height: size ?? double.infinity,
          width: size ?? double.infinity,
          color: PeanutTheme.black,
          child: CommonUtils.loadingIndicator(size: 15),
        );

    Widget errorImage() => Image.asset(
          "assets/image_not_found.png",
          height: size,
          width: size,
          fit: BoxFit.fitHeight,
        );

    Image provider = Image.file(
      type == FileType.video && thumbnail != null ? File(thumbnail!) : File(path),
      height: size,
      width: size,
      fit: boxFit,
    );

    return Stack(
      key: Key(path),
      alignment: Alignment.bottomLeft,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: OctoImage(
            image: provider.image,
            placeholderBuilder: (_) => placeHolder(),
            errorBuilder: (_, __, ___) => errorImage(),
            fit: boxFit,
          ),
        ),
        Container(
          width: 35,
          height: 30,
          padding: const EdgeInsets.only(left: 5, bottom: 5),
          alignment: Alignment.bottomLeft,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(topRight: Radius.circular(100)),
            color: PeanutTheme.almostBlack.withOpacity(0.9),
          ),
          child: Icon(
            type == FileType.image ? FontAwesomeIcons.image : FontAwesomeIcons.video,
            size: 14,
            color: PeanutTheme.white,
          ),
        ),
      ],
    );
  }
}

enum FileType {
  file,
  image,
  video,
}

extension FileTypeExtension on FileType {
  String get name => toString().split('.').last;
}
