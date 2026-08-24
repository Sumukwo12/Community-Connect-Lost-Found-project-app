import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/item.dart';
import '../../widgets/item_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../items/item_detail_screen.dart';
import '../items/browse_screen.dart';
import '../items/report_lost_screen.dart';
import '../items/report_found_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>()
        ..loadHomeFeed()
        ..loadCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _navigateToSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BrowseScreen(initialSearch: query)),
    );
  }

  void _showPostOptions(BuildContext ctx) {
    final isAuth = ctx.read<AuthProvider>().isAuth;
    if (!isAuth) {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to report?', style: AppTheme.headline3),
            const SizedBox(height: 20),
            _PostOptionTile(
              icon: Icons.search_off_rounded,
              color: AppTheme.lostColor,
              title: 'Report Lost Item',
              subtitle: 'I lost something and need help finding it',
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ReportLostScreen()));
              },
            ),
            const SizedBox(height: 12),
            _PostOptionTile(
              icon: Icons.inventory_2_rounded,
              color: AppTheme.foundColor,
              title: 'Report Found Item',
              subtitle: 'I found something and want to return it',
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ReportFoundScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user     = context.watch<AuthProvider>().user;
    final items    = context.watch<ItemProvider>();
    final greeting = _getGreeting();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ItemProvider>().loadHomeFeed(),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // ─── App Bar ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting,
                                    style: TextStyle(
                                      fontSize: 13, color: Colors.grey.shade500,
                                      fontFamily: 'Outfit',
                                    )),
                                Text(
                                  user != null ? user.fullName.split(' ').first : 'Guest',
                                  style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notification / Profile avatar
                          GestureDetector(
                            onTap: () {},
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                              child: user != null
                                  ? Text(
                                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Outfit',
                                      ),
                                    )
                                  : const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search Bar
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BrowseScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                              const SizedBox(width: 12),
                              Text('Search lost & found items...',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Quick Actions ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon:     Icons.search_off_rounded,
                              label:    'Report Lost',
                              gradient: [AppTheme.lostColor, const Color(0xFFFF8E8E)],
                              onTap:    () => _showPostOptions(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon:     Icons.inventory_2_rounded,
                              label:    'Report Found',
                              gradient: [AppTheme.foundColor, const Color(0xFF80E5E0)],
                              onTap:    () => _showPostOptions(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon:     Icons.grid_view_rounded,
                              label:    'Browse All',
                              gradient: [AppTheme.primaryColor, const Color(0xFF9B8FFF)],
                              onTap:    () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BrowseScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Stats Banner ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF9B8FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Lost Items',
                            value: items.recentLost.length.toString() + '+',
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                        Expanded(
                          child: _StatItem(
                            label: 'Found Items',
                            value: items.recentFound.length.toString() + '+',
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                        const Expanded(
                          child: _StatItem(label: 'Community', value: 'Active'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Recent Lost Items ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      const Text('Recent Lost Items',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BrowseScreen(initialType: 'lost')),
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              ),

              if (items.isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 3,
                      itemBuilder: (_, __) => Container(
                        width: 200, margin: const EdgeInsets.only(right: 14),
                        child: const ShimmerCard(),
                      ),
                    ),
                  ),
                )
              else if (items.recentLost.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No lost items yet',
                      message: 'Be the first to report a lost item',
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.recentLost.length,
                      itemBuilder: (ctx, i) {
                        final item = items.recentLost[i];
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 14),
                          child: ItemCard(
                            item: item,
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ─── Recent Found Items ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      const Text('Recent Found Items',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BrowseScreen(initialType: 'found')),
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              ),

              if (!items.isLoading && items.recentFound.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: EmptyStateWidget(
                      icon: Icons.inventory_2_rounded,
                      title: 'No found items yet',
                      message: 'Found something? Help return it!',
                    ),
                  ),
                )
              else if (!items.isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.recentFound.length,
                      itemBuilder: (ctx, i) {
                        final item = items.recentFound[i];
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 14),
                          child: ItemCard(
                            item: item,
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Outfit'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, fontFamily: 'Outfit')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Outfit')),
      ],
    );
  }
}

class _PostOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PostOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontFamily: 'Outfit')),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Outfit')),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
