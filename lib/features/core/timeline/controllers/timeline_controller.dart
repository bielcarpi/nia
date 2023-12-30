import 'package:get/get.dart';

class Conversation {
  DateTime date;
  String topic;

  Conversation({required this.date, required this.topic});
}

class TimelineController extends GetxController {
  // Hem d'omplir la llista amb les dades de Firebase
  final RxList<Conversation> conversations = RxList();

  @override
  void onInit() {
    super.onInit();
    // Aquí hem de cargar els chats guardats
    loadConversations();
  }

  // Exemple de com quedaria
  void loadConversations() {
    var now = DateTime.now();
    conversations.addAll([
      Conversation(date: now, topic: 'About holidays'),
      Conversation(date: now.subtract(Duration(days: 1)), topic: 'About school'),
    ]);
  }
}
