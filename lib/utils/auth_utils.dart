import 'package:firebase_auth/firebase_auth.dart';

/// Función global para verificar si el usuario inició sesión
bool isUserLoggedIn() {
  final user = FirebaseAuth.instance.currentUser;
  return user != null;
}
