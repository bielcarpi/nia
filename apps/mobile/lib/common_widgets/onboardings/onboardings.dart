import 'package:flutter/cupertino.dart';

class OnboardingPage extends StatelessWidget {
  final Color color;
  final String title;
  final String description;
  final Color contentColor;
  final String imagePath;

  const OnboardingPage({
    required this.color,
    required this.title,
    required this.description,
    required this.contentColor,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: contentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(
            imagePath,
            height: 300,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              color: contentColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}