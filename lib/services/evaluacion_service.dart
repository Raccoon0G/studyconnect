import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class EvaluacionService {
  static const String _url =
      "https://hook.us2.make.com/2tx6w48rcjsco7o6ki24v8ecztiqyywf"; // tu webhook

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Llama al webhook de Make para que genere nuevas preguntas con IA.
  /// Devuelve true si fue exitoso (HTTP 200), false si hubo error.
  Future<bool> notificarGeneracionPreguntas(String tema) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Usuario no autenticado.");
        return false;
      }

      final nombre = await obtenerNombreDesdeUsuarios(user.uid);

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tema': tema, 'uid': user.uid, 'nombre': nombre}),
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          final mensaje = decoded["mensaje"]?.toString().toLowerCase() ?? "";

          print("✅ Webhook respondió: $mensaje");

          // Considera éxito si contiene "creadas" o "generadas"
          final exito =
              mensaje.contains("creadas") || mensaje.contains("generadas");
          return exito;
        } catch (e) {
          print("⚠️ Error al decodificar la respuesta JSON: $e");
          // Acepta como éxito si el código HTTP fue 200, aunque falle el parsing
          return true;
        }
      } else {
        print("❌ Error HTTP ${response.statusCode}: ${response.reasonPhrase}");
        print("Cuerpo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Excepción al enviar webhook: $e");
      return false;
    }
  }

  Future<String> obtenerNombreDesdeUsuarios(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      if (doc.exists && doc.data()?['Nombre'] != null) {
        return doc['Nombre'];
      }
    } catch (e) {
      print("Error al obtener nombre desde Firestore: $e");
    }
    return "Anónimo";
  }

  /// 🔄 Lee preguntas generadas por IA desde Firestore
  Future<Map<String, List<PreguntaModel>>> obtenerPreguntasDesdeFirestore(
    String tema, {
    int cantidad = 25,
  }) async {
    try {
      final snapshot =
          await firestore
              .collection('preguntas_por_tema')
              .where('tema', isEqualTo: tema)
              .orderBy('timestamp', descending: true)
              .limit(cantidad)
              .get();

      final preguntas =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return PreguntaModel.fromJson(data);
          }).toList();

      return {tema: preguntas};
    } catch (e) {
      print("Error al obtener preguntas desde Firestore: $e");
      return {tema: []};
    }
  }
}
