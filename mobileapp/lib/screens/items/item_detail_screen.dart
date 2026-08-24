import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../services/message_service.dart';
import '../messages/conversation_screen.dart';
import '../auth/login_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _reportLoading = false;

  void _contactPoster() {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (authUser.id == widget.item.userId) {
      AppHelpers.showInfo(context, 'This is your own item.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          otherUserId:   widget.item.userId,
          otherUserName: widget.item.posterName ?? 'User',
          itemId:        widget.item.id,
        ),
      ),
    );
  }

  Future<void> _reportItem() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final reasonCtrl = TextEditingController();
    final confirmed  = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report Item', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe why you are reporting this item:',
                style: TextStyle(fontFamily: 'Outfit')),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter your reason...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lostColor),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (reasonCtrl.text.trim().length < 10) {
      AppHelpers.showError(context, 'Please provide a reason of at least 10 characters.');
      return;
    }

    setState(() => _reportLoading = true);
    final response = await MessageService.reportItem(
      itemId: widget.item.id,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _reportLoading = false);

    if (response.success) {
      AppHelpers.showSuccess(context, 'Item reported. Thank you!');
    } else {
      AppHelpers.showError(context, response.message);
    }
  }

  Future<void> _resolveItem() async {
    final confirmed = await AppHelpers.showConfirmDialog(
      context,
      title:       'Mark as Resolved?',
      message:     'Are you sure this item has been returned/found? This cannot be undone.',
      confirmText: 'Yes, Resolve',
    );
    if (!confirmed || !mounted) return;

    final response = await context.read<ItemProvider>().resolveItem(widget.item.id);
    if (!mounted) return;
    if (response.success) {
      AppHelpers.showSuccess(context, 'Item marked as resolved!');
      Navigator.pop(context);
    } else {
      AppHelpers.showError(context, response.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item     = widget.item;
    final authUser = context.watch<AuthProvider>().user;
    final isOwner  = authUser?.id == item.userId;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Hero Image App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => _PlaceholderHero(item: item),
                    )
                  : _PlaceholderHero(item: item),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + category row
                  Row(
                    children: [
                      _Badge(
                        label: item.isLost ? 'LOST' : 'FOUND',
                        color: item.isLost ? AppTheme.lostColor : AppTheme.foundColor,
                      ),
                      if (item.isResolved) ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'RESOLVED', color: Colors.grey),
                      ],
                      const Spacer(),
                      if (item.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item.categoryName!,
                              style: const TextStyle(
                                fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(item.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
                  const SizedBox(height: 16),

                  // Info rows
                  _InfoRow(icon: Icons.location_on_rounded,   label: 'Location',    value: item.location),
                  _InfoRow(icon: Icons.calendar_today_rounded, label: 'Date',        value: AppHelpers.formatDate(item.dateOccurred)),
                  if (item.timeOccurred != null && item.timeOccurred!.isNotEmpty)
                    _InfoRow(icon: Icons.access_time_rounded,  label: 'Time',        value: item.timeOccurred!),
                  _InfoRow(icon: Icons.person_rounded,         label: 'Posted by',   value: item.posterName ?? 'Anonymous'),
                  _InfoRow(icon: Icons.calendar_month_rounded, label: 'Posted',
                      value: AppHelpers.formatRelativeTime(item.createdAt)),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(fontSize: 14, height: 1.6, fontFamily: 'Outfit')),

                  if (item.additionalInformation != null && item.additionalInformation!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Additional Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
                    const SizedBox(height: 8),
                    Text(item.additionalInformation!,
                        style: const TextStyle(fontSize: 14, height: 1.6, fontFamily: 'Outfit')),
                  ],

                  const SizedBox(height: 32),

                  // ─── Action Buttons ───────────────────────────────────────────
                  if (!isOwner && item.isActive) ...[
                    ElevatedButton.icon(
                      onPressed: _contactPoster,
                      icon: const Icon(Icons.message_rounded),
                      label: const Text('Contact Poster'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isOwner && item.isActive) ...[
                    ElevatedButton.icon(
                      onPressed: _resolveItem,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Mark as Resolved'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (!isOwner && item.isActive)
                    OutlinedButton.icon(
                      onPressed: _reportLoading ? null : _reportItem,
                      icon: _reportLoading
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.flag_rounded),
                      label: const Text('Report Item'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.lostColor,
                        side: BorderSide(color: AppTheme.lostColor.withOpacity(0.5)),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Outfit', fontSize: 14)),
          Expanded(
            child: Text(value,
                style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Outfit', fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color, fontFamily: 'Outfit',
          )),
    );
  }
}

class _PlaceholderHero extends StatelessWidget {
  final ItemModel item;
  const _PlaceholderHero({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.isLost
              ? [AppTheme.lostColor.withOpacity(0.3), AppTheme.lostColor.withOpacity(0.05)]
              : [AppTheme.foundColor.withOpacity(0.3), AppTheme.foundColor.withOpacity(0.05)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Icon(
        item.isLost ? Icons.search_rounded : Icons.inventory_2_rounded,
        size: 80,
        color: (item.isLost ? AppTheme.lostColor : AppTheme.foundColor).withOpacity(0.3),
      ),
    );
  }
}
