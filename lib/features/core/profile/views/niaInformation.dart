import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';


class niaInformation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Información sobre Nia', style: TextStyle(color: primaryColor)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Bienvenido a Nia, tu Asistente de Inteligencia Artificial',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Nia es una avanzada asistente virtual impulsada por la tecnología de Inteligencia Artificial de OpenAI, diseñada para ayudarte a mejorar tu dominio en un idioma secundario a través de conversaciones interactivas y personalizadas.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                '¿Cómo Funciona Nia?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Nia utiliza la última versión de ChatGPT con tecnología OpenAI para entender y responder a tus preguntas en tiempo real. Con una mezcla de algoritmos de procesamiento de lenguaje natural y aprendizaje automático, Nia está programada para ofrecerte una experiencia de aprendizaje de idiomas rica y adaptativa.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                'Características Principales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                '\t1) Interactúa con Nia en tu idioma secundario. Cada conversación está diseñada para mejorar tu fluidez y comprensión.\n\n'
                    '\t2) Nia se adapta a tu nivel de habilidad y a tus intereses personales para hacer el aprendizaje más relevante y atractivo.\n\n'
                    '\t3) Recibe retroalimentación sobre tu uso del idioma, incluyendo pronunciación, gramática y vocabulario.\n\n'
                    '\t4) Participa en actividades y juegos lingüísticos diseñados para reforzar tu aprendizaje.\n\n'
                    '\t5) Practica con una variedad de idiomas, cada uno con su propio conjunto de lecciones y desafíos.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text(
                'Privacidad y Seguridad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Tu privacidad es nuestra prioridad. Las conversaciones con Nia son seguras y confidenciales, y nos adherimos a estrictas políticas de privacidad para proteger tus datos.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                'Sobre Nosotros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 10),
              Text(
                'Desarrollado por un equipo de estudiantes de la universidad La Salle URL. Nia es más que una aplicación; es tu compañera en el viaje hacia el dominio de un nuevo idioma.',
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
