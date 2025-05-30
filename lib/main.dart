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
