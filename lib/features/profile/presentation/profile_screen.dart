import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/auth/providers/auth_provider.dart';
import 'package:finan_goal/features/transaction/providers/transaction_provider.dart';
import 'package:finan_goal/features/goals/providers/saving_goals_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  bool _isPro = false;
  List<bool> _notificationsRead = [false, false, false];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _initLocalState();
  }

  Future<void> _initLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPro = prefs.getBool('is_pro') ?? false;
      _notificationsRead = [
        prefs.getBool('notif_0') ?? false,
        prefs.getBool('notif_1') ?? false,
        prefs.getBool('notif_2') ?? false,
      ];
    });
  }

  int get _unreadCount => _notificationsRead.where((read) => !read).length;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Future<void> _logout() async {
    ref.read(authProvider.notifier).resetState();
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    if (mounted) context.goNamed('login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(balanceProvider);
    final totalTransactions = ref.watch(transactionProvider).length;
    final totalGoals = ref.watch(savingGoalsProvider).length;

    final authState = ref.watch(authProvider);
    final name = authState.user?.name ?? 'Usuario';
    final email = authState.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
              child: Column(
                children: [
                  // Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mi Perfil', style: AppTextStyles.displayMedium),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar + nombre
                  _buildAvatarSection(name, email),
                  const SizedBox(height: 20),

                  // Stats rápidas
                  _buildStatsRow(balance, totalTransactions, totalGoals),
                  const SizedBox(height: 20),

                  // Menú
                  _buildMenu(name, email),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String name, String email) {
    final profileImagePath = ref.watch(profileImageProvider);
    final hasImage = profileImagePath != null && File(profileImagePath).existsSync();

    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourcePicker,
          child: Stack(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24, offset: const Offset(0, 8),
                  )],
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.file(
                          File(profileImagePath),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        )
                      : Center(
                          child: Text(
                            _getInitials(name),
                            style: AppTextStyles.displayLarge.copyWith(
                              color: Colors.white,
                              fontSize: 26,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showEditProfileSheet(name, email),
              child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(email, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _isPro 
                ? const Color(0xFFE2A732).withOpacity(0.12)
                : AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(_isPro ? '✦  Plan PRO 💎' : '✦  Plan Gratis',
              style: AppTextStyles.caption.copyWith(
                  color: _isPro ? const Color(0xFFE2A732) : AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      // Alerta de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Guardar Foto de Perfil', style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
          content: Text('¿Deseas guardar esta foto como tu imagen de perfil?', style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Confirmar', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final docDir = await getApplicationDocumentsDirectory();
      final targetPath = '${docDir.path}/profile_avatar.jpg';
      final file = File(pickedFile.path);

      // Copiar archivo localmente
      final savedFile = await file.copy(targetPath);

      // Guardar a través del notifier del provider
      await ref.read(profileImageProvider.notifier).setImagePath(savedFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Foto de perfil actualizada con éxito! 📸',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la foto: $e',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text('Tomar Foto con Cámara', style: AppTextStyles.labelLarge),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text('Elegir de la Galería', style: AppTextStyles.labelLarge),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(double balance, int transactionsCount, int goalsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatBadge(value: '\$${balance.toStringAsFixed(2)}', label: 'Balance', color: AppColors.primary),
          const SizedBox(width: 10),
          _StatBadge(value: '$transactionsCount', label: 'Movimientos'),
          const SizedBox(width: 10),
          _StatBadge(value: '$goalsCount', label: 'Metas', color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildMenu(String name, String email) {
    final items = [
      _MenuItem(
        icon: '👤', 
        label: 'Editar Perfil',
        bg: AppColors.primary.withOpacity(0.12), 
        onTap: () => _showEditProfileSheet(name, email),
      ),
      _MenuItem(
        icon: '📝', 
        label: 'Notas y Recordatorios',
        bg: const Color(0xFFE2A732).withOpacity(0.12), 
        onTap: _showNotesSheet,
      ),
      _MenuItem(
        icon: '🔔', 
        label: 'Notificaciones',
        bg: AppColors.accent.withOpacity(0.12),
        badge: _unreadCount > 0 ? '$_unreadCount' : null, 
        onTap: _showNotificationsSheet,
      ),
      _MenuItem(
        icon: '🔒', 
        label: 'Seguridad',
        bg: const Color(0xFF8B7FE8).withOpacity(0.12), 
        onTap: _showSecuritySheet,
      ),
      _MenuItem(
        icon: '💎', 
        label: 'Actualizar a Pro',
        bg: AppColors.error.withOpacity(0.08),
        badge: _isPro ? 'Activo' : 'Nuevo', 
        badgeColor: _isPro ? AppColors.success : AppColors.accent, 
        onTap: _showUpgradeProSheet,
      ),
      _MenuItem(
        icon: '🚪', 
        label: 'Cerrar sesión',
        bg: AppColors.error.withOpacity(0.10),
        textColor: AppColors.error, 
        onTap: _logout, 
        isLast: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: items.map((item) => _MenuTile(item: item)).toList()),
      ),
    );
  }

  // ── Sheets / Modales de Acciones ───────────────────────────

  void _showNotesSheet() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> notes = [];
    
    void loadNotes() {
      final notesJson = prefs.getString('user_notes');
      if (notesJson != null) {
        try {
          final decoded = jsonDecode(notesJson);
          if (decoded is List) {
            notes = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (_) {}
      } else {
        notes = [];
      }
    }
    
    loadNotes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notas y Recordatorios 📝', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                        onPressed: () {
                          _showAddEditNoteDialog(context, onSave: (newNote) async {
                            notes.add(newNote);
                            await prefs.setString('user_notes', jsonEncode(notes));
                            setSheetState(() {
                              loadNotes();
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Escribe notas de tus metas o finanzas y personaliza su color', style: AppTextStyles.caption),
                  const SizedBox(height: 20),
                  
                  if (notes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 44)),
                            const SizedBox(height: 12),
                            Text('No tienes notas aún.', style: AppTextStyles.labelLarge),
                            const SizedBox(height: 4),
                            Text('Pulsa el botón "+" arriba para crear una.', style: AppTextStyles.caption, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 320,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final colorVal = note['color'] ?? 0xFF8B7FE8;
                          final cardColor = Color(colorVal);

                          return Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: cardColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note['title'] ?? 'Sin título',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                          onPressed: () {
                                            _showAddEditNoteDialog(context, noteToEdit: note, onSave: (updatedNote) async {
                                              notes[index] = updatedNote;
                                              await prefs.setString('user_notes', jsonEncode(notes));
                                              setSheetState(() {
                                                loadNotes();
                                              });
                                            });
                                          },
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                                          onPressed: () async {
                                            notes.removeAt(index);
                                            await prefs.setString('user_notes', jsonEncode(notes));
                                            setSheetState(() {
                                              loadNotes();
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Nota eliminada', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                                                  backgroundColor: AppColors.error,
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            }
                                          },
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note['content'] ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    note['date'] ?? '',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditNoteDialog(BuildContext context, {Map<String, dynamic>? noteToEdit, required Function(Map<String, dynamic>) onSave}) {
    final titleController = TextEditingController(text: noteToEdit?['title']);
    final contentController = TextEditingController(text: noteToEdit?['content']);
    int selectedColorVal = noteToEdit?['color'] ?? 0xFF8B7FE8;
    final formKey = GlobalKey<FormState>();

    final colorsList = [
      0xFF8B7FE8, // Morado
      0xFF3A86F5, // Azul
      0xFF00C853, // Verde
      0xFFFFAB00, // Amarillo/Naranja
      0xFFFF5C5C, // Rojo
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(noteToEdit == null ? 'Nueva Nota' : 'Editar Nota', style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Título',
                          labelStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contentController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Contenido',
                          labelStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      Text('SELECCIONA UN COLOR', style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: colorsList.map((cVal) {
                          final isSelected = selectedColorVal == cVal;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColorVal = cVal;
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(cVal),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: AppTextStyles.caption),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    
                    final now = DateTime.now();
                    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

                    final note = {
                      'id': noteToEdit?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text.trim(),
                      'content': contentController.text.trim(),
                      'color': selectedColorVal,
                      'date': dateStr,
                    };
                    onSave(note);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Guardar', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileSheet(String currentName, String currentEmail) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Editar Perfil', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text('Actualiza tu información personal', style: AppTextStyles.caption),
                      const SizedBox(height: 24),
                      Text('Nombre Completo', style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Tu nombre',
                          hintStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'El nombre no puede estar vacío' : null,
                      ),
                      const SizedBox(height: 20),
                      Text('Correo Electrónico', style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'ejemplo@correo.com',
                          hintStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'El correo no puede estar vacío';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Ingresa un correo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: saving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => saving = true);
                            
                            final result = await ref.read(authProvider.notifier).updateProfile(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                            );
                            
                            if (context.mounted) {
                              setSheetState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'], style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                                  backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                                ),
                              );
                              if (result['success']) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: saving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Guardar Cambios', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final unreadList = [
              {
                'title': '🎯 Meta de Ahorro cerca',
                'desc': 'Tu meta "Fondo de Emergencia" ha alcanzado el 80% de su objetivo.',
                'time': 'Hace 2 horas',
              },
              {
                'title': '💸 Alerta de Gastos',
                'desc': 'Has gastado el 85% de tu presupuesto asignado a la categoría Alimentación.',
                'time': 'Ayer',
              },
              {
                'title': '💎 Actualización Pro disponible',
                'desc': 'Prueba la exportación de reportes PDF personalizados y backups ilimitados.',
                'time': 'Hace 3 días',
              }
            ];

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notificaciones', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
                      if (_unreadCount > 0)
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('notif_0', true);
                            await prefs.setBool('notif_1', true);
                            await prefs.setBool('notif_2', true);
                            setSheetState(() {
                              _notificationsRead = [true, true, true];
                            });
                            setState(() {});
                          },
                          child: Text('Marcar todas como leídas', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_unreadCount == 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 12),
                            Text('No tienes notificaciones pendientes', style: AppTextStyles.labelLarge),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(unreadList.length, (index) {
                        final isRead = _notificationsRead[index];
                        final item = unreadList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead ? AppColors.surfaceLight.withOpacity(0.4) : AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Expanded(child: Text(item['title']!, style: AppTextStyles.labelLarge.copyWith(fontSize: 14, fontWeight: isRead ? FontWeight.w500 : FontWeight.bold))),
                                if (!isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  )
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(item['desc']!, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: isRead ? AppColors.textHint : AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                Text(item['time']!, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                              ],
                            ),
                            onTap: isRead ? null : () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('notif_$index', true);
                              setSheetState(() {
                                _notificationsRead[index] = true;
                              });
                              setState(() {});
                            },
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSecuritySheet() {
    bool biometricLock = false;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            SharedPreferences.getInstance().then((prefs) {
              final val = prefs.getBool('biometric_lock') ?? false;
              if (val != biometricLock) {
                setSheetState(() => biometricLock = val);
              }
            });

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Seguridad', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('Protege tu cuenta y datos financieros', style: AppTextStyles.caption),
                  const SizedBox(height: 24),
                  
                  SwitchListTile(
                    title: Text('Bloqueo de Aplicación', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                    subtitle: Text('Solicitar PIN o huella dactilar al abrir la app', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    value: biometricLock,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('biometric_lock', value);
                      setSheetState(() => biometricLock = value);
                    },
                  ),
                  
                  const Divider(color: AppColors.surfaceLight, height: 24),
                  
                  ListTile(
                    title: Text('Cambiar Contraseña', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                    subtitle: Text('Actualiza tus credenciales de acceso', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pop(context);
                      _showChangePasswordDialog();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Cambiar Contraseña', style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual',
                          labelStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          labelStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          labelStyle: AppTextStyles.caption,
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v != newController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: AppTextStyles.caption),
                ),
                ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => loading = true);
                    
                    final result = await ref.read(authProvider.notifier).updatePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                    
                    if (context.mounted) {
                      setDialogState(() => loading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'], style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                          backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                        ),
                      );
                      if (result['success']) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Actualizar', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpgradeProSheet() {
    bool upgrading = false;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F1924),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('💎', style: TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    _isPro ? '¡Ya eres Plan PRO!' : 'FinanGoal PRO',
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPro ? 'Disfrutas de todos los beneficios premium' : 'Lleva el control de tus finanzas al siguiente nivel',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildProBenefit('🎯 Metas de Ahorro Ilimitadas', 'Crea tantas metas como necesites sin restricciones.'),
                  const SizedBox(height: 12),
                  _buildProBenefit('📄 Reportes PDF Personalizados', 'Exporta tus dashboards con estilos y filtros avanzados.'),
                  const SizedBox(height: 12),
                  _buildProBenefit('🔔 Notificaciones Inteligentes', 'Alertas avanzadas cuando te acerques a tus límites de gasto.'),
                  const SizedBox(height: 12),
                  _buildProBenefit('☁️ Respaldo en la Nube', 'Sincroniza tus datos de forma segura entre dispositivos.'),
                  
                  const SizedBox(height: 32),
                  
                  if (_isPro)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Cerrar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                      ),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('\$4.99 USD', style: AppTextStyles.displayMedium.copyWith(fontSize: 24, color: AppColors.primary)),
                        Text(' / mes', style: AppTextStyles.caption.copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: upgrading ? null : () async {
                            setSheetState(() => upgrading = true);
                            
                            await Future.delayed(const Duration(milliseconds: 1800));
                            
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_pro', true);
                            
                            if (context.mounted) {
                              setSheetState(() {
                                upgrading = false;
                              });
                              setState(() {
                                _isPro = true;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡Suscripción Pro activada con éxito! 💎', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: upgrading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text('Comprar Plan Pro', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProBenefit(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge.copyWith(fontSize: 13, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String value, label;
  final Color? color;
  const _StatBadge({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.labelLarge.copyWith(
                fontSize: 16, color: color ?? AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String icon, label;
  final Color bg;
  final String? badge;
  final Color? badgeColor, textColor;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon, required this.label, required this.bg,
    required this.onTap, this.badge, this.badgeColor,
    this.textColor, this.isLast = false,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: item.isLast ? null : Border(
            bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: item.bg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(item.icon,
                  style: const TextStyle(fontSize: 17))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label,
                style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    color: item.textColor ?? AppColors.textPrimary))),
            if (item.badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.badgeColor ?? AppColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(item.badge!,
                    style: AppTextStyles.caption.copyWith(
                        color: item.badgeColor ?? AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            if (!item.isLast)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}