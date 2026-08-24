import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/item_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'item_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  final String? initialType;
  final String? initialSearch;
  final int?    initialCategoryId;

  const BrowseScreen({
    super.key,
    this.initialType,
    this.initialSearch,
    this.initialCategoryId,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchCtrl    = TextEditingController();
  final _scrollCtrl    = ScrollController();

  String?  _selectedType;
  int?     _selectedCategoryId;
  int      _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedType       = widget.initialType;
    _selectedCategoryId = widget.initialCategoryId;

    if (widget.initialSearch != null) {
      _searchCtrl.text = widget.initialSearch!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems(refresh: true);
      context.read<ItemProvider>().loadCategories();
    });

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final provider = context.read<ItemProvider>();
      if (!provider.isLoadingMore && provider.hasMorePages) {
        _currentPage++;
        _loadItems();
      }
    }
  }

  void _loadItems({bool refresh = false}) {
    if (refresh) _currentPage = 1;
    context.read<ItemProvider>().loadItems(
      type:       _selectedType,
      categoryId: _selectedCategoryId,
      search:     _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      page:       _currentPage,
      refresh:    refresh,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<ItemProvider>();
    final items      = provider.items;
    final categories = provider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context, categories),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:    'Search items...',
                prefixIcon:  const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadItems(refresh: true);
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadItems(refresh: true),
            ),
          ),

          // ─── Filter Chips ─────────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedType == null,
                  onTap: () { setState(() => _selectedType = null); _loadItems(refresh: true); },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Lost',
                  selected: _selectedType == 'lost',
                  color: AppTheme.lostColor,
                  onTap: () { setState(() => _selectedType = 'lost'); _loadItems(refresh: true); },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Found',
                  selected: _selectedType == 'found',
                  color: AppTheme.foundColor,
                  onTap: () { setState(() => _selectedType = 'found'); _loadItems(refresh: true); },
                ),
                ...categories.map((c) {
                  final isSelected = _selectedCategoryId == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: c.name,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedCategoryId = isSelected ? null : c.id);
                        _loadItems(refresh: true);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // ─── Results Count ────────────────────────────────────────────────────
          if (provider.pagination != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${provider.pagination!.total} items found',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Outfit'),
                  ),
                ],
              ),
            ),

          // ─── Items Grid ───────────────────────────────────────────────────────
          Expanded(
            child: provider.isLoading && items.isEmpty
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 14, mainAxisSpacing: 14,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => const ShimmerCard(),
                  )
                : provider.error != null && items.isEmpty
                    ? ErrorStateWidget(message: provider.error!, onRetry: () => _loadItems(refresh: true))
                    : items.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.search_off_rounded,
                            title: 'No items found',
                            message: 'Try adjusting your search or filters',
                            actionLabel: 'Clear Filters',
                            onAction: () {
                              setState(() { _selectedType = null; _selectedCategoryId = null; });
                              _searchCtrl.clear();
                              _loadItems(refresh: true);
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadItems(refresh: true),
                            color: AppTheme.primaryColor,
                            child: GridView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 0.72,
                                crossAxisSpacing: 14, mainAxisSpacing: 14,
                              ),
                              itemCount: items.length + (provider.isLoadingMore ? 2 : 0),
                              itemBuilder: (ctx, i) {
                                if (i >= items.length) return const ShimmerCard();
                                final item = items[i];
                                return ItemCard(
                                  item: item,
                                  onTap: () => Navigator.push(
                                    ctx,
                                    MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Outfit')),
            const SizedBox(height: 16),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Outfit')),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final type in [null, 'lost', 'found'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _selectedType = type);
                          Navigator.pop(context);
                          _loadItems(refresh: true);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedType == type
                              ? AppTheme.primaryColor.withOpacity(0.1) : null,
                          side: BorderSide(
                            color: _selectedType == type ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(type == null ? 'All' : type.capitalize()),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _selectedType = null; _selectedCategoryId = null; });
                _searchCtrl.clear();
                Navigator.pop(context);
                _loadItems(refresh: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Clear All Filters'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

extension StringX on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : c.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : c,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}
