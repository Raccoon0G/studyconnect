import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/widgets/custom_latex_text.dart';
import 'package:study_connect/widgets/custom_star_rating.dart';
import 'package:study_connect/widgets/custom_action_button.dart';
import 'package:study_connect/services/services.dart';
import 'package:study_connect/widgets/widgets.dart';

import '../utils/utils.dart';

class ExerciseListPage extends StatelessWidget {
  const ExerciseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

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
              final bool isMobile = screenWidth < 1200;
              final double fontSize = screenWidth > 800 ? 20 : 16;

              /// Calcula el ancho total de la tabla
              final double totalWidth = constraints.maxWidth;

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
                    isMobile
                        ? Column(
                          children:
                              ejercicios.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    hoverColor: Colors.black12,
                                    onTap: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/exercise_view',
                                        arguments: {
                                          'tema': temaKey,
                                          'ejercicioId': doc.id,
                                        },
                                      );

                                      if (result == 'eliminado') {
                                        await LocalNotificationService.show(
                                          title: 'Ejercicio eliminado',
                                          body:
                                              'El ejercicio fue eliminado correctamente.',
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
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
                                            fontSize: fontSize,
                                            prepararLatex: prepararLaTeX,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            data['DesEjercicio'] ?? '',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: fontSize - 2,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Autor: ${data['Autor'] ?? 'Anónimo'}",
                                            style: TextStyle(
                                              fontSize: fontSize - 3,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              CustomStarRating(
                                                valor:
                                                    (data['CalPromedio'] is num)
                                                        ? (data['CalPromedio']
                                                                as num)
                                                            .toDouble()
                                                        : 0.0,
                                                size: 22,
                                              ),
                                              CustomActionButton(
                                                text: 'Ver',
                                                icon: Icons.arrow_forward_ios,
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.pushNamed(
                                                        context,
                                                        '/exercise_view',
                                                        arguments: {
                                                          'tema': temaKey,
                                                          'ejercicioId': doc.id,
                                                        },
                                                      );

                                                  if (result == 'eliminado') {
                                                    await LocalNotificationService.show(
                                                      title:
                                                          'Ejercicio eliminado',
                                                      body:
                                                          'El ejercicio fue eliminado correctamente.',
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        )
                        : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: screenWidth),
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF48C9EF),
                              ),
                              columnSpacing: 24,
                              columns: const [
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
                                      onSelectChanged: (_) async {
                                        final result =
                                            await Navigator.pushNamed(
                                              context,
                                              '/exercise_view',
                                              arguments: {
                                                'tema': temaKey,
                                                'ejercicioId': doc.id,
                                              },
                                            );

                                        if (result == 'eliminado') {
                                          await LocalNotificationService.show(
                                            title: 'Ejercicio eliminado',
                                            body:
                                                'El ejercicio fue eliminado correctamente.',
                                          );
                                        }
                                      },
                                      cells: [
                                        // Ejercicio
                                        DataCell(
                                          SizedBox(
                                            width: totalWidth * 0.18,
                                            child: CustomLatexText(
                                              contenido: data['Titulo'] ?? '',
                                              fontSize: 16,
                                              prepararLatex: prepararLaTeX,
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
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.ebGaramond(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: totalWidth * 0.14,
                                            child: CustomLatexText(
                                              contenido:
                                                  data['Autor'] ?? 'Anónimo',
                                              fontSize: 16,
                                              prepararLatex: prepararLaTeX,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          CustomStarRating(
                                            color: Colors.amber,
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),

                                            valor:
                                                (data['CalPromedio'] is num)
                                                    ? (data['CalPromedio']
                                                            as num)
                                                        .toDouble()
                                                    : 0.0,
                                            size: 30,
                                            geometryAlignment:
                                                Alignment.centerLeft,
                                          ),
                                        ),
                                        DataCell(
                                          // 1) usamos FRactionallySizedBox para darle al botón
                                          //    un ancho relativo al ancho de la tabla
                                          FractionallySizedBox(
                                            widthFactor:
                                                0.10, // 10% de totalWidth
                                            alignment: Alignment.centerLeft,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: CustomActionButton(
                                                text: 'Ver',
                                                icon: Icons.arrow_forward_ios,
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.pushNamed(
                                                        context,
                                                        '/exercise_view',
                                                        arguments: {
                                                          'tema': temaKey,
                                                          'ejercicioId': doc.id,
                                                        },
                                                      );

                                                  if (result == 'eliminado') {
                                                    await LocalNotificationService.show(
                                                      title:
                                                          'Ejercicio eliminado',
                                                      body:
                                                          'El ejercicio fue eliminado correctamente.',
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
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
