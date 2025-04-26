import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y Condiciones')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TÉRMINOS Y CONDICIONES',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Fecha de última actualización: 23 de abril de 2025\n',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              Text(
                'Bienvenidos al Prototipo de sistema web para enseñanza con recursos digitales y compartición en Facebook: caso UA Cálculo “Study Connect”, la cual opera en la dirección Web.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Los siguientes Términos y Condiciones tienen como finalidad regular el acceso y uso de la plataforma educativa para la Escuela Superior de Cómputo (ESCOM) del Instituto Politécnico Nacional (IPN). Al acceder y utilizar la Aplicación, usted (Usuario: alumno, tutor o profesor) manifiesta su conformidad con estos Términos. Si no está de acuerdo con alguna sección de los mismos, deberá abstenerse de utilizar esta plataforma.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '1. Uso de la aplicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• Proporcionada como herramienta académica para la ESCOM-IPN.\n'
                '• El usuario se compromete a usarla con fines académicos.\n'
                '• Prohibido usarla con fines comerciales, ofensivos o difamatorios.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '2. Registro de Cuenta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• El usuario debe proporcionar datos reales.\n'
                '• Es responsable de la confidencialidad de su cuenta.\n'
                '• Debe notificar usos no autorizados.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '3. Contenido generado por el Usuario',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• El usuario garantiza tener derecho sobre lo que publica.\n'
                '• Autoriza a Study Connect a mostrarlo con fines académicos.\n'
                '• La plataforma puede eliminar contenido inapropiado.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '4. Propiedad intelectual',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• El sistema es propiedad del equipo desarrollador y el IPN.\n'
                '• No puede ser copiado o modificado sin autorización.\n'
                '• Se pueden incluir recursos de terceros bajo sus términos.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '5. Privacidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• El tratamiento de datos se rige por el Aviso de Privacidad.\n'
                '• Al usar la app, el usuario acepta este tratamiento.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '6. Limitación de responsabilidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• No se garantiza disponibilidad total del sistema.\n'
                '• No se asume responsabilidad por decisiones tomadas en base al contenido.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '7. Modificaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• Los términos pueden cambiar en cualquier momento.\n'
                '• Las actualizaciones se publicarán en la plataforma.\n'
                '• El uso continuado implica aceptación.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '8. Cancelación de cuenta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• El usuario puede solicitar la eliminación de su cuenta.\n'
                '• La plataforma puede cancelar cuentas que violen estos términos.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '9. Retroalimentación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• Las sugerencias pueden ser usadas libremente para mejorar la plataforma.\n',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '10. Vigencia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• Los términos están vigentes mientras el usuario mantenga una cuenta activa o use alguna función del sistema.\n',
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
