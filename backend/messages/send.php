<?php
/**
 * POST /api/messages/send.php
 * Send a message to an item poster.
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

$receiverId = (int) ($body['receiver_id'] ?? 0);
$itemId     = (int) ($body['item_id']     ?? 0);
$message    = sanitizeString($body['message'] ?? '', 2000);

$errors = [];
if ($receiverId <= 0)      $errors[] = 'Receiver is required.';
if (mb_strlen($message) < 1) $errors[] = 'Message cannot be empty.';
if (mb_strlen($message) > 2000) $errors[] = 'Message is too long (max 2000 characters).';
if ($receiverId === (int) $authUser['id']) $errors[] = 'You cannot message yourself.';

if (!empty($errors)) {
    jsonResponse(false, 'Validation failed.', ['errors' => $errors], 422);
}

// Verify receiver exists
$stmt = $db->prepare("SELECT id FROM users WHERE id = :id AND status = 'active' LIMIT 1");
$stmt->execute([':id' => $receiverId]);
if (!$stmt->fetch()) {
    errorResponse('Recipient not found.', 404);
}

// Verify item exists (if provided)
if ($itemId > 0) {
    $stmt = $db->prepare("SELECT id FROM items WHERE id = :id AND status != 'deleted' LIMIT 1");
    $stmt->execute([':id' => $itemId]);
    if (!$stmt->fetch()) {
        $itemId = null;
    }
} else {
    $itemId = null;
}

$stmt = $db->prepare(
    "INSERT INTO messages (sender_id, receiver_id, item_id, message)
     VALUES (:sid, :rid, :iid, :msg)"
);
$stmt->execute([
    ':sid' => $authUser['id'],
    ':rid' => $receiverId,
    ':iid' => $itemId,
    ':msg' => $message,
]);
$msgId = (int) $db->lastInsertId();

$stmt = $db->prepare(
    "SELECT m.*, u.full_name AS sender_name
     FROM messages m JOIN users u ON u.id = m.sender_id
     WHERE m.id = :id"
);
$stmt->execute([':id' => $msgId]);
$msg = $stmt->fetch();

successResponse('Message sent.', $msg, 201);
