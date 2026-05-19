import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shifa_shimmer.dart';
import '../../../../core/auth/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader().animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 32),
                  _buildWelcomeSection().animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 40),
                  _buildStaggeredGrid(statsAsync, context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFF8FAFC)],
          stops: [0.0, 0.4],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isAdmin = ref.watch(isAdminProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
          ),
          child: Image.asset(
            'assets/images/shifa_logo.jpeg',
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
        Row(
          children: [
            if (isAdmin) ...[
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                ),
                tooltip: 'Staff Management (Admin Only)',
                onPressed: () => context.push('/admin'),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No new notifications. All clinical systems are optimal.',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: AppColors.error.withOpacity(0.12),
                child: const Icon(Icons.logout_rounded, color: AppColors.error),
              ),
              tooltip: 'Sign Out Portal',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to end your session and log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final staffUser = ref.watch(currentStaffUserProvider);
    final staffId = staffUser?.staffId ?? 'Staff';
    final roleName = staffUser?.isAdmin ?? false ? 'Administrator' : 'Clinical Caregiver';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Dashboard • $roleName',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome, $staffId',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildStaggeredGrid(AsyncValue<Map<String, int>> statsAsync, BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.3,
          child: statsAsync.when(
            loading: () => ShifaShimmer.card(height: 220),
            error: (_, __) => const SizedBox(),
            data: (stats) => _GlassCard(
              title: 'Active Admissions',
              value: '${stats['active']}',
              subtitle: 'Current hospital occupancy',
              icon: Icons.personal_injury_rounded,
              color: AppColors.primary,
              trend: '▲ 8% from yesterday',
              isHero: true,
              showGraph: true,
            ),
          ).animate().scale(delay: 300.ms),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: _GlassCard(
            title: 'New Patient',
            icon: Icons.person_add_rounded,
            color: const Color(0xFF2E7D32),
            onTap: () => context.go('/register_patient'),
            isAction: true,
          ).animate().scale(delay: 400.ms),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: _GlassCard(
            title: 'Search MRN',
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFFE65100),
            onTap: () => context.go('/search_patient'),
            isAction: true,
          ).animate().scale(delay: 500.ms),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.8,
          child: statsAsync.when(
            loading: () => ShifaShimmer.card(),
            error: (_, __) => const SizedBox(),
            data: (stats) => _GlassCard(
              title: 'Total Records',
              value: '${stats['total']}',
              color: Colors.blueGrey[800]!,
              compact: true,
            ),
          ).animate().scale(delay: 600.ms),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.8,
          child: statsAsync.when(
            loading: () => ShifaShimmer.card(),
            error: (_, __) => const SizedBox(),
            data: (stats) => _GlassCard(
              title: 'Today\'s Reg.',
              value: '${stats['today']}',
              color: const Color(0xFFC62828),
              compact: true,
              trend: '+2 today',
            ),
          ).animate().scale(delay: 700.ms),
        ),
      ],
    );
  }
}

class _GlassCard extends StatefulWidget {
  final String title;
  final String? value;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;
  final bool isHero;
  final bool isAction;
  final bool compact;
  final bool showGraph;

  const _GlassCard({
    required this.title,
    this.value,
    this.subtitle,
    this.icon,
    required this.color,
    this.trend,
    this.onTap,
    this.isHero = false,
    this.isAction = false,
    this.compact = false,
    this.showGraph = false,
  });

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: 100.ms,
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isPressed ? 0.2 : 0.1),
              blurRadius: _isPressed ? 30 : 20,
              offset: Offset(0, _isPressed ? 12 : 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : (widget.showGraph ? 20 : 22),
                  vertical: widget.compact ? 12 : (widget.showGraph ? 16 : 20),
                ),
                decoration: BoxDecoration(
                  color: (widget.isHero ? widget.color : Colors.white).withValues(alpha: widget.isHero ? 0.9 : 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.icon != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (widget.isHero ? Colors.white : widget.color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(widget.icon, color: widget.isHero ? Colors.white : widget.color, size: 22),
                          ),
                        if (widget.trend != null)
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (widget.trend!.contains('▲') ? AppColors.success : AppColors.error).withValues(alpha: widget.isHero ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.trend!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isHero ? Colors.white : (widget.trend!.contains('▲') ? AppColors.success : AppColors.error),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.showGraph) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 3),
                                  const FlSpot(1, 4),
                                  const FlSpot(2, 3.5),
                                  const FlSpot(3, 5),
                                  const FlSpot(4, 4.5),
                                  const FlSpot(5, 6),
                                ],
                                isCurved: true,
                                color: Colors.white.withValues(alpha: 0.5),
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.value != null)
                          Text(
                            widget.value!,
                            style: GoogleFonts.outfit(
                              fontSize: widget.compact ? 22 : (widget.showGraph ? 32 : 38),
                              fontWeight: FontWeight.bold,
                              color: widget.isHero ? Colors.white : AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: widget.compact ? 12 : (widget.showGraph ? 14 : 16),
                            fontWeight: FontWeight.bold,
                            color: widget.isHero ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: widget.isHero ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


