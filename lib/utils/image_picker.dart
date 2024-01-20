import 'dart:io';

import 'package:image_picker/image_picker.dart';

class GalleryPicker {
  static Future<File?> selectImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }
}
