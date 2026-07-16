import 'package:get/get.dart';
import 'package:nia_flutter/repository/user_repository/user_model.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  UserModel? _user;

  UserModel get user {
    return _user!;
  }

  @override
  void onInit() async {
    super.onInit();
    //TODO check if user is authenticated in AuthenticatedRepository. If so, load the user (loginUser() method)
  }

  Future<bool> createUser(String email, String name, {String? photoURL}) async {
    // TODO: On register, call this method to create a new user in firestore
    // TODO: If the creation fails, the register process should fail
    // TODO: (it's very important to delete the user from firebase auth if the creation fails)

    //TODO: Note some social providers will provide a photoURL, others won't.
    return false;
  }

  Future<bool> loginUser(String email) async {
    // TODO: On login, call this method to load the user from firestore and set it in the _user variable
    // TODO: If the retrieval from database fails, the login process should fail

    // TODO: This method will also be called from the onInit() method of this class if the user is already authenticated in the AuthenticationRepository
    return false;
  }

  Future<bool> updateUser({String? name, String? photoURL}) async {
    // TODO: Update the user fields in firestore (we don't update the email as it's the PK)
    return false;
  }
}
