import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:http/src/multipart_file.dart' as mpt;
import 'package:nia_flutter/utils/logs/logs.dart';

class APIRepository extends GetxController {
  static APIRepository get instance => Get.find();

  final API_URL = "https://nia-backend.oa.r.appspot.com/api/audio";

  Future<StreamedResponse?> sendAudioToServer(String filePath) async {
    var uri = Uri.parse(API_URL);
    var request = MultipartRequest('POST', uri)
      ..files.add(await mpt.MultipartFile.fromPath('audio', filePath));

    try {
      var response = await request.send();
      if (response.statusCode != 200) {
        Logs.e('Error occurred while sending audio: ${response.statusCode}');

        // Get the response body
        var responseBody = await response.stream.bytesToString();
        Logs.e('Response body: $responseBody');

        return null;
      }

      return response;
    } catch (e) {
      Logs.e('Error occurred while sending audio: $e');
      return null;
    }
  }
}
