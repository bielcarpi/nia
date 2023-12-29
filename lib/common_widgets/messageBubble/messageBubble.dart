import 'package:flutter/material.dart';
import 'package:nia_flutter/constants/colors.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser; // true -> usuari, false -> nia

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isUser ? messageBubble : Colors.grey,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: thirdColor,
            ),
          ),
        ),
      ),
    );
  }
}
