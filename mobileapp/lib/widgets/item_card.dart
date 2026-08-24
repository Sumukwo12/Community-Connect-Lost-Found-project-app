import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onResolve;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: _buildImage(context),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      _StatusBadge(item: item),
                      const Spacer(),
                      if (item.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.categoryName!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    AppHelpers.truncate(item.description, 60),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Location & Date
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        AppHelpers.formatDate(item.dateOccurred),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  // Actions (for My Items)
                  if (showActions) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.isActive && onResolve != null)
                          _ActionButton(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Resolve',
                            color: AppTheme.secondaryColor,
                            onTap: onResolve!,
                          ),
                        if (onEdit != null) ...[
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            color: AppTheme.primaryColor,
                            onTap: onEdit!,
                          ),
                        ],
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            color: AppTheme.lostColor,
                            onTap: onDelete!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 140,
          color: AppTheme.primaryColor.withOpacity(0.08),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => _PlaceholderImage(item: item),
      );
    }
    return _PlaceholderImage(item: item);
  }
}

class _StatusBadge extends StatelessWidget {
  final ItemModel item;
  const _StatusBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (item.isResolved) {
      color = Colors.grey;
      label = 'Resolved';
    } else if (item.isLost) {
      color = AppTheme.lostColor;
      label = 'Lost';
    } else {
      color = AppTheme.foundColor;
      label = 'Found';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final ItemModel item;
  const _PlaceholderImage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.isLost
              ? [AppTheme.lostColor.withOpacity(0.2), AppTheme.lostColor.withOpacity(0.05)]
              : [AppTheme.foundColor.withOpacity(0.2), AppTheme.foundColor.withOpacity(0.05)],
        ),
      ),
      child: Icon(
        item.isLost ? Icons.search_rounded : Icons.inventory_2_rounded,
        size: 40,
        color: (item.isLost ? AppTheme.lostColor : AppTheme.foundColor).withOpacity(0.5),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final Color     color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
