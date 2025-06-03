import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/screens/screens.dart';

import 'services/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> main() async {
    await dotenv.load(); // carga el .env
    runApp(const MyApp());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Connect',

      // --- COMIENZA LA ADICIÓN DEL THEME ---
      theme: ThemeData(
        // Define tus colores primarios.
        primaryColor: const Color(
          0xFF015C8B,
        ), // Tu azul principal oscuro para fondos de paneles, etc.
        // ColorScheme es más moderno y flexible para definir paletas.
        colorScheme: ColorScheme.fromSwatch(
          // Usar un primarySwatch ayuda a Flutter a derivar otros tonos si no los especificas.
          // Puedes buscar "flutter material color generator" para encontrar un primarySwatch para tu azul.
          // O definir cada color explícitamente.
          primarySwatch: Colors.blue,
        ).copyWith(
          // Aquí defines los colores clave de tu aplicación
          primary: const Color(
            0xFF015C8B,
          ), // Tu azul principal (para fondos, AppBars)
          onPrimary:
              Colors
                  .white, // Color del texto/iconos SOBRE el color primario (ej. texto en AppBar)

          secondary: const Color(
            0xFF048DD2,
          ), // Tu azul más claro (ej. para el header del chat, botones de acento)
          onSecondary: Colors.white, // Texto/iconos SOBRE el secundario

          background: const Color(
            0xFFF0F2F5,
          ), // Fondo general de las pantallas (un gris claro suave)
          onBackground: Colors.black87, // Texto SOBRE el fondo general

          surface:
              Colors
                  .white, // Color para "superficies" como Cards, Dialogs, menús
          onSurface: Colors.black87, // Texto SOBRE estas superficies

          error: Colors.redAccent, // Color para errores
          onError: Colors.white, // Texto SOBRE el color de error
        ),

        // Define estilos de texto por defecto que puedes usar en toda la app
        textTheme: const TextTheme(
          // Para títulos grandes como "Chats" en el panel
          headlineSmall: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          // Para nombres de usuario/grupo en la lista o header del chat
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          // Para texto de cuerpo normal, como el contenido de los mensajes
          bodyMedium: TextStyle(fontSize: 14.0),
          // Para texto más pequeño, como la hora del mensaje o el preview
          bodySmall: TextStyle(fontSize: 12.0),
          // Para el texto de los botones
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),

        // Estilo por defecto para AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(
            0xFF015C8B,
          ), // Usa tu color primario del tema
          foregroundColor:
              Colors.white, // Color de iconos y texto en AppBar (onPrimary)
          elevation: 1.0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // Estilo para los campos de texto (InputDecoration)
        inputDecorationTheme: InputDecorationTheme(
          // Ejemplo: Borde redondeado sutil y un color de fondo claro
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none, // Sin borde visible por defecto
          ),
          filled: true,
          fillColor: Colors.white, // O un gris muy claro como Colors.grey[50]
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),

        // Estilo para ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF048DD2), // Tu color secundario
            foregroundColor: Colors.white, // Texto del botón (onSecondary)
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),

        // Estilo para TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF048DD2), // Tu color secundario
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // Color para el indicador de la TabBar
        indicatorColor: Colors.lightBlueAccent, // Un color que contraste bien
        // Color del divisor
        dividerTheme: const DividerThemeData(
          color: Colors.black12, // Un color sutil para los divisores
          thickness: 1,
        ),
      ),

      // --- FIN DE LA ADICIÓN DEL THEME ---
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/chat': (context) => const ChatHomePage(),
        '/content': (context) => const ContentPage(),
        '/exercise_list': (context) => const ExerciseListPage(),
        '/material_list': (context) => const MaterialListPage(),
        '/exercise_upload': (context) => const ExerciseUploadPage(),
        '/ranking': (context) => const RankingPage(),
        '/user_profile': (context) => const UserProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/privacy': (context) => const PrivacyPage(),
        '/terms': (context) => const TermsPage(),
        '/credits': (context) => const CreditsPage(),
        '/faq': (context) => const FAQPage(),
        '/user_exercises': (context) => const MyExercisesPage(),
        '/user_materials': (context) => const MyMaterialsPage(),
        '/autoevaluation': (context) => AutoevaluationPage(),
        '/upload_material': (context) => UploadMaterialPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/exercise_view') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ExerciseViewPage(
                  tema: args['tema'],
                  ejercicioId: args['ejercicioId'],
                ),
          );
        }

        if (settings.name == '/material_view') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => MaterialViewPage(
                  tema: args['tema'],
                  materialId: args['materialId'],
                ),
          );
        }

        // --------------- NUEVO BLOQUE -----------------
        if (settings.name == '/exercise_versions') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ExerciseVersionsPage(
                  tema: args['tema'],
                  subcoleccion: args['subcoleccion'],
                  id: args['id'],
                ),
          );
        }
        // ----------------------------------------------
        return null;
      },
    );
  }
}
