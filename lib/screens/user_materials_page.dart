import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/widgets/custom_app_bar.dart'; // Asegúrate que esta ruta es correcta
import 'dart:math'; // Para min() y max() en paginación

class MyMaterialsPage extends StatefulWidget {
  const MyMaterialsPage({super.key});

  @override
  State<MyMaterialsPage> createState() => _MyMaterialsPageState();
}

class _MyMaterialsPageState extends State<MyMaterialsPage> {
  late Future<List<Map<String, dynamic>>> _futureMateriales;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>> _allMateriales = [];
  List<Map<String, dynamic>> _displayedMateriales = [];

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
  final int _itemsPerPage = 5; // Puedes ajustar este número (ej. 10 o 20)
  int _totalPages = 1;

  bool _isInitialLoadComplete =
      false; // Para controlar la visibilidad del FAB y el spinner inicial

  @override
  void initState() {
    super.initState();
    _futureMateriales = _fetchMyMaterials();
  }

  Future<List<Map<String, dynamic>>> _fetchMyMaterials() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        // Actualizar estado si no hay UID
        _allMateriales = [];
        _applyFiltersAndPagination(); // Esto llamará a setState
      }
      return [];
    }

    final temas = ['FnAlg', 'Lim', 'Der', 'TecInteg'];
    final subcolecciones = {
      'FnAlg': 'MatFnAlg',
      'Lim': 'MatLim',
      'Der': 'MatDer',
      'TecInteg': 'MatTecInteg',
    };
    List<Map<String, dynamic>> materialesCargados = [];

    for (var tema in temas) {
      if (subcolecciones[tema] == null) {
        debugPrint(
          "Advertencia: No se encontró subcolección para el tema $tema en materiales",
        );
        continue;
      }
      try {
        final snap =
            await FirebaseFirestore.instance
                .collection('materiales')
                .doc(tema)
                .collection(subcolecciones[tema]!)
                .where('autorId', isEqualTo: uid)
                .get();
        for (var doc in snap.docs) {
          materialesCargados.add({
            'id': doc.id,
            'tema': tema,
            'subcoleccion': subcolecciones[tema]!,
            'titulo': doc['titulo'] ?? 'Sin título',
            'descripcion': doc['descripcion'] ?? 'Sin descripción',
          });
        }
      } catch (e) {
        debugPrint("Error fetching materials for tema $tema: $e");
        // Considerar si se debe notificar al usuario o reintentar
      }
    }

    if (mounted) {
      // Ordenar los materiales, por ejemplo, alfabéticamente por título
      materialesCargados.sort(
        (a, b) => (a['titulo'] as String? ?? "").compareTo(
          b['titulo'] as String? ?? "",
        ),
      );
      _allMateriales = materialesCargados;
      _applyFiltersAndPagination(); // Esto llamará a setState
    }
    return materialesCargados; // El FutureBuilder usará esto
  }

  void _applyFiltersAndPagination() {
    List<Map<String, dynamic>> filtered = [];
    if (_selectedTemaFilter == null || _selectedTemaFilter == 'Todos') {
      filtered = List.from(_allMateriales);
    } else {
      filtered =
          _allMateriales
              .where((mat) => mat['tema'] == _selectedTemaFilter)
              .toList();
    }

    _totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_totalPages == 0)
      _totalPages = 1; // Evitar división por cero si filtered.length es 0

    // Asegurarse que _currentPage esté dentro de los límites válidos
    _currentPage = max(1, min(_currentPage, _totalPages));

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    // endIndex no debe exceder la longitud de la lista filtrada
    int endIndex = min(startIndex + _itemsPerPage, filtered.length);

    if (startIndex < filtered.length) {
      // Solo tomar sublista si startIndex es válido
      _displayedMateriales = filtered.sublist(startIndex, endIndex);
    } else {
      _displayedMateriales =
          []; // Si startIndex está fuera de rango, la lista desplegada es vacía
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _changePage(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages && newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
        _applyFiltersAndPagination();
      });
    }
  }

  Future<void> _eliminarMaterial(
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
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Confirmar Eliminación'),
              content: const Text(
                '¿Estás seguro de que deseas eliminar este material? Esta acción no se puede deshacer.',
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

    try {
      final versionesRef = FirebaseFirestore.instance
          .collection('materiales')
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
              'No se puede eliminar un material con múltiples versiones.',
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('materiales')
          .doc(tema)
          .collection(subcoleccion)
          .doc(docId)
          .delete();

      final userRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final actual =
            (snapshot.data()?['MaterialesSubidos'] as num?)?.toInt() ?? 0;
        transaction.update(userRef, {
          'MaterialesSubidos': (actual - 1).clamp(0, actual),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material eliminado exitosamente.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refrescar datos y UI
      setState(() {
        _isInitialLoadComplete =
            false; // Forzar spinner si la lista queda vacía
        _futureMateriales =
            _fetchMyMaterials(); // Esto actualizará _allMateriales y llamará a _applyFiltersAndPagination
      });
    } catch (e) {
      debugPrint("Error al eliminar material: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar material: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToUploadPage({
    String? tema,
    String? materialId,
    String modo = 'crear',
    bool nuevaVersion = false,
  }) {
    Navigator.pushNamed(
      context,
      '/upload_material',
      arguments: {
        'tema': tema,
        'materialId': materialId,
        'editar': modo == 'editar',
        'nuevaVersion': nuevaVersion,
      },
    ).then((value) {
      if (value == true && mounted) {
        _refreshIndicatorKey.currentState?.show(); // Esto llama a onRefresh
      }
    });
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SizedBox(
        height: 40,
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
                setState(() {
                  _currentPage = 1; // Reset page on filter change
                  if (selected) {
                    _selectedTemaFilter = (tema == 'Todos') ? null : tema;
                  }
                  _applyFiltersAndPagination();
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
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
    if (_totalPages <= 1) return const SizedBox.shrink();
    List<Widget> pageNumberWidgets = [];
    int startPage = max(1, _currentPage - 2);
    int endPage = min(_totalPages, _currentPage + 2);

    if (_currentPage > 3 && _totalPages > 5) {
      pageNumberWidgets.add(_buildPageNumberButton(1));
      if (_currentPage > 4)
        pageNumberWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text("...", style: TextStyle(color: Colors.white)),
          ),
        );
    }
    for (int i = startPage; i <= endPage; i++)
      pageNumberWidgets.add(_buildPageNumberButton(i));
    if (_currentPage < _totalPages - 2 && _totalPages > 5) {
      if (_currentPage < _totalPages - 3)
        pageNumberWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text("...", style: TextStyle(color: Colors.white)),
          ),
        );
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

    // Definir la variable para la visibilidad del FAB aquí
    final bool isListEmptyAndLoadComplete =
        _allMateriales.isEmpty && _isInitialLoadComplete;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: CustomAppBar(
        titleText: 'Mis Materiales',
        showBack: Navigator.canPop(context),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              color: Colors.white,
              backgroundColor: theme.colorScheme.primary,
              onRefresh: () async {
                if (mounted) {
                  setState(() {
                    _isInitialLoadComplete =
                        false; // Reiniciar para mostrar spinner si es necesario
                  });
                  Future<List<Map<String, dynamic>>> newFuture =
                      _fetchMyMaterials();
                  setState(() {
                    _futureMateriales = newFuture;
                  });
                  await newFuture;
                }
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureMateriales,
                builder: (context, snapshot) {
                  // Actualizar _isInitialLoadComplete después de que el FutureBuilder resuelva
                  if (snapshot.connectionState != ConnectionState.waiting &&
                      !_isInitialLoadComplete) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _isInitialLoadComplete = true;
                        });
                      }
                    });
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_isInitialLoadComplete) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 50,
                            ), // Usar theme.colorScheme.error
                            const SizedBox(height: 10),
                            Text(
                              'Ocurrió un error al cargar tus materiales.',
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
                                    _isInitialLoadComplete = false;
                                    _futureMateriales = _fetchMyMaterials();
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

                  // Usar la variable definida a nivel de build para el estado vacío principal
                  if (_allMateriales.isEmpty && _isInitialLoadComplete) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_outlined,
                              size: 80,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Aún no has subido materiales.',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¡Presiona el botón para añadir tu primer material!',
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
                              label: const Text('Subir Material'),
                              onPressed: () => _navigateToUploadPage(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Estado cuando la lista filtrada está vacía, pero la lista general no.
                  bool isDisplayListEmptyAfterFilter =
                      _displayedMateriales.isEmpty &&
                      !_allMateriales.isEmpty &&
                      _isInitialLoadComplete;
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
                              'No hay materiales para el filtro "${_selectedTemaFilter ?? "Todos"}".',
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

                  // Si hay datos para mostrar (ya filtrados y paginados)
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    itemCount: _displayedMateriales.length,
                    itemBuilder: (context, index) {
                      final mat = _displayedMateriales[index];
                      return _MaterialCard(
                        material: mat,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              '/material_view',
                              arguments: {
                                'tema': mat['tema'],
                                'materialId': mat['id'],
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
                              tema: mat['tema'],
                              materialId: mat['id'],
                              modo: 'editar',
                            ),
                        onNewVersion:
                            () => _navigateToUploadPage(
                              tema: mat['tema'],
                              materialId: mat['id'],
                              nuevaVersion: true,
                            ),
                        onDelete:
                            () => _eliminarMaterial(
                              context,
                              mat['tema'] as String,
                              mat['subcoleccion'] as String,
                              mat['id'] as String,
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
          if (_allMateriales.isNotEmpty && _isInitialLoadComplete)
            _buildPaginationControls(),
        ],
      ),
      floatingActionButton:
          isListEmptyAndLoadComplete // Usar la variable definida en el ámbito del build
              ? null
              : FloatingActionButton.extended(
                onPressed: () => _navigateToUploadPage(),
                label: const Text('Nuevo Material'),
                icon: const Icon(Icons.add),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
    );
  }
}

// _MaterialCard (sin cambios significativos, solo asegurar `super.key`)
class _MaterialCard extends StatefulWidget {
  final Map<String, dynamic> material;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onNewVersion;
  final VoidCallback onDelete;

  const _MaterialCard({
    super.key, // Importante añadir super.key
    required this.material,
    required this.onTap,
    required this.onEdit,
    required this.onNewVersion,
    required this.onDelete,
  });

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String titulo =
        widget.material['titulo']?.toString() ?? 'Material sin título';
    final String categoria = widget.material['tema']?.toString() ?? 'General';

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
                  Icons.article_outlined,
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
                            title: const Text('Editar material'),
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
