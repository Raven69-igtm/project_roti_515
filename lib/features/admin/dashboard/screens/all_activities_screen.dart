import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_stats_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/staggered_fade_animation.dart';

/// Halaman untuk menampilkan seluruh riwayat Aktivitas Terkini admin
class AllActivitiesScreen extends StatelessWidget {
  const AllActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<AdminStatsProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final activities = (statsProvider.stats['activities'] as List?) ?? [];

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: context.colors.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.surface,
                border: Border.all(color: context.colors.divider),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.colors.textDark,
                size: 18,
              ),
            ),
          ),
        ),
        title: Text(
          "Semua Aktivitas",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: context.colors.primaryOrange,
        onRefresh: () => statsProvider.refreshNow(auth.token),
        child: activities.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final act = activities[index];
                  final createdAt = DateTime.parse(act['created_at']).toLocal();
                  final title = act['title'] ?? '';
                  final subtitle = "${_getTimeAgo(createdAt)} • ${act['subtitle'] ?? ''}";
                  final icon = act['type'] == 'order' 
                      ? Icons.receipt_long_rounded 
                      : Icons.person_add_alt_1_rounded;

                  return StaggeredFadeAnimation(
                    index: index,
                    child: _buildActivityItem(context, title, subtitle, icon),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.divider),
            ),
            child: Icon(
              Icons.history_rounded,
              color: context.colors.textHint,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada aktivitas hari ini",
            style: GoogleFonts.plusJakartaSans(
              color: context.colors.textGrey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: context.colors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} mnt lalu';
    return 'Baru saja';
  }
}
