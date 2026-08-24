<?php
/**
 * POST /api/items/delete.php
 * Soft-delete an item. Owner-only.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$authUser = requireAuth();
$db       = Database::getConnection();

$body   = getRequestBody();
$itemId = (int) ($body['id'] ?? 0);

if ($itemId <= 0) {
    errorResponse('Item ID is required.', 422);
}

$stmt = $db->prepare("SELECT user_id FROM items WHERE id = :id AND status != 'deleted' LIMIT 1");
$stmt->execute([':id' => $itemId]);
$item = $stmt->fetch();

if (!$item) {
    errorResponse('Item not found.', 404);
}
if ((int) $item['user_id'] !== (int) $authUser['id']) {
    errorResponse('You are not authorized to delete this item.', 403);
}

$db->prepare("UPDATE items SET status = 'deleted' WHERE id = :id")
   ->execute([':id' => $itemId]);

successResponse('Item deleted successfully.');
