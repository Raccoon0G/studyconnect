import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_connect/services/local_notification_service.dart';
import 'package:study_connect/utils/utils.dart'; // Para prepararLaTeX
import 'package:study_connect/widgets/widgets.dart';

// Opciones de ordenamiento (sin cambios)
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (_temaKey == null &&
        args != null &&
        args.containsKey('tema') &&
        args.containsKey('titulo')) {
      if (mounted) {
        setState(() {
          _temaKey = args['tema'];
          _tituloTema = args['titulo'];
          _updateStream();
        });
      }
    } else if (_temaKey == null &&
        (args == null ||
            !args.containsKey('tema') ||
            !args.containsKey('titulo'))) {
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/content');
        }
      });
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
    startIndex = startIndex.clamp(
      0,
      filtered.isNotEmpty ? filtered.length - 1 : 0,
    );
    int endIndex = startIndex + _itemsPerPage;
    endIndex = endIndex.clamp(startIndex, filtered.length);

    _paginatedAndFilteredDocuments = filtered.sublist(startIndex, endIndex);

    if (mounted) {
      setState(() {});
    }
  }

  void _changePage(int newPage) {
    List<DocumentSnapshot> currentlyFiltered =
        _allFetchedDocuments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final titulo = (data['Titulo'] as String? ?? '').toLowerCase();
          final descripcion =
              (data['DesEjercicio'] as String? ?? '').toLowerCase();
          return _searchTerm.isEmpty ||
              titulo.contains(_searchTerm) ||
              descripcion.contains(_searchTerm);
        }).toList();

    int totalPages = (currentlyFiltered.length / _itemsPerPage).ceil();

    if (newPage >= 0 && newPage < totalPages) {
      if (mounted) {
        setState(() {
          _currentPage = newPage;
          _applyClientSideFiltersAndPagination();
        });
      }
    } else if (newPage < 0 && mounted) {
      setState(() {
        _currentPage = 0;
        _applyClientSideFiltersAndPagination();
      });
    } else if ((newPage * _itemsPerPage) >= currentlyFiltered.length &&
        mounted) {
      int totalPagesCalculated =
          (currentlyFiltered.length / _itemsPerPage).ceil();
      setState(() {
        _currentPage = totalPagesCalculated > 0 ? totalPagesCalculated - 1 : 0;
        _applyClientSideFiltersAndPagination();
      });
    }
  }

  Widget _buildPaginationControls(int totalFilteredItems) {
    final theme = Theme.of(context);
    if (totalFilteredItems <= _itemsPerPage) return const SizedBox.shrink();
    int totalPages = (totalFilteredItems / _itemsPerPage).ceil();

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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isScreenWide =
        MediaQuery.of(context).size.width > 800; // Para responsividad general

    if (_temaKey == null || _tituloTema == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF036799),
        appBar: CustomAppBar(
          showBack: true,
          titleText: _tituloTema ?? "Cargando...",
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: CustomAppBar(showBack: true, titleText: "Ejercicios"),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isScreenWide ? 32.0 : 12.0,
          vertical: 16.0,
        ), // Padding ajustado
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
              // --- Barra de Herramientas: Búsqueda y Ordenamiento ---
              Container(
                // Contenedor para la barra de herramientas para darle un fondo distinto
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100, // Fondo más distintivo
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
                                  onPressed: () {
                                    _searchController.clear();
                                  },
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

              // --- Lista de Ejercicios ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _exercisesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
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
                      return Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      );
                    }

                    if (snapshot.hasData) {
                      _allFetchedDocuments = snapshot.data!.docs;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _applyClientSideFiltersAndPagination();
                      });
                    } else if (!snapshot.hasData &&
                        _allFetchedDocuments.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          setState(() => _paginatedAndFilteredDocuments = []);
                      });
                    }

                    if (_allFetchedDocuments.isEmpty &&
                        _searchTerm.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Aún no hay ejercicios para "${_tituloTema ?? "este tema"}".',
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
                        snapshot.connectionState == ConnectionState.waiting) {
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
                                  MediaQuery.of(context).size.width >
                                  700; // Ajustado para responsividad del item

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                  horizontal: 2.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color:
                                    theme
                                        .colorScheme
                                        .surfaceContainerHigh, // Un color de tarjeta que contraste un poco más
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
                                                // Los parámetros de color y peso dependerán de tu CustomLatexText
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
                                              // Tooltip para las estrellas
                                              message:
                                                  'Calificación: ${(data['CalPromedio'] is num) ? (data['CalPromedio'] as num).toStringAsFixed(1) : "N/A"} / 5',
                                              child: CustomStarRating(
                                                valor:
                                                    (data['CalPromedio'] is num)
                                                        ? (data['CalPromedio']
                                                                as num)
                                                            .toDouble()
                                                        : 0.0,
                                                size:
                                                    isCurrentlyWide
                                                        ? 21
                                                        : 19, // Estrellas un poco más grandes
                                                color:
                                                    Colors
                                                        .amber
                                                        .shade700, // Color de estrella intenso
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
    );
  }
}
