import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/models/usuario_model.dart';
import 'package:study_connect/widgets/custom_app_bar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final User? firebaseAuthUser = FirebaseAuth.instance.currentUser;
  Key _futureBuilderKey = UniqueKey();

  Future<Usuario?> _fetchUserData() async {
    if (firebaseAuthUser == null) return null;
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(firebaseAuthUser!.uid)
            .get();
    if (doc.exists) {
      return Usuario.fromFirestore(doc);
    }
    return null;
  }

  void _refreshProfile() {
    setState(() {
      _futureBuilderKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canPop = Navigator.canPop(context);
    final bool emailEstaVerificado = firebaseAuthUser?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: CustomAppBar(titleText: 'Mi Perfil', showBack: canPop),
      body: FutureBuilder<Usuario?>(
        key: _futureBuilderKey,
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          // ... (manejo de errores y no data igual que antes) ...
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el perfil: ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.white,
                  ), // Texto blanco para fondo oscuro
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No se pudo cargar el perfil o no existe.',
                    style: TextStyle(color: Colors.white), // Texto blanco
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                        () =>
                            Navigator.canPop(context)
                                ? Navigator.pop(context)
                                : Navigator.pushReplacementNamed(
                                  context,
                                  '/home',
                                ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          final usuario = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refreshProfile(),
            color: Colors.white,
            backgroundColor: theme.colorScheme.primary,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- Tarjeta de Cabecera del Perfil (sin cambios) ---
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          backgroundImage:
                              (usuario.fotoPerfilUrl != null &&
                                      usuario.fotoPerfilUrl!.isNotEmpty)
                                  ? NetworkImage(usuario.fotoPerfilUrl!)
                                  : null,
                          child:
                              (usuario.fotoPerfilUrl == null ||
                                      usuario.fotoPerfilUrl!.isEmpty)
                                  ? Icon(
                                    Icons.person,
                                    size: 70,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          usuario.nombre.isNotEmpty
                              ? usuario.nombre
                              : 'Usuario',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (usuario.rol != null && usuario.rol!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            usuario.rol!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/edit_profile',
                            );
                            if (result == true || mounted) {
                              _refreshProfile();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Tarjeta de Información Detallada (AHORA INCLUYE "SOBRE MÍ") ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Información General", // Título más general para la tarjeta
                          style: theme.textTheme.titleLarge?.copyWith(
                            // Un poco más grande el título de la tarjeta
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(
                          height: 24,
                          thickness: 1,
                        ), // Divisor más pronunciado
                        // Correo
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          title: Text(
                            "Correo",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          subtitle: Text(
                            usuario.correo,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing:
                              emailEstaVerificado
                                  ? Tooltip(
                                    message: "Verificado",
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.green.shade600,
                                      size: 22,
                                    ),
                                  )
                                  : Tooltip(
                                    message: "No verificado",
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange.shade700,
                                      size: 22,
                                    ),
                                  ),
                        ),

                        // Teléfono (si existe)
                        if (usuario.telefono != null &&
                            usuario.telefono!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.phone_outlined,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                            title: Text(
                              "Teléfono",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            subtitle: Text(
                              usuario.telefono!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        // Sobre Mí (si existe)
                        if (usuario.acercaDeMi != null &&
                            usuario.acercaDeMi!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            // Padding para el título "Sobre mí"
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 4.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Sobre mí",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            // Padding para el texto de la descripción
                            padding: const EdgeInsets.only(
                              left: 32.0,
                              right: 8.0,
                              bottom: 8.0,
                            ), // Indentación para el texto
                            child: Text(
                              usuario.acercaDeMi!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.4,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Acciones/Navegación (sin cambios) ---
                _buildProfileActionButton(
                  context: context,
                  theme: theme,
                  icon: Icons.list_alt_outlined,
                  label: 'Mis Ejercicios',
                  onTap: () => Navigator.pushNamed(context, '/user_exercises'),
                ),
                const SizedBox(height: 12),
                _buildProfileActionButton(
                  context: context,
                  theme: theme,
                  icon: Icons.library_books_outlined,
                  label: 'Mis Materiales',
                  onTap: () => Navigator.pushNamed(context, '/user_materials'),
                ),
                const SizedBox(height: 24),

                // --- Cerrar Sesión (sin cambios respecto a tu última modificación) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.logout, color: theme.colorScheme.error),
                    label: Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: theme.colorScheme.error.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      final confirmSignOut = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Cerrar Sesión'),
                              content: const Text(
                                '¿Estás seguro de que quieres cerrar sesión?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Sí, Cerrar Sesión',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirmSignOut == true && mounted) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileActionButton({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
