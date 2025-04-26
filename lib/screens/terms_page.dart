import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos de Privacidad')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVISOS DE PRIVACIDAD',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Fecha de última actualización: 22 de abril de 2025\n',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              Text(
                'Bienvenidos al Prototipo de sistema web para enseñanza con recursos digitales y compartición en Facebook: caso UA Cálculo “Study Connect”, la cual opera en la dirección Web:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'El siguiente Aviso de Privacidad tiene como finalidad informarte sobre el tratamiento que se le dará a tus datos personales al utilizar el sistema web Study Connect, desarrollado como un prototipo educativo por estudiantes de la Escuela Superior de Cómputo (ESCOM) del Instituto Politécnico Nacional (IPN), con fines académicos.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Este prototipo recaba algunos datos personales con el propósito de ofrecer la mejor experiencia de enseñanza, fomentar la camaradería y la participación entre estudiantes, tutores y/o docentes. Te invitamos a leer los siguientes puntos para que estés consciente de cómo se manejarán tus datos.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '1. Recopilación de datos personales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Se recopilan datos al registrarse o utilizar el sistema:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Nombre Completo\n• Correo electrónico\n• Rol académico (estudiante, tutor, docente)\n• Ejercicios, comentarios y materiales subidos\n• Estadísticas de actividad de la plataforma',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),

              Text(
                '2. Uso de datos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Tu información será utilizada para:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Gestión de cuenta\n• Comunicación entre usuarios\n• Publicación de ejercicios\n• Comentarios y recompensas virtuales\n• Estadísticas internas de uso académico\n• Notificaciones relevantes dentro del sistema',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),

              Text(
                '3. Conservación y seguridad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Tus datos, archivos e información se almacenarán en Firebase, un servicio seguro integrado por Google, donde se aplican medidas técnicas y administrativas de protección. No obstante, ningún sistema puede garantizar una seguridad total.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),

              Text(
                '4. Acceso, modificación y eliminación de datos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Nuestros usuarios tienen todo el derecho a acceder, corregir o eliminar sus datos desde su perfil o enviando una solicitud al correo electrónico del responsable del proyecto.\n\nContacto: btorresm1802@alumno.ipn.mx',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),

              Text(
                '5. Cambios al aviso de privacidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Study Connect se reserva el derecho de actualizar este aviso. Cualquier cambio será notificado dentro de la plataforma y reflejado con una fecha de actualización.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
