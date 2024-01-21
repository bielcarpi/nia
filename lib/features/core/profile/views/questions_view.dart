import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';


class questionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preguntas Frecuentes', style: TextStyle(color: primaryColor)),
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
                '¿Tienes preguntas sobre Nia y cómo funciona? Aquí encontrarás respuestas a algunas de las preguntas más comunes.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Qué es Nia y cómo puede ayudarme a aprender un nuevo idioma?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Nia es un asistente virtual basado en IA que te ayuda a practicar y mejorar tu dominio de un idioma secundario mediante '
                    'conversaciones interactivas y personalizadas. Utiliza la última tecnología de OpenAI para ofrecer una experiencia de aprendizaje '
                    'natural y efectiva.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Es gratuita la aplicación Nia?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'No, Nia es una aplicación de suscripción. Ofrecemos una experiencia completa y personalizada con Nia por un costo de 5,99 € al mes.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Cómo puedo cambiar el idioma en la aplicación?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Cambiar el idioma en Nia es tan sencillo como empezar a hablar en el idioma que deseas practicar. Nia está diseñada '
                    'para reconocer automáticamente el idioma en el que estás hablando y responderá en el mismo.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Puedo cancelar mi suscripción en cualquier momento?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Sí, puedes cancelar tu suscripción en cualquier momento. No hay contratos a largo plazo ni cargos ocultos.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Nia funciona sin conexión a internet?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Nia requiere una conexión a internet para acceder a la mayoría de sus funciones, ya que utiliza la nube para procesar '
                    'las respuestas y actualizar el contenido.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Cómo garantizan la seguridad y privacidad de mis datos?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Nos tomamos muy en serio la seguridad y privacidad de tus datos. Utilizamos medidas de seguridad de vanguardia para proteger '
                    'tu información y no compartimos tus datos personales con terceros.',
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
