import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/features/auth/providers/auth_provider.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/home/presentation/widgets/balance_card.dart';
import 'package:finan_goal/features/home/presentation/widgets/income_expense_row.dart';
import 'package:finan_goal/features/home/presentation/widgets/savings_goal_card.dart';
import 'package:finan_goal/features/transaction/providers/transaction_provider.dart';
import 'package:finan_goal/features/goals/providers/saving_goals_provider.dart';
import 'package:finan_goal/core/services/pdf_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;



  List<File> _pdfReports = [];
  bool _loadingPdfs = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPdfReports();
  }

  Future<void> _loadPdfReports() async {
    setState(() => _loadingPdfs = true);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${docDir.path}/reports');
      if (await reportsDir.exists()) {
        final files = reportsDir.listSync();
        final pdfs = files
            .whereType<File>()
            .where((f) => f.path.endsWith('.pdf'))
            .toList();
        pdfs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        setState(() {
          _pdfReports = pdfs;
        });
      }
    } catch (_) {}
    setState(() => _loadingPdfs = false);
  }

  Future<void> _generatePdfReport() async {
    final transactions = ref.read(transactionProvider);
    final goals = ref.read(savingGoalsProvider);
    final authState = ref.read(authProvider);
    final name = authState.user?.name ?? 'Usuario';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando reporte PDF...',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final file = await PdfService.generateReport(
        transactions: transactions,
        goals: goals,
        userName: name,
      );

      await _loadPdfReports();

      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte PDF: $e',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deletePdfReport(File file) async {
    try {
      await file.delete();
      await _loadPdfReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte eliminado',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }



  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    const count = 5;
    _fadeAnims = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.6);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.6);
      return Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    // Datos reales desde los providers
    final income  = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final balance = ref.watch(balanceProvider);
    final goals   = ref.watch(savingGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _animated(0, _buildTopBar()),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _animated(
                    1,
                    BalanceCard(balance: balance, changePercent: 3.2),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _animated(
                    2,
                    IncomeExpenseRow(income: income, expense: expense),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _animated(3, _buildSectionHeader()),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: goals.isEmpty
                    ? SliverToBoxAdapter(
                        child: _animated(
                          4,
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🎯',
                                  style: TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sin metas de ahorro aún',
                                  style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Crea una en la sección de Metas para empezar a ahorrar.',
                                  style: AppTextStyles.caption,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _animated(
                              4,
                              SavingsGoalCard(
                                emoji: goals[index].emoji,
                                name: goals[index].name,
                                current: goals[index].savedAmount,
                                target: goals[index].targetAmount,
                              ),
                            ),
                          ),
                          childCount: goals.length,
                        ),
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _animated(4, _buildPdfSectionHeader()),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverToBoxAdapter(
                  child: _animated(4, _buildPdfReportSection()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Usuario';
    final shortName = userName.split(' ').first;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $shortName 👋',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text('Mis Finanzas', style: AppTextStyles.displayMedium),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: () {
                final imagePath = ref.watch(profileImageProvider);
                if (imagePath != null && File(imagePath).existsSync()) {
                  return Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                  );
                } else {
                  return Center(
                    child: Text(
                      shortName.isNotEmpty ? shortName[0].toUpperCase() : 'U',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
              }(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Metas de Ahorro 🎯',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
        GestureDetector(
          onTap: () => context.go('/goals'),
          child: Text(
            'Ver todo',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Reportes y Exportaciones 📄',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
      ],
    );
  }

  String _formatPdfFileName(File file) {
    try {
      final modTime = file.lastModifiedSync();
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return 'Reporte - ${modTime.day} ${months[modTime.month - 1]}, ${modTime.year} ${modTime.hour.toString().padLeft(2, '0')}:${modTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return file.path.split('/').last.split('\\').last;
    }
  }

  String _getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  Widget _buildPdfReportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genera un reporte PDF con tu balance, historial detallado de ingresos y gastos, y el progreso de tus metas de ahorro.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          
          // Botón Generar PDF
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _generatePdfReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Generar Reporte PDF',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          
          if (_loadingPdfs)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_pdfReports.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'HISTORIAL DE REPORTES',
              style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Lista de reportes
            Column(
              children: _pdfReports.map((file) {
                final fileSize = _getFileSizeString(file.lengthSync());
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF152336),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.description_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatPdfFileName(file),
                              style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fileSize,
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
                        onPressed: () => OpenFilex.open(file.path),
                        tooltip: 'Abrir reporte',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => _deletePdfReport(file),
                        tooltip: 'Eliminar reporte',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No has generado reportes aún.',
                style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}