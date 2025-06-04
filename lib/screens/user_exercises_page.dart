import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/widgets/custom_app_bar.dart';
import 'dart:math'; // Para min() en paginación

class MyExercisesPage extends StatefulWidget {
  const MyExercisesPage({super.key});

  @override
  State<MyExercisesPage> createState() => _MyExercisesPageState();
}

class _MyExercisesPageState extends State<MyExercisesPage> {
  late Future<List<Map<String, dynamic>>> _futureEjercicios;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>> _allEjercicios = [];
  List<Map<String, dynamic>> _displayedEjercicios = [];

  String? _selectedTemaFilter; // Null significa "Todos"
  final List<String> _availableTemas = const [
    'Todos',
    'FnAlg',
    'Lim',
    'Der',
    'TecInteg',
  ];

  // Para paginación
  int _currentPage = 1;
  final int _itemsPerPage =
      5; // Mostrar 5 ejercicios por página (puedes ajustar esto)
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _futureEjercicios = _fetchMyExercises();
  }

  Future<List<Map<String, dynamic>>> _fetchMyExercises() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    final subcolecciones = {
      'FnAlg': 'EjerFnAlg',
      'Lim': 'EjerLim',
      'Der': 'EjerDer',
      'TecInteg': 'EjerTecInteg',
    };
    List<Map<String, dynamic>> ejerciciosCargados = [];

    for (var tema in temas) {
      if (subcolecciones[tema] == null) {
        debugPrint(
          "Advertencia: No se encontró subcolección para el tema $tema",
        );
        continue;
      }
      try {
        final snap =
            await FirebaseFirestore.instance
                .collection('calculo')
                .doc(tema)
                .collection(subcolecciones[tema]!)
                .where('AutorId', isEqualTo: uid)
                .get();
        for (var doc in snap.docs) {
          ejerciciosCargados.add({
            'id': doc.id,
            'tema': tema,
            'subcoleccion': subcolecciones[tema]!,
            'titulo': doc['Titulo'] ?? 'Sin título',
            'descripcion': doc['DesEjercicio'] ?? 'Sin descripción',
          });
        }
      } catch (e) {
        debugPrint("Error fetching exercises for tema $tema: $e");
      }
    }
    // Una vez cargados, actualizamos el estado general
    // Esto se llamará cada vez que el Future se complete
    if (mounted) {
      // Ordenar por título alfabéticamente como ejemplo
      ejerciciosCargados.sort(
        (a, b) => (a['titulo'] as String).compareTo(b['titulo'] as String),
      );
      _allEjercicios = ejerciciosCargados;
      _applyFiltersAndPagination(); // Aplicar filtros y paginación inicial
    }
    return ejerciciosCargados; // El FutureBuilder usará esto para saber cuándo finalizar la carga
  }

  void _applyFiltersAndPagination() {
    List<Map<String, dynamic>> filtered = [];
    if (_selectedTemaFilter == null || _selectedTemaFilter == 'Todos') {
      filtered = List.from(_allEjercicios);
    } else {
      filtered =
          _allEjercicios
              .where((ejer) => ejer['tema'] == _selectedTemaFilter)
              .toList();
    }

    _totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_totalPages == 0)
      _totalPages = 1; // Siempre hay al menos una página (vacía)
    _currentPage = max(
      1,
      min(_currentPage, _totalPages),
    ); // Ajustar currentPage si es necesario

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    _displayedEjercicios = filtered.sublist(
      startIndex,
      min(endIndex, filtered.length),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _changePage(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages) {
      _currentPage = newPage;
      _applyFiltersAndPagination();
    }
  }

  Future<void> _eliminarEjercicio(
    BuildContext context,
    String tema,
    String subcoleccion,
    String docId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final bool confirmar =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            /* ... diálogo sin cambios ... */
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Confirmar Eliminación'),
              content: const Text(
                '¿Estás seguro de que deseas eliminar este ejercicio? Esta acción no se puede deshacer.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                TextButton(
                  child: Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmar || !mounted) return;

    // ... Lógica de eliminación (sin cambios) ...
    try {
      final versionesRef = FirebaseFirestore.instance
          .collection('calculo')
          .doc(tema)
          .collection(subcoleccion)
          .doc(docId)
          .collection('Versiones');
      final versiones = await versionesRef.get();

      if (versiones.size > 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se puede eliminar un ejercicio con múltiples versiones.',
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final docRef = FirebaseFirestore.instance
          .collection('calculo')
          .doc(tema)
          .collection(subcoleccion)
          .doc(docId);
      await docRef.delete();
      final userRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final actual = (snapshot.data()?['EjerSubidos'] as num?)?.toInt() ?? 0;
        transaction.update(userRef, {
          'EjerSubidos': (actual - 1).clamp(0, actual),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ejercicio eliminado exitosamente.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refrescar los datos después de eliminar
      _futureEjercicios =
          _fetchMyExercises(); // Esto recargará y _applyFiltersAndPagination se llamará
      // Forzar la actualización visual si el FutureBuilder no lo hace inmediatamente
      setState(() {});
    } catch (e) {
      debugPrint("Error al eliminar ejercicio: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar ejercicio: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToUploadPage({
    String? tema,
    String? ejercicioId,
    String modo = 'crear',
  }) {
    Navigator.pushNamed(
      context,
      '/exercise_upload',
      arguments: {'tema': tema, 'ejercicioId': ejercicioId, 'modo': modo},
    ).then((value) {
      if (value == true && mounted) {
        _refreshIndicatorKey.currentState
            ?.show(); // Esto llamará a onRefresh y luego a _fetchMyExercises
      }
    });
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SizedBox(
        height: 40, // Altura fija para el scroll horizontal
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _availableTemas.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final tema = _availableTemas[index];
            final bool isSelected =
                (_selectedTemaFilter == null && tema == 'Todos') ||
                _selectedTemaFilter == tema;
            return ChoiceChip(
              label: Text(tema),
              selected: isSelected,
              onSelected: (selected) {
                _currentPage = 1; // Reset page on filter change
                if (selected) {
                  _selectedTemaFilter = (tema == 'Todos') ? null : tema;
                }
                _applyFiltersAndPagination();
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest, // Fondo del chip no seleccionado
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    // No mostrar controles de paginación si hay una sola página o ninguna
    if (_totalPages <= 1) {
      return const SizedBox.shrink();
    }

    List<Widget> pageNumberWidgets = [];
    // Mostrar un conjunto limitado de números de página (ej. 5) alrededor de la página actual
    int startPage = max(1, _currentPage - 2);
    int endPage = min(_totalPages, _currentPage + 2);

    if (_currentPage > 3 && _totalPages > 5) {
      pageNumberWidgets.add(_buildPageNumberButton(1));
      if (_currentPage > 4) {
        pageNumberWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text("...", style: TextStyle(color: Colors.white)),
          ),
        );
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      pageNumberWidgets.add(_buildPageNumberButton(i));
    }

    if (_currentPage < _totalPages - 2 && _totalPages > 5) {
      if (_currentPage < _totalPages - 3) {
        pageNumberWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text("...", style: TextStyle(color: Colors.white)),
          ),
        );
      }
      pageNumberWidgets.add(_buildPageNumberButton(_totalPages));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed:
                _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
            tooltip: 'Anterior',
          ),
          const SizedBox(width: 10),
          ...pageNumberWidgets,
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed:
                _currentPage < _totalPages
                    ? () => _changePage(_currentPage + 1)
                    : null,
            tooltip: 'Siguiente',
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumberButton(int pageNumber) {
    bool isCurrent = pageNumber == _currentPage;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changePage(pageNumber),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white54,
            ),
          ),
          child: Text(
            '$pageNumber',
            style: TextStyle(
              color:
                  isCurrent
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.white,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color scaffoldBackgroundColor = Color(0xFF036799);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: CustomAppBar(
        titleText: 'Mis Ejercicios',
        showBack: Navigator.canPop(context),
      ),
      body: Column(
        children: [
          _buildFilterChips(), // Chips de filtro aquí
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              color: Colors.white,
              backgroundColor: theme.colorScheme.primary,
              onRefresh: () async {
                if (mounted) {
                  Future<List<Map<String, dynamic>>> newFuture =
                      _fetchMyExercises();
                  // No necesitamos setState aquí porque _fetchMyExercises ya llama a _applyFiltersAndPagination
                  // que a su vez llama a setState.
                  // Lo que sí necesitamos es que el FutureBuilder se actualice con el *nuevo* future
                  // para que muestre el CircularProgressIndicator correctamente.
                  setState(() {
                    _futureEjercicios = newFuture;
                  });
                  await newFuture;
                }
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureEjercicios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _allEjercicios.isEmpty) {
                    // Mostrar carga solo si no hay datos previos
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      /* ... Error UI sin cambios ... */
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.errorContainer,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Ocurrió un error al cargar tus ejercicios.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Intentar de nuevo'),
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _futureEjercicios = _fetchMyExercises();
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // _allEjercicios ya se actualizó en _fetchMyExercises
                  // y _displayedEjercicios en _applyFiltersAndPagination

                  bool isListEmpty =
                      _allEjercicios
                          .isEmpty; // Comprobar si la lista *original* está vacía para el FAB
                  bool isDisplayListEmptyAfterFilter =
                      _displayedEjercicios.isEmpty && !isListEmpty;

                  if (isListEmpty &&
                      snapshot.connectionState != ConnectionState.waiting) {
                    // Si la lista original está vacía
                    return Center(
                      /* ... Empty state UI ... */
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 80,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Aún no has subido ejercicios.',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¡Presiona el botón para añadir tu primer ejercicio!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                textStyle: theme.textTheme.labelLarge,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Subir Ejercicio'),
                              onPressed: () => _navigateToUploadPage(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (isDisplayListEmptyAfterFilter) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_alt_off_outlined,
                              size: 70,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No hay ejercicios para el filtro "${_selectedTemaFilter ?? "Todos"}".',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Intenta seleccionar otro tema.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Si hay datos (ya filtrados y paginados en _displayedEjercicios)
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    itemCount: _displayedEjercicios.length,
                    itemBuilder: (context, index) {
                      final ejer = _displayedEjercicios[index];
                      return _ExerciseCard(
                        ejercicio: ejer,
                        /* ... callbacks ... */
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              '/exercise_view',
                              arguments: {
                                'tema': ejer['tema'],
                                'ejercicioId': ejer['id'],
                              },
                            ).then(
                              (v) =>
                                  v == true
                                      ? _refreshIndicatorKey.currentState
                                          ?.show()
                                      : null,
                            ),
                        onEdit:
                            () => _navigateToUploadPage(
                              tema: ejer['tema'],
                              ejercicioId: ejer['id'],
                              modo: 'editar',
                            ),
                        onNewVersion:
                            () => _navigateToUploadPage(
                              tema: ejer['tema'],
                              ejercicioId: ejer['id'],
                              modo: 'nueva_version',
                            ),
                        onDelete:
                            () => _eliminarEjercicio(
                              context,
                              ejer['tema'] as String,
                              ejer['subcoleccion'] as String,
                              ejer['id'] as String,
                            ),
                      );
                    },
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 12),
                  );
                },
              ),
            ),
          ),
          if (_allEjercicios.isNotEmpty)
            _buildPaginationControls(), // Controles de paginación aquí, solo si hay ejercicios
        ],
      ),
      floatingActionButton:
          (_allEjercicios
                      .isEmpty && // Ocultar FAB si la lista original está vacía
                  (_futureEjercicios !=
                          null && // Y el future no está en espera inicial (para evitar FOUC)
                      (ModalRoute.of(context)?.isCurrent ??
                          false) // Y la página es la actual
                      ))
              ? null
              : FloatingActionButton.extended(
                onPressed: () => _navigateToUploadPage(),
                label: const Text('Nuevo Ejercicio'),
                icon: const Icon(Icons.add),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
    );
  }
}

// _ExerciseCard (sin cambios)
class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> ejercicio;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onNewVersion;
  final VoidCallback onDelete;

  const _ExerciseCard({
    super.key, // Añadido super.key
    required this.ejercicio,
    required this.onTap,
    required this.onEdit,
    required this.onNewVersion,
    required this.onDelete,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String titulo =
        widget.ejercicio['titulo']?.toString() ?? 'Ejercicio sin título';
    final String categoria = widget.ejercicio['tema']?.toString() ?? 'General';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 8.0 : 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: _isHovered ? theme.colorScheme.surfaceDim : theme.cardColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.0),
          splashColor: theme.colorScheme.primary.withOpacity(0.12),
          highlightColor: theme.colorScheme.primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Categoría: $categoria',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'editar') widget.onEdit();
                    if (value == 'nueva') widget.onNewVersion();
                    if (value == 'eliminar') widget.onDelete();
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'editar',
                          child: ListTile(
                            leading: Icon(
                              Icons.edit_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: const Text('Editar ejercicio'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'nueva',
                          child: ListTile(
                            leading: Icon(
                              Icons.add_circle_outline,
                              color: Colors.green.shade600,
                            ),
                            title: const Text('Nueva versión'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_forever_outlined,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
