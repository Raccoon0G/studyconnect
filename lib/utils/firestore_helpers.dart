import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> actualizarTodoCalculoDeUsuario({required String? uid}) async {
  if (uid == null || uid.isEmpty) return;

  final firestore = FirebaseFirestore.instance;
  final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];

  double sumaMat = 0, sumaEjer = 0;
  int countMat = 0, countEjer = 0;

  for (final tema in temas) {
    // Materiales del autor
    final matSnap =
        await firestore
            .collection('materiales')
            .doc(tema)
            .collection('Mat$tema')
            .where('autorId', isEqualTo: uid)
            .get();

    for (final doc in matSnap.docs) {
      sumaMat += (doc.data()['calificacionPromedio'] ?? 0.0).toDouble();
      countMat++;
    }

    // Ejercicios del autor
    final ejerSnap =
        await firestore
            .collection('calculo')
            .doc(tema)
            .collection('Ejer$tema')
            .where('AutorId', isEqualTo: uid)
            .get();

    for (final doc in ejerSnap.docs) {
      sumaEjer += (doc.data()['CalPromedio'] ?? 0.0).toDouble();
      countEjer++;
    }
  }

  final promedioMat = countMat > 0 ? sumaMat / countMat : 0.0;
  final promedioEjer = countEjer > 0 ? sumaEjer / countEjer : 0.0;
  final promedioGlobal =
      (countMat + countEjer > 0)
          ? ((countMat > 0 ? promedioMat : 0) +
                  (countEjer > 0 ? promedioEjer : 0)) /
              ((countMat > 0 && countEjer > 0) ? 2 : 1)
          : 0.0;

  // 🟢 Actualizar el documento del usuario
  await firestore.collection('usuarios').doc(uid).update({
    'CalificacionMateriales': double.parse(promedioMat.toStringAsFixed(2)),
    'CalificacionEjercicios': double.parse(promedioEjer.toStringAsFixed(2)),
    'CalificacionGlobal': double.parse(promedioGlobal.toStringAsFixed(2)),
    'MaterialesSubidos': countMat,
    'EjerSubidos': countEjer,
  });

  print('✅ Calificaciones actualizadas para $uid');
}

Future<void> actualizarPromedioEjerciciosDelUsuario(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];

  double suma = 0;
  int conteo = 0;

  for (final tema in temas) {
    final query =
        await firestore
            .collection('calculo')
            .doc(tema)
            .collection('Ejer$tema')
            .where('AutorId', isEqualTo: uid)
            .get();

    for (final doc in query.docs) {
      final cal = (doc.data()['CalPromedio'] ?? 0).toDouble();
      suma += cal;
      conteo++;
    }
  }

  final promedio = conteo > 0 ? suma / conteo : 0.0;
  await firestore.collection('usuarios').doc(uid).update({
    'CalificacionEjercicios': double.parse(promedio.toStringAsFixed(2)),
  });
}

Future<void> actualizarPromedioMaterialesDelUsuario(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];

  double suma = 0;
  int conteo = 0;

  for (final tema in temas) {
    final query =
        await firestore
            .collection('materiales')
            .doc(tema)
            .collection('Mat$tema')
            .where('autorId', isEqualTo: uid)
            .get();

    for (final doc in query.docs) {
      final cal = (doc.data()['calificacionPromedio'] ?? 0).toDouble();
      suma += cal;
      conteo++;
    }
  }

  final promedio = conteo > 0 ? suma / conteo : 0.0;
  await firestore.collection('usuarios').doc(uid).update({
    'CalificacionMateriales': double.parse(promedio.toStringAsFixed(2)),
  });
}

Future<void> actualizarCalificacionGlobalDelUsuario(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final doc = await firestore.collection('usuarios').doc(uid).get();

  if (!doc.exists) return;

  final data = doc.data()!;
  final calEjer = (data['CalificacionEjercicios'] ?? 0).toDouble();
  final calMat = (data['CalificacionMateriales'] ?? 0).toDouble();
  final ejerSubidos = (data['EjerSubidos'] ?? 0).toInt();
  final matSubidos = (data['MaterialesSubidos'] ?? 0).toInt();

  double global = 0.0;

  if (ejerSubidos == 0 && matSubidos == 0) {
    global = 0.0;
  } else if (ejerSubidos == 0) {
    global = calMat;
  } else if (matSubidos == 0) {
    global = calEjer;
  } else {
    global = (calEjer + calMat) / 2.0;
  }

  await firestore.collection('usuarios').doc(uid).update({
    'CalificacionGlobal': double.parse(global.toStringAsFixed(2)),
  });
}
