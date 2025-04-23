import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html; // SOLO FUNCIONA EN FLUTTER WEB

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  String? _temaSeleccionado;
  final TextEditingController _subtemaController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final List<Map<String, dynamic>> _archivos = [];

  final Map<String, String> temasDisponibles = {
    'FnAlg': 'Funciones algebraicas y trascendentes',
    'Lim': 'Límites de funciones y continuidad',
    'Der': 'Derivada y optimización',
    'TecInteg': 'Técnicas de integración',
  };

  Future<void> _seleccionarArchivo(String tipo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type:
          tipo == 'pdf'
              ? FileType.custom
              : tipo == 'image'
              ? FileType.image
              : FileType.media,
      allowedExtensions: tipo == 'pdf' ? ['pdf'] : null,
    );

    if (result != null) {
      final file = result.files.first;
      setState(() {
        _archivos.add({
          'nombre': file.name,
          'bytes': file.bytes,
          'extension': file.extension,
          'tipo': tipo,
        });
      });
    }
  }

  void _agregarEnlace() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Agregar enlace'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _archivos.add({'nombre': controller.text, 'tipo': 'link'});
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _agregarNota() {
    if (_notaController.text.isNotEmpty) {
      setState(() {
        _archivos.add({'nombre': _notaController.text, 'tipo': 'nota'});
        _notaController.clear();
      });
    }
  }

  String _extractYoutubeId(String url) {
    final uri = Uri.parse(url);
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    } else if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    } else {
      return '';
    }
  }

  void _abrirEnlaceEnWeb(String url) {
    html.window.open(url, '_blank');
  }

  Widget _buildArchivoPreview(Map<String, dynamic> archivo) {
    final tipo = archivo['tipo'];

    if (tipo == 'pdf') {
      return ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(archivo['nombre']),
      );
    } else if (tipo == 'image') {
      return ListTile(
        leading: const Icon(Icons.image, color: Colors.blue),
        title: Text(archivo['nombre']),
      );
    } else if (tipo == 'video') {
      return ListTile(
        leading: const Icon(Icons.videocam, color: Colors.orange),
        title: Text(archivo['nombre']),
      );
    } else if (tipo == 'link') {
      final link = archivo['nombre'];
      final isYoutube =
          link.contains("youtube.com") || link.contains("youtu.be");

      if (isYoutube) {
        final videoId = _extractYoutubeId(link);
        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(thumbnailUrl, fit: BoxFit.cover),
              ListTile(
                leading: const Icon(Icons.play_circle, color: Colors.red),
                title: const Text('Video de YouTube'),
                subtitle: Text(link),
                trailing: ElevatedButton.icon(
                  onPressed: () => _abrirEnlaceEnWeb(link),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Ver video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return ListTile(
          leading: const Icon(Icons.link, color: Colors.green),
          title: Text(link),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _abrirEnlaceEnWeb(link),
          ),
        );
      }
    } else if (tipo == 'nota') {
      return ListTile(
        leading: const Icon(Icons.notes, color: Colors.purple),
        title: Text(archivo['nombre']),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: AppBar(
        backgroundColor: const Color(0xFF048DD2),
        title: const Text('Subir Material Educativo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _temaSeleccionado,
                  hint: const Text('Selecciona un tema'),
                  items:
                      temasDisponibles.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _temaSeleccionado = value),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subtemaController,
                  decoration: const InputDecoration(
                    labelText: 'Subtema (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _seleccionarArchivo('pdf'),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Agregar PDF'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _seleccionarArchivo('image'),
                      icon: const Icon(Icons.image),
                      label: const Text('Agregar Imagen'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _seleccionarArchivo('video'),
                      icon: const Icon(Icons.videocam),
                      label: const Text('Agregar Video'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _agregarEnlace,
                      icon: const Icon(Icons.link),
                      label: const Text('Agregar Enlace'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _agregarNota,
                      icon: const Icon(Icons.notes),
                      label: const Text('Agregar Nota'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Escribe una nota para agregarla...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Vista previa:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _archivos.length,
                    itemBuilder:
                        (context, index) =>
                            _buildArchivoPreview(_archivos[index]),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aquí puedes invocar la función de subir a Firestore
                    print('Subiendo a Firestore...');
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Subir a Firestore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
