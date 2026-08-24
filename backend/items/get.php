<?php
/**
 * GET /api/items/get.php?id={item_id}
 * Get a single item with full details.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    errorResponse('Method not allowed.', 405);
}

$itemId = (int) ($_GET['id'] ?? 0);
if ($itemId <= 0) {
    errorResponse('Item ID is required.', 422);
}

$db   = Database::getConnection();
$stmt = $db->prepare(
    "SELECT i.*,
            c.name AS category_name,
            u.full_name AS poster_name,
            u.phone AS poster_phone,
            u.email AS poster_email
     FROM   items i
     LEFT JOIN categories c ON c.id = i.category_id
     LEFT JOIN users       u ON u.id = i.user_id
     WHERE  i.id = :id AND i.status != 'deleted'
     LIMIT  1"
);
$stmt->execute([':id' => $itemId]);
$item = $stmt->fetch();

if (!$item) {
    errorResponse('Item not found.', 404);
}

// Append full image URL
$item['image_url'] = !empty($item['image'])
    ? UPLOAD_URL . basename($item['image'])
    : null;

// Do not expose hashed password or reset token
unset($item['password'], $item['reset_token'], $item['reset_expires']);

successResponse('Item retrieved.', $item);
