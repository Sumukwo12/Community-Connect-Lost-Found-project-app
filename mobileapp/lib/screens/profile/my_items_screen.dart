import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../providers/item_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/item_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../items/item_detail_screen.dart';

class MyItemsScreen extends StatefulWidget {
  final int initialTabIndex;
  const MyItemsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadMyItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(ItemModel item) async {
    final confirmed = await AppHelpers.showConfirmDialog(
      context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete "${item.title}"? This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final res = await context.read<ItemProvider>().deleteItem(item.id);
      if (mounted) {
        if (res.success) {
          AppHelpers.showSuccess(context, 'Item deleted successfully.');
        } else {
          AppHelpers.showError(context, res.message);
        }
      }
    }
  }

  Future<void> _handleResolve(ItemModel item) async {
    final confirmed = await AppHelpers.showConfirmDialog(
      context,
      title: 'Mark as Resolved',
      message: 'Mark "${item.title}" as resolved/recovered?',
      confirmText: 'Mark Resolved',
    );

    if (confirmed && mounted) {
      final res = await context.read<ItemProvider>().resolveItem(item.id);
      if (mounted) {
        if (res.success) {
          AppHelpers.showSuccess(context, 'Item marked as resolved.');
        } else {
          AppHelpers.showError(context, res.message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Items'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Lost (${provider.myLostItems.length})'),
            Tab(text: 'Found (${provider.myFoundItems.length})'),
            Tab(text: 'Resolved (${provider.resolvedItems.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemList(
            items: provider.myLostItems,
            isLoading: isLoading,
            emptyTitle: 'No Lost Items Reported',
            emptySubtitle: 'You haven\'t posted any lost items yet.',
            emptyIcon: Icons.search_off_rounded,
          ),
          _buildItemList(
            items: provider.myFoundItems,
            isLoading: isLoading,
            emptyTitle: 'No Found Items Reported',
            emptySubtitle: 'You haven\'t reported finding any items yet.',
            emptyIcon: Icons.inventory_2_rounded,
          ),
          _buildItemList(
            items: provider.resolvedItems,
            isLoading: isLoading,
            emptyTitle: 'No Resolved Items',
            emptySubtitle: 'Items you mark as resolved will appear here.',
            emptyIcon: Icons.check_circle_outline_rounded,
            allowResolve: false,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList({
    required List<ItemModel> items,
    required bool isLoading,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    bool allowResolve = true,
  }) {
    if (isLoading && items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: ShimmerCard(),
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<ItemProvider>().loadMyItems(),
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: EmptyStateWidget(
              title: emptyTitle,
              message: emptySubtitle,
              icon: emptyIcon,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ItemProvider>().loadMyItems(),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ItemCard(
              item: item,
              showActions: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                );
              },
              onResolve: (allowResolve && item.isActive) ? () => _handleResolve(item) : null,
              onDelete: () => _handleDelete(item),
            ),
          );
        },
      ),
    );
  }
}
