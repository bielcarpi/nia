import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class BucketRepository {
  static BucketRepository instance = BucketRepository._();
  BucketRepository._();

  Future<String?> uploadImage(File imageFile) async {
    try {
      // Create a unique filename for the image
      String fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      // Upload the image to Firebase Storage with the unique filename
      Reference firebaseStorageRef =
      FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Return the download URL of the uploaded image
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print(e);
    }

    return null;
  }
}
