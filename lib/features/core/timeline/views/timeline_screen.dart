import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import '../controllers/timeline_controller.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(TimelineController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('auth.timeline.title'),
          style: TextStyle(
            color: primaryColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
              BubbleSpecialThree(
                text: tr('auth.timeline.nia'),
                isSender: false,
                color: Colors.blue,
                textStyle: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 20),
              BubbleSpecialThree(
                text: tr('auth.timeline.user'),
                isSender: true,
                color: Colors.grey.shade200,
                textStyle: TextStyle(color: Colors.black87, fontSize: 16),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
