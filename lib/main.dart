import 'package:flutter/material.dart';
import 'package:study_connect/screens/screens.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Connect',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(),
        '/content': (context) => const ContentPage(),
        '/exercise_list': (context) => const ExerciseListPage(),
        '/exercise_upload': (context) => const ExerciseUploadPage(),
        '/exercise_view': (context) => const ExerciseViewPage(),
        '/ranking': (context) => const RankingPage(),
        '/user_profile': (context) => const UserProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
      },
    );
  }
}
