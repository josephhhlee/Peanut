import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static final _storageRef = FirebaseStorage.instance.ref();

  static SettableMetadata imageType = SettableMetadata(contentType: "image/jpeg");
  static SettableMetadata videoType = SettableMetadata(contentType: "video/mp4");

  static Reference chatMediaRef(String chatId, String fileName) => _storageRef.child("chat/$chatId/media/$fileName");
}
