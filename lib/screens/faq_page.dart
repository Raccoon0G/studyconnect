import 'package:flutter/material.dart';

// Un modelo simple para manejar nuestras preguntas y respuestas
class _FAQItem {
  _FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });

  String question;
  String answer;
  bool isExpanded;
}

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final TextEditingController _searchController = TextEditingController();

  // Lista original de todas las preguntas (ahora más completa)
  final List<_FAQItem> _originalFaqs = [
    // --- Categoría: Cuenta y Perfil ---
    _FAQItem(
      question: '¿Cómo puedo registrarme?',
      answer:
          'Para registrarte, ve a la pantalla principal y haz clic en el botón "Registrarse". Deberás llenar un formulario con tu nombre, correo electrónico y una contraseña segura. Finalmente, acepta los términos y condiciones para completar el proceso.',
    ),
    _FAQItem(
      question: '¿Qué hago si no recibo el correo de verificación?',
      answer:
          'Primero, revisa tu carpeta de spam o correo no deseado. Si después de unos minutos el correo no ha llegado, puedes solicitar que se envíe de nuevo desde la pantalla de inicio de sesión. El sistema requiere verificación por correo para asegurar la autenticidad de los usuarios.',
    ),
    _FAQItem(
      question: '¿Cómo puedo editar mi perfil o cambiar mi contraseña?',
      answer:
          'Dentro de la aplicación, ve a la sección de "Mi Perfil". Ahí encontrarás opciones para editar tu información personal y un botón específico para "Cambiar Contraseña". Para tu seguridad, el cambio de contraseña requiere una verificación adicional por correo.',
    ),

    // --- Categoría: Contenido y Ejercicios ---
    _FAQItem(
      question: '¿Dónde puedo subir ejercicios?',
      answer:
          'Una vez que hayas iniciado sesión, navega a la sección de "Mis Contenidos" o busca el botón flotante con el símbolo "+". Desde ahí podrás seleccionar "Agregar Ejercicio" y llenar los campos necesarios.',
    ),
    _FAQItem(
      question: '¿Necesito saber LaTeX para subir ejercicios?',
      answer:
          'No es estrictamente necesario. La plataforma cuenta con un teclado simbólico que te ayuda a insertar las fórmulas matemáticas más comunes. Sin embargo, si conoces LaTeX, puedes escribirlo directamente para crear expresiones más complejas y detalladas.',
    ),
    _FAQItem(
      question: '¿Qué tipo de material de apoyo puedo subir?',
      answer:
          'Puedes subir una gran variedad de material para enriquecer la comunidad. El sistema acepta archivos PDF, imágenes, enlaces a videos de YouTube y notas de texto escritas directamente en la plataforma, con un estilo similar a Google Classroom.',
    ),
    _FAQItem(
      question: '¿Puedo editar mis ejercicios después de subirlos?',
      answer:
          'Sí, puedes modificar y crear nuevas versiones de tus ejercicios desde la sección "Mis Contenidos". Selecciona el ejercicio que deseas cambiar y busca el ícono de editar.',
    ),

    // --- Categoría: Interacción y Comunidad ---
    _FAQItem(
      question: '¿Cómo funciona el sistema de ranking?',
      answer:
          'El ranking se basa en un sistema de puntos. Ganas puntos principalmente de dos formas: cuando otros usuarios califican positivamente los ejercicios que subes y cuando tus autoevaluaciones tienen un puntaje alto. ¡Mientras más contribuyas con material de calidad, más alto será tu ranking!',
    ),
    _FAQItem(
      question: '¿Cómo sé si tengo notificaciones nuevas?',
      answer:
          'Aparecerá una insignia o "badge" en el ícono de la campana en la barra superior. El sistema te notificará sobre nuevos mensajes de chat, comentarios en tus ejercicios, nuevas calificaciones y cambios en tu posición en el ranking.',
    ),
    _FAQItem(
      question: '¿Puedo borrar un mensaje que envié por error en el chat?',
      answer:
          'Sí, el chat funciona de manera similar a otras aplicaciones de mensajería. Puedes editar o eliminar tus propios mensajes después de haberlos enviado, además de poder reaccionar a los mensajes de otros usuarios.',
    ),
    _FAQItem(
      question: '¿De dónde vienen las preguntas de las autoevaluaciones?',
      answer:
          'Las preguntas son generadas automáticamente por un sistema de inteligencia artificial (vía Make y OpenAI) para asegurar un banco de reactivos amplio y variado para cada tema. Tus resultados y puntajes se guardan para que puedas ver tu progreso.',
    ),
  ];

  // (El resto del código no necesita cambios)

  List<_FAQItem> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _originalFaqs;
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFaqs);
    _searchController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _originalFaqs;
      } else {
        _filteredFaqs =
            _originalFaqs.where((faq) {
              return faq.question.toLowerCase().contains(query) ||
                  faq.answer.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> listItems = [];
    if (_searchController.text.isEmpty) {
      // Rangos actualizados para las nuevas preguntas
      listItems.add(_buildCategoryHeader('Cuenta y Perfil'));
      listItems.addAll(
        _originalFaqs.sublist(0, 3).map((faq) => _buildFaqCard(faq)),
      );

      listItems.add(_buildCategoryHeader('Contenido y Ejercicios'));
      listItems.addAll(
        _originalFaqs.sublist(3, 7).map((faq) => _buildFaqCard(faq)),
      );

      listItems.add(_buildCategoryHeader('Interacción y Comunidad'));
      listItems.addAll(
        _originalFaqs.sublist(7, 11).map((faq) => _buildFaqCard(faq)),
      );
    } else {
      listItems.addAll(_filteredFaqs.map((faq) => _buildFaqCard(faq)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar preguntas...',
                hintText: 'Escribe una palabra clave, ej. "ranking"',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                return listItems[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(_FAQItem faq) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(faq.question),
        onExpansionChanged: (bool expanded) {
          setState(() {
            faq.isExpanded = expanded;
          });
        },
        leading: const Icon(Icons.help_outline),
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            faq.isExpanded
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
        children: [
          Container(
            color: Colors.black.withOpacity(0.03),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                faq.answer,
                textAlign: TextAlign.justify,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
