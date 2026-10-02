import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../checkout/delivery_tracking_screen.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'cart_screen.dart';

class VibeDrawer extends StatefulWidget {
  const VibeDrawer({super.key});

  @override
  State<VibeDrawer> createState() => _VibeDrawerState();
}

class _VibeDrawerState extends State<VibeDrawer> {
  String _userName = 'VibeVault Explorer';
  String _userEmail = 'guest@vibevault.com';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _isLoggedIn = true;
        _userEmail = user.email ?? 'member@vibevault.com';
      });

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['full_name'] != null) {
          if (mounted) {
            setState(() {
              _userName = profile['full_name'] as String;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF7F00FF);
    const accentColor = Color(0xFFE100FF);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 1. User Profile Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primaryColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'V',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Vault Verified Member',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Active Order Banner (Hero in Drawer)
            ListenableBuilder(
              listenable: OrderService.instance,
              builder: (context, _) {
                final orders = OrderService.instance.orders;
                if (orders.isEmpty) return const SizedBox.shrink();

                final activeOrder = orders.first;

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.2),
                        accentColor.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                orders.length > 1
                                    ? '${orders.length} ACTIVE DELIVERIES'
                                    : 'ACTIVE SHIPMENT',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            activeOrder.id,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        orders.length > 1
                            ? '${orders.length} deliveries in transit (${activeOrder.id}, ${orders[1].id})'
                            : activeOrder.statusDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // close drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryTrackingScreen(
                                  orderId: activeOrder.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.radar_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            orders.length > 1
                                ? 'Track All (${orders.length}) Deliveries'
                                : 'Track Live Delivery',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 3. Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  ListenableBuilder(
                    listenable: OrderService.instance,
                    builder: (context, _) {
                      final orders = OrderService.instance.orders;
                      return _buildDrawerItem(
                        icon: Icons.local_shipping_outlined,
                        title: 'Orders & Tracking',
                        subtitle: orders.isNotEmpty
                            ? '${orders.length} active delivery package(s)'
                            : 'Track your deliveries & drops',
                        badgeText: orders.isNotEmpty ? '${orders.length}' : null,
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onTap: () {
                          Navigator.pop(context);
                          final activeOrder = OrderService.instance.activeOrder;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeliveryTrackingScreen(
                                orderId: activeOrder?.id ?? 'VV-ACTIVE',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ListenableBuilder(
                    listenable: CartService.instance,
                    builder: (context, _) {
                      final count = CartService.instance.itemCount;
                      return _buildDrawerItem(
                        icon: Icons.shopping_bag_outlined,
                        title: 'My Vibe Bag',
                        subtitle: count > 0 ? '$count item(s) ready for checkout' : 'Your bag is empty',
                        badgeText: count > 0 ? '$count' : null,
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Curate Aesthetic',
                    subtitle: 'Personalize your feed vibe tags',
                    isDark: isDark,
                    primaryColor: primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/onboarding');
                    },
                  ),
                  const Divider(height: 28),
                  if (_isLoggedIn)
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'Switch accounts or logout',
                      isDark: isDark,
                      primaryColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: _handleSignOut,
                    )
                  else
                    _buildDrawerItem(
                      icon: Icons.login_rounded,
                      title: 'Sign In / Register',
                      subtitle: 'Access saved lockers and history',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/auth');
                      },
                    ),
                ],
              ),
            ),

            // 4. Footer Branding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'VibeVault v1.0.0 • Curated Archive',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white30 : Colors.black26,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color primaryColor,
    Color? iconColor,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? primaryColor).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      trailing: badgeText != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFE100FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 20,
            ),
    );
  }
}
