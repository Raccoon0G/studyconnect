import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/widgets/custom_latex_text.dart';
import 'package:study_connect/widgets/custom_star_rating.dart';
import 'package:study_connect/widgets/custom_action_button.dart';
import 'package:study_connect/services/services.dart';
import 'package:study_connect/widgets/widgets.dart';

class ExerciseListPage extends StatelessWidget {
  const ExerciseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    // 🔁 Si no hay argumentos, redirige automáticamente a /content
    if (args == null ||
        !args.containsKey('tema') ||
        !args.containsKey('titulo')) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/content'),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final String temaKey = args['tema'];
    final String tituloTema = args['titulo'];

    final CollectionReference ejerciciosRef = FirebaseFirestore.instance
        .collection('calculo')
        .doc(temaKey)
        .collection('Ejer$temaKey');

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Study Connect'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            child: const Text('Inicio', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/ranking'),
            child: const Text('Ranking', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/content'),
            child: const Text(
              'Contenidos',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const NotificationIconWidget(),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/user_profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Perfil',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ejerciciosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ejercicios = snapshot.data?.docs ?? [];

          return LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;

              return Container(
                width: screenWidth,
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF6F9FF), Color(0xFF048DD2)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tituloTema,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double totalWidth = constraints.maxWidth;

                        final isMobile =
                            MediaQuery.of(context).size.width < 1200;

                        return isMobile
                            ? Column(
                              children:
                                  ejercicios.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomLatexText(
                                              contenido: data['Titulo'] ?? '',
                                              fontSize: 18,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              data['DesEjercicio'] ?? '',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Autor: ${data['Autor'] ?? 'Anónimo'}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                CustomStarRating(
                                                  valor:
                                                      (data['CalPromedio']
                                                              is num)
                                                          ? (data['CalPromedio']
                                                                  as num)
                                                              .toDouble()
                                                          : 0.0,
                                                  size: 22,
                                                ),
                                                CustomActionButton(
                                                  text: 'Ver',
                                                  icon: Icons.arrow_forward_ios,
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/exercise_view',
                                                      arguments: {
                                                        'tema': temaKey,
                                                        'ejercicioId': doc.id,
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            )
                            : // 👇 tabla existente
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: totalWidth,
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFF48C9EF),
                                  ),
                                  columnSpacing: 24,
                                  columns: [
                                    DataColumn(label: Text('Ejercicio')),
                                    DataColumn(label: Text('Descripción')),
                                    DataColumn(label: Text('Autor')),
                                    DataColumn(label: Text('Calificación')),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows:
                                      ejercicios.map((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return DataRow(
                                          cells: [
                                            // Ejercicio
                                            DataCell(
                                              SizedBox(
                                                width: totalWidth * 0.18,
                                                child: CustomLatexText(
                                                  contenido:
                                                      data['Titulo'] ?? '',
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),

                                            // Descripción
                                            DataCell(
                                              SizedBox(
                                                width: totalWidth * 0.32,
                                                child: Text(
                                                  data['DesEjercicio'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              CustomLatexText(
                                                contenido:
                                                    data['Autor'] ?? 'Anónimo',
                                                fontSize: 16,
                                              ),
                                            ),
                                            DataCell(
                                              Center(
                                                child: CustomStarRating(
                                                  valor:
                                                      (data['CalPromedio']
                                                              is num)
                                                          ? (data['CalPromedio']
                                                                  as num)
                                                              .toDouble()
                                                          : 0.0,
                                                  size: 25,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: CustomActionButton(
                                                  text: 'Ver',
                                                  icon: Icons.arrow_forward_ios,
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/exercise_view',
                                                      arguments: {
                                                        'tema': temaKey,
                                                        'ejercicioId': doc.id,
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
