import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_colors.dart';
import 'package:multi_vendor_ecommerce/core/theme/app_text_styles.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:multi_vendor_ecommerce/features/auth/presentation/bloc/auth_event.dart';
import 'package:multi_vendor_ecommerce/features/profile/domain/entities/user_profile.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_event.dart';
import 'package:multi_vendor_ecommerce/features/profile/presentation/bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ProfileBloc>().add(const LoadProfileEvent()),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          UserProfile? profile;
          if (state is ProfileLoaded) {
            profile = state.profile;
          } else if (state is ProfileUpdating) {
            profile = state.currentProfile;
          } else if (state is ProfileUpdateSuccess) {
            profile = state.updatedProfile;
          }

          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(
                      const LoadProfileEvent(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(const LoadProfileEvent());
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildProfileHeader(context, profile, isDark),
                const SizedBox(height: 24),
                _buildSectionHeader('Account & Preferences'),
                const SizedBox(height: 8),
                _buildMenuCard(context, [
                  _MenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Update your name, phone, and avatar',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'Manage delivery addresses and defaults',
                    onTap: () => context.push('/addresses'),
                  ),
                  _MenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Order History',
                    subtitle: 'View and track past orders',
                    onTap: () => context.push('/orders'),
                  ),
                  _MenuItem(
                    icon: Icons.rate_review_outlined,
                    title: 'My Reviews',
                    subtitle: 'Manage your verified purchase reviews',
                    onTap: () => context.push('/my-reviews'),
                  ),
                ]),
                if (profile.role == 'seller' || profile.role == 'admin') ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Management & Portals'),
                  const SizedBox(height: 8),
                  _buildMenuCard(context, [
                    _MenuItem(
                      icon: Icons.analytics_outlined,
                      title: 'Seller Analytics',
                      subtitle: 'View sales KPIs, orders & top products',
                      onTap: () => context.push('/seller/analytics'),
                    ),
                    _MenuItem(
                      icon: Icons.storefront_outlined,
                      title: 'Seller Dashboard',
                      subtitle: 'Manage your products and orders',
                      onTap: () => context.push('/seller'),
                    ),
                    if (profile.role == 'admin')
                      _MenuItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin Dashboard',
                        subtitle: 'Platform metrics, moderation & audits',
                        onTap: () => context.push('/admin'),
                      ),
                  ]),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    context.go('/auth/login');
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage:
                (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                ? Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.phone!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleBadgeColor(
                      profile.role,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getRoleBadgeColor(profile.role),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'seller':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == items.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 22),
                ),
                title: Text(
                  item.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(item.subtitle, style: AppTextStyles.bodySmall),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onTap: item.onTap,
              ),
              if (!isLast) const Divider(height: 1, indent: 60, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
