import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';


class questionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('auth.questions.title'), style: TextStyle(color: primaryColor)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
              Text(
                tr('auth.questions.information.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.information.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                tr('auth.questions.q1.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.q1.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                tr('auth.questions.q2.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.q2.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                tr('auth.questions.q3.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.q3.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                tr('auth.questions.q4.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.q4.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                tr('auth.questions.q5.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.q5.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                tr('auth.questions.q6.subtitle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                tr('auth.questions.q6.description'),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
