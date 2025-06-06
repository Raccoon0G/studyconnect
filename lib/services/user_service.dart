import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  /// Obtiene un Stream con los datos del documento de un usuario.
  /// Esto nos permitirá escuchar cambios en su configuración en tiempo real.
  static Stream<DocumentSnapshot> obtenerConfiguracionUsuario(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .snapshots();
  }
}
