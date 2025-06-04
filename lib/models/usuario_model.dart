import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id; // UID de Firebase Auth, generalmente es el ID del documento
  String nombre;
  String correo;
  String? telefono; // Puede ser nulo
  String? rol; // Puede ser nulo
  String? acercaDeMi; // Puede ser nulo
  String? fotoPerfilUrl; // Puede ser nulo
  Map<String, bool> config; // Para ModoOscuro, Notificaciones, PerfilVisible

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    this.telefono,
    this.rol,
    this.acercaDeMi,
    this.fotoPerfilUrl,
    Map<String, bool>? config, // Hacemos el parámetro opcional
  }) : config =
           config ??
           {
             'ModoOscuro': true,
             'Notificaciones': true,
             'PerfilVisible': true,
           }; // Valores por defecto

  // ----- PASO 2: Convertir datos de Firestore a un Objeto Usuario -----
  // Factory constructor: permite crear una instancia desde un tipo de dato diferente (en este caso, un DocumentSnapshot)
  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Puedes lanzar un error o devolver un Usuario con valores por defecto/vacíos si prefieres
      throw StateError('Faltan datos para el Usuario ID: ${doc.id}');
    }

    // Manejo de 'Config' que es un mapa anidado
    final configData = data['Config'] as Map<String, dynamic>? ?? {};

    return Usuario(
      id: doc.id, // El ID del documento en Firestore
      nombre: data['Nombre'] as String? ?? '',
      correo: data['Correo'] as String? ?? '',
      telefono: data['Telefono'] as String?,
      rol: data['rol'] as String?,
      acercaDeMi: data['Acerca de mi'] as String?,
      fotoPerfilUrl: data['FotoPerfil'] as String?,
      config: {
        'ModoOscuro': configData['ModoOscuro'] as bool? ?? true,
        'Notificaciones': configData['Notificaciones'] as bool? ?? true,
        'PerfilVisible': configData['PerfilVisible'] as bool? ?? true,
      },
    );
  }

  // ----- PASO 3: Convertir un Objeto Usuario a un Mapa para Firestore -----
  Map<String, dynamic> toMap() {
    return {
      // 'id' no se suele guardar dentro del documento si ya es el ID del documento,
      // pero si lo necesitas por alguna razón, puedes incluirlo: 'id': id,
      'Nombre': nombre,
      'Correo': correo,
      'Telefono': telefono,
      'rol': rol,
      'Acerca de mi': acercaDeMi,
      'FotoPerfil': fotoPerfilUrl,
      'Config': config,
      'ultimaActualizacion':
          FieldValue.serverTimestamp(), // Opcional: para registrar cuándo se actualizó
    };
  }
}
