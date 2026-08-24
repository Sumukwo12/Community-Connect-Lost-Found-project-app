<?php
/**
 * POST /api/reports/create.php
 * Report an item for inappropriate content.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$authUser = requireAuth();
$db       = Database::getConnection();
$body     = getRequestBody();

$itemId = (int) ($body['item_id'] ?? 0);
$reason = sanitizeString($body['reason'] ?? '', 500);

if ($itemId <= 0) {
    errorResponse('Item ID is required.', 422);
}
if (mb_strlen($reason) < 10) {
    errorResponse('Please provide a reason of at least 10 characters.', 422);
}

// Verify item exists
$stmt = $db->prepare("SELECT id, user_id FROM items WHERE id = :id AND status != 'deleted' LIMIT 1");
$stmt->execute([':id' => $itemId]);
$item = $stmt->fetch();

if (!$item) {
    errorResponse('Item not found.', 404);
}
if ((int) $item['user_id'] === (int) $authUser['id']) {
    errorResponse('You cannot report your own item.', 422);
}

// Prevent duplicate reports
$stmt = $db->prepare(
    "SELECT id FROM reports WHERE item_id = :iid AND reported_by = :uid LIMIT 1"
);
$stmt->execute([':iid' => $itemId, ':uid' => $authUser['id']]);
if ($stmt->fetch()) {
    errorResponse('You have already reported this item.', 409);
}

$db->prepare(
    "INSERT INTO reports (item_id, reported_by, reason) VALUES (:iid, :uid, :reason)"
)->execute([':iid' => $itemId, ':uid' => $authUser['id'], ':reason' => $reason]);

successResponse('Thank you for your report. Our team will review it shortly.', null, 201);
