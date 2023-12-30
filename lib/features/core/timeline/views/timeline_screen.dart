import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/home/views/bottom_navigation_bar.dart';
import 'package:nia_flutter/features/core/timeline/controllers/timeline_controller.dart';

class TimelineScreen extends GetView<TimelineController> {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: primaryColor,
      body: Obx(() {
        var sortedConversations = controller.conversations
          ..sort((a, b) => b.date.compareTo(a.date));
        return ListView.builder(
          itemCount: sortedConversations.length,
          itemBuilder: (context, index) {
            var conversation = sortedConversations[index];
            var showDateHeader = index == 0 ||
                sortedConversations[index - 1].date.day != conversation.date.day;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDateHeader)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _formatDate(conversation.date),
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                ListTile(
                  title: Text(conversation.topic),
                ),
              ],
            );
          },
        );
      }),
      bottomNavigationBar: CustomBottomNavigationBar(
        context: context
      ),
    );
  }


  String _formatDate(DateTime date) {
    var now = DateTime.now();
    var difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'Last week';
    }
  }
}
