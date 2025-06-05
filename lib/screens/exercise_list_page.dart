import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/services/local_notification_service.dart';
import 'package:study_connect/utils/utils.dart'; // Para prepararLaTeX
import 'package:study_connect/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth

// Opciones de ordenamiento
enum SortOptions {
  mejorCalificados,
  peorCalificados,
  tituloAZ,
  tituloZA,
  masRecientes,
  menosRecientes,
}

extension SortOptionsExtension on SortOptions {
  String get displayName {
    switch (this) {
      case SortOptions.mejorCalificados:
        return 'Mejor Calificados';
      case SortOptions.peorCalificados:
        return 'Peor Calificados';
      case SortOptions.tituloAZ:
        return 'Título (A-Z)';
      case SortOptions.tituloZA:
        return 'Título (Z-A)';
      case SortOptions.masRecientes:
        return 'Más Recientes';
      case SortOptions.menosRecientes:
        return 'Menos Recientes';
    }
  }
}

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  String? _temaKey;
  String? _tituloTema;

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";
  SortOptions _currentSortOption = SortOptions.mejorCalificados;

  Stream<QuerySnapshot>? _exercisesStream;

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  List<DocumentSnapshot> _allFetchedDocuments = [];
  List<DocumentSnapshot> _paginatedAndFilteredDocuments = [];

  bool _showCenteredUploadButton = false;
  bool _argumentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null &&
          args.containsKey('tema') &&
          args.containsKey('titulo')) {
        _temaKey = args['tema'];
        _tituloTema = args['titulo'];
        _argumentsLoaded = true;
        _updateStream();
      } else {
        Future.microtask(() {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/content');
          }
        });
      }
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
        _currentPage = 0;
        _applyClientSideFiltersAndPagination();
      });
    }
  }

  void _updateStream() {
    if (_temaKey == null) return;
    Query query = FirebaseFirestore.instance
        .collection('calculo')
        .doc(_temaKey)
        .collection('Ejer$_temaKey');

    switch (_currentSortOption) {
      case SortOptions.masRecientes:
        query = query.orderBy('fechaCreacion', descending: true);
        break;
      case SortOptions.menosRecientes:
        query = query.orderBy('fechaCreacion', descending: false);
        break;
      case SortOptions.mejorCalificados:
        query = query.orderBy('CalPromedio', descending: true);
        break;
      case SortOptions.peorCalificados:
        query = query.orderBy('CalPromedio', descending: false);
        break;
      case SortOptions.tituloAZ:
        query = query.orderBy('Titulo', descending: false);
        break;
      case SortOptions.tituloZA:
        query = query.orderBy('Titulo', descending: true);
        break;
    }
    if (mounted) {
      setState(() {
        _exercisesStream = query.snapshots();
        _currentPage = 0;
        _allFetchedDocuments = [];
        _paginatedAndFilteredDocuments = [];
      });
    }
  }

  void _applyClientSideFiltersAndPagination() {
    if (!mounted) return;

    List<DocumentSnapshot> filtered = List.from(_allFetchedDocuments);

    if (_searchTerm.isNotEmpty) {
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final titulo = (data['Titulo'] as String? ?? '').toLowerCase();
            final descripcion =
                (data['DesEjercicio'] as String? ?? '').toLowerCase();
            return titulo.contains(_searchTerm) ||
                descripcion.contains(_searchTerm);
          }).toList();
    }

    int startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= filtered.length && filtered.isNotEmpty) {
      _currentPage = (filtered.length - 1) ~/ _itemsPerPage;
      startIndex = _currentPage * _itemsPerPage;
    } else if (filtered.isEmpty) {
      _currentPage = 0;
      startIndex = 0;
    }

    int endIndex = startIndex + _itemsPerPage;
    endIndex = endIndex.clamp(startIndex, filtered.length);

    if (mounted) {
      setState(() {
        _paginatedAndFilteredDocuments = filtered.sublist(startIndex, endIndex);
      });
    }
  }

  void _changePage(int newPage) {
    List<DocumentSnapshot> currentlyFilteredTotal = List.from(
      _allFetchedDocuments,
    );
    if (_searchTerm.isNotEmpty) {
      currentlyFilteredTotal =
          currentlyFilteredTotal.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final titulo = (data['Titulo'] as String? ?? '').toLowerCase();
            final descripcion =
                (data['DesEjercicio'] as String? ?? '').toLowerCase();
            return titulo.contains(_searchTerm) ||
                descripcion.contains(_searchTerm);
          }).toList();
    }

    int totalPages = (currentlyFilteredTotal.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    if (newPage >= 0 && newPage < totalPages) {
      if (mounted) {
        setState(() {
          _currentPage = newPage;
          _applyClientSideFiltersAndPagination();
        });
      }
    }
  }

  Widget _buildPaginationControls(int totalFilteredItems) {
    final theme = Theme.of(context);
    if (totalFilteredItems <= _itemsPerPage) return const SizedBox.shrink();
    int totalPages = (totalFilteredItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color:
                  _currentPage == 0
                      ? theme.disabledColor
                      : theme.colorScheme.onSurface,
              size: 30,
            ),
            tooltip: "Página Anterior",
            onPressed:
                _currentPage == 0 ? null : () => _changePage(_currentPage - 1),
          ),
          Text(
            'Página ${_currentPage + 1} de $totalPages',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color:
                  (_currentPage + 1) >= totalPages
                      ? theme.disabledColor
                      : theme.colorScheme.onSurface,
              size: 30,
            ),
            tooltip: "Página Siguiente",
            onPressed:
                (_currentPage + 1) >= totalPages
                    ? null
                    : () => _changePage(_currentPage + 1),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Inicio de Sesión Requerido',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Para realizar esta acción, necesitas iniciar sesión.',
              style: GoogleFonts.poppins(),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: Theme.of(dialogContext).colorScheme.secondary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                  foregroundColor:
                      Theme.of(dialogContext).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Iniciar Sesión', style: GoogleFonts.poppins()),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ],
          ),
    );
  }

  void _handleUploadNavigation() {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (!isLoggedIn) {
      _showLoginRequiredDialog(context);
    } else {
      Navigator.pushNamed(
        context,
        '/exercise_upload',
        arguments: {'tema': _temaKey},
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isScreenWide = MediaQuery.of(context).size.width > 800;

    if (_temaKey == null || _tituloTema == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF036799),
        appBar: CustomAppBar(
          showBack: true,
          titleText: "Cargando Ejercicios...",
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: CustomAppBar(
        showBack: true,
        titleText: "Ejercicios de $_tituloTema",
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isScreenWide ? 32.0 : 12.0,
          vertical: 16.0,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
                child: Text(
                  _tituloTema!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isScreenWide ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar ejercicio...',
                        hintStyle: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.6,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainer
                            .withOpacity(0.8),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon:
                            _searchTerm.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer.withOpacity(
                          0.8,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SortOptions>(
                          value: _currentSortOption,
                          isExpanded: true,
                          dropdownColor:
                              theme.colorScheme.surfaceContainerHighest,
                          icon: Icon(
                            Icons.sort_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          items:
                              SortOptions.values.map((SortOptions option) {
                                return DropdownMenuItem<SortOptions>(
                                  value: option,
                                  child: Text(
                                    option.displayName,
                                    style: GoogleFonts.poppins(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (SortOptions? newValue) {
                            if (newValue != null && mounted) {
                              setState(() {
                                _currentSortOption = newValue;
                                _updateStream();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _exercisesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      _showCenteredUploadButton = false;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error al cargar ejercicios: ${snapshot.error}.\nVerifica tu conexión y la configuración de Firestore.',
                            style: GoogleFonts.poppins(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _allFetchedDocuments.isEmpty) {
                      _showCenteredUploadButton = false;
                      return Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      );
                    }

                    if (snapshot.hasData) {
                      _allFetchedDocuments = snapshot.data!.docs;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _applyClientSideFiltersAndPagination();
                          setState(() {
                            _showCenteredUploadButton =
                                _allFetchedDocuments.isEmpty &&
                                _searchTerm.isEmpty;
                          });
                        }
                      });
                    } else if (!snapshot.hasData &&
                        _allFetchedDocuments.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _paginatedAndFilteredDocuments = [];
                            _showCenteredUploadButton = true;
                          });
                        }
                      });
                    }

                    if (_showCenteredUploadButton &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 70,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.5),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Aún no hay ejercicios para "${_tituloTema ?? "este tema"}".',
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '¡Sé el primero en contribuir!',
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Subir Nuevo Ejercicio'),
                                onPressed: _handleUploadNavigation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_paginatedAndFilteredDocuments.isEmpty &&
                        _searchTerm.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No se encontraron ejercicios para "$_searchTerm" en "${_tituloTema ?? "este tema"}".',
                            style: GoogleFonts.poppins(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (_paginatedAndFilteredDocuments.isEmpty &&
                        _searchTerm.isEmpty &&
                        _allFetchedDocuments.isNotEmpty &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      return Center(
                        child: Text(
                          'No hay más ejercicios en esta página.',
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    if (_paginatedAndFilteredDocuments.isEmpty &&
                        snapshot.connectionState == ConnectionState.waiting &&
                        _allFetchedDocuments.isNotEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 6.0),
                            itemCount: _paginatedAndFilteredDocuments.length,
                            itemBuilder: (context, index) {
                              final doc = _paginatedAndFilteredDocuments[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final bool isCurrentlyWide =
                                  MediaQuery.of(context).size.width > 700;

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 2.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: theme.colorScheme.surfaceContainerHigh,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/exercise_view',
                                      arguments: {
                                        'tema': _temaKey,
                                        'ejercicioId': doc.id,
                                        'tituloTema': _tituloTema,
                                      },
                                    );
                                    if (result == 'eliminado' && mounted) {
                                      LocalNotificationService.show(
                                        title: 'Ejercicio eliminado',
                                        body:
                                            'El ejercicio fue eliminado correctamente.',
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CustomLatexText(
                                                contenido:
                                                    data['Titulo'] ??
                                                    'Sin Título',
                                                fontSize:
                                                    isCurrentlyWide ? 16.5 : 15,
                                                prepararLatex: prepararLaTeX,
                                              ),
                                              const SizedBox(height: 5),
                                              if (data['DesEjercicio'] !=
                                                      null &&
                                                  (data['DesEjercicio']
                                                          as String)
                                                      .isNotEmpty) ...[
                                                Text(
                                                  data['DesEjercicio'],
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        isCurrentlyWide
                                                            ? 13
                                                            : 12,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withOpacity(0.8),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                              ],
                                              Text(
                                                "Autor: ${data['Autor'] ?? 'Anónimo'}",
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      isCurrentlyWide
                                                          ? 11.5
                                                          : 10.5,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.65),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Tooltip(
                                              message:
                                                  'Calificación: ${(data['CalPromedio'] is num) ? (data['CalPromedio'] as num).toStringAsFixed(1) : "N/A"} / 5',
                                              child: CustomStarRating(
                                                valor:
                                                    (data['CalPromedio'] is num)
                                                        ? (data['CalPromedio']
                                                                as num)
                                                            .toDouble()
                                                        : 0.0,
                                                size: isCurrentlyWide ? 21 : 19,
                                                color: Colors.amber.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final result =
                                                    await Navigator.pushNamed(
                                                      context,
                                                      '/exercise_view',
                                                      arguments: {
                                                        'tema': _temaKey,
                                                        'ejercicioId': doc.id,
                                                        'tituloTema':
                                                            _tituloTema,
                                                      },
                                                    );
                                                if (result == 'eliminado' &&
                                                    mounted) {
                                                  LocalNotificationService.show(
                                                    title:
                                                        'Ejercicio eliminado',
                                                    body:
                                                        'El ejercicio fue eliminado correctamente.',
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      isCurrentlyWide ? 12 : 10,
                                                  vertical:
                                                      isCurrentlyWide ? 8 : 6,
                                                ),
                                                backgroundColor: theme
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.9),
                                                foregroundColor:
                                                    theme.colorScheme.onPrimary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Ver',
                                                    style: GoogleFonts.poppins(
                                                      fontSize:
                                                          isCurrentlyWide
                                                              ? 12
                                                              : 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    size:
                                                        isCurrentlyWide
                                                            ? 12
                                                            : 11,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        _buildPaginationControls(
                          _allFetchedDocuments.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final titulo =
                                (data['Titulo'] as String? ?? '').toLowerCase();
                            final descripcion =
                                (data['DesEjercicio'] as String? ?? '')
                                    .toLowerCase();
                            return _searchTerm.isEmpty ||
                                titulo.contains(_searchTerm) ||
                                descripcion.contains(_searchTerm);
                          }).length,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          (_temaKey != null && !_showCenteredUploadButton)
              ? FloatingActionButton.extended(
                onPressed: _handleUploadNavigation,
                label: const Text('Subir Ejercicio'),
                icon: const Icon(Icons.add),
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              )
              : null,
    );
  }
}
