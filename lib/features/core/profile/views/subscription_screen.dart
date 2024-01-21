import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';


class subscriptionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscripción', style: TextStyle(color: primaryColor)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
              Text(
                'Información',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Ofrecemos una experiencia avanzada y personalizada para aquellos que desean llevar su aprendizaje al siguiente nivel. Por solo 5,99 € al mes, accede a características exclusivas y maximiza tu potencial de aprendizaje con Nia.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                'Características de la subscripción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                '\t1) Disfruta de interacciones ilimitadas con Nia para una práctica intensiva.\n\n'
                    '\t2) Aprende sin interrupciones para una experiencia más inmersiva.\n\n'
                    '\t3) Obtén respuestas rápidas y soporte dedicado cuando lo necesites.\n\n'
                    '\t4) Puedes practicar cualquier idioma del mundo.\n\n'
                    '\t5) Tecnologia IA para mejorar tu vocalización.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text(
                'Preguntas Frecuentes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                '¿Cómo se facturan las suscripciones?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Las suscripciones se facturan mensualmente y puedes cancelar en cualquier momento.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 10),
              Text(
                '¿Cómo cancelo mi suscripción?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Puedes cancelar tu suscripción fácilmente desde la configuración de tu cuenta en cualquier momento.',
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
