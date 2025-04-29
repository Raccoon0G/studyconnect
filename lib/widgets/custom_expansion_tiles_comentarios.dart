import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_connect/widgets/comment_shimmer_placeholder.dart';
import 'package:study_connect/widgets/custom_star_rating.dart';
import 'package:study_connect/utils/utils.dart';

class CustomExpansionTileComentarios extends StatelessWidget {
  final List<Map<String, dynamic>> comentarios;
  final Future<void> Function(Map<String, dynamic> comentario)
  onEliminarComentario;

  const CustomExpansionTileComentarios({
    super.key,
    required this.comentarios,
    required this.onEliminarComentario,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTileCard(
      elevation: 4,
      baseColor: const Color(0xFFF6F3FA),
      expandedColor: const Color(0xFFF6F3FA),
      borderRadius: BorderRadius.circular(16),
      leading: const Icon(Icons.comment, color: Colors.black87),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Comentarios (${comentarios.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          if (comentarios.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  calcularPromedioEstrellas(comentarios).toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
        ],
      ),
      children:
          comentarios.isEmpty
              ? List.generate(3, (_) => const CustomShimmerComment())
              : comentarios.map((c) {
                final fecha = (c['timestamp'] as Timestamp?)?.toDate();
                final formatted =
                    fecha != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                        : '';
                final editable =
                    c['usuarioId'] == FirebaseAuth.instance.currentUser?.uid;

                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(
                    milliseconds: 500 + (comentarios.indexOf(c) * 100),
                  ),
                  curve: Curves.easeOut,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade100,
                          child: const Icon(
                            Icons.person,
                            color: Colors.black87,
                          ),
                        ),
                        title: LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile =
                                MediaQuery.of(context).size.width < 500;
                            return isMobile
                                ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['nombre'] ?? 'Anónimo',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (c['estrellas'] ?? 0).toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c['nombre'] ?? 'Anónimo',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    CustomStarRating(
                                      valor: (c['estrellas'] ?? 0).toDouble(),
                                      size: 24,
                                    ),
                                  ],
                                );
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              formatted,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['comentario'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        trailing:
                            editable
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () async => await onEliminarComentario(c),
                                )
                                : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
    );
  }
}
