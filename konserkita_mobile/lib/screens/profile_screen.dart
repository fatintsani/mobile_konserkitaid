import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:konserkita_mobile/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppConstants.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.phone!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (user.role == 'organizer' || user.role == 'admin' || user.role == 'super_admin') ...[
              _buildMenuCard(
                context,
                title: 'Organizer Dashboard',
                icon: Icons.dashboard,
                onTap: () => context.push('/organizer'),
              ),
              const Divider(indent: 16, endIndent: 16),
            ],
            _buildMenuCard(
              context,
              title: 'Edit Profile',
              icon: Icons.person_outline,
              onTap: () => context.push('/edit-profile'),
            ),
            _buildMenuCard(
              context,
              title: 'Passkeys & Security',
              icon: Icons.fingerprint,
              onTap: () => context.push('/passkeys'),
            ),
            _buildMenuCard(
              context,
              title: 'Active Sessions',
              icon: Icons.devices,
              onTap: () => context.push('/active-sessions'),
            ),
            _buildMenuCard(
              context,
              title: 'Login Activity',
              icon: Icons.history,
              onTap: () => context.push('/login-activity'),
            ),
            _buildMenuCard(
              context,
              title: 'Transaction History',
              icon: Icons.receipt_long,
              onTap: () => context.push('/transactions'),
            ),
            _buildMenuCard(
              context,
              title: 'My Wishlist',
              icon: Icons.favorite_border,
              onTap: () => context.push('/wishlist'),
            ),
            _buildMenuCard(
              context,
              title: 'My Refunds',
              icon: Icons.refresh,
              onTap: () => context.push('/my-refunds'),
            ),
            _buildMenuCard(
              context,
              title: 'My Reviews',
              icon: Icons.star_outline,
              onTap: () => context.push('/my-reviews'),
            ),
            _buildMenuCard(
              context,
              title: 'Affiliate & Referrals',
              icon: Icons.group_add_outlined,
              onTap: () => context.push('/referral-dashboard'),
            ),
            _buildMenuCard(
              context,
              title: 'Recommendation Preferences',
              icon: Icons.tune,
              onTap: () => context.push('/preferences'),
            ),
            _buildMenuCard(
              context,
              title: 'Followed Organizers',
              icon: Icons.storefront,
              onTap: () => context.push('/followed-organizers'),
            ),
            _buildMenuCard(
              context,
              title: 'My Tickets',
              icon: Icons.confirmation_number_outlined,
              onTap: () => context.push('/my-tickets'),
            ),
            _buildMenuCard(
              context,
              title: l10n.language,
              icon: Icons.language,
              onTap: () => context.push('/language'),
            ),
            _buildMenuCard(
              context,
              title: l10n.logout,
              icon: Icons.logout,
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.logout),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : AppConstants.primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
