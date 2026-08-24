<?php
/**
 * POST /api/items/update.php
 * Update an existing item. Owner-only.
 * Accepts multipart/form-data (for optional image replacement).
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$authUser = requireAuth();
$db       = Database::getConnection();

$itemId = (int) ($_POST['id'] ?? 0);
if ($itemId <= 0) {
    errorResponse('Item ID is required.', 422);
}

// Fetch item and verify ownership
$stmt = $db->prepare("SELECT * FROM items WHERE id = :id AND status != 'deleted' LIMIT 1");
$stmt->execute([':id' => $itemId]);
$item = $stmt->fetch();

if (!$item) {
    errorResponse('Item not found.', 404);
}
if ((int) $item['user_id'] !== (int) $authUser['id']) {
    errorResponse('You are not authorized to edit this item.', 403);
}

// ─── Fields ───────────────────────────────────────────────────────────────────
$type        = sanitizeString($_POST['type']        ?? $item['type'], 10);
$title       = sanitizeString($_POST['title']       ?? $item['title'], 255);
$description = sanitizeString($_POST['description'] ?? $item['description'], 2000);
$categoryId  = isset($_POST['category_id']) ? (int) $_POST['category_id'] : $item['category_id'];
$location    = sanitizeString($_POST['location']     ?? $item['location'], 255);
$dateOccurred = sanitizeString($_POST['date_occurred'] ?? $item['date_occurred'], 20);
$timeOccurred = sanitizeString($_POST['time_occurred'] ?? $item['time_occurred'], 10);
$additional  = sanitizeString($_POST['additional_information'] ?? $item['additional_information'], 1000);

// ─── Validation ──────────────────────────────────────────────────────────────
$errors = [];
if (!in_array($type, ['lost', 'found'], true)) {
    $errors[] = 'Type must be "lost" or "found".';
}
if (mb_strlen($title) < 3) {
    $errors[] = 'Title must be at least 3 characters.';
}
if (mb_strlen($description) < 10) {
    $errors[] = 'Description must be at least 10 characters.';
}
if (empty($location)) {
    $errors[] = 'Location is required.';
}
if (!empty($errors)) {
    jsonResponse(false, 'Validation failed.', ['errors' => $errors], 422);
}

// ─── Optional image upload ─────────────────────────────────────────────────────
$imagePath = $item['image'];
if (!empty($_FILES['image']['tmp_name'])) {
    $result = uploadItemImage('image');
    if (!$result['success']) {
        errorResponse($result['message'], 422);
    }
    // Delete old image if it exists
    if (!empty($item['image'])) {
        $oldPath = __DIR__ . '/../' . $item['image'];
        if (file_exists($oldPath)) @unlink($oldPath);
    }
    $imagePath = $result['path'];
}

// ─── Update ───────────────────────────────────────────────────────────────────
$db->prepare(
    "UPDATE items SET
        type = :type, title = :title, description = :desc,
        category_id = :cat, location = :loc, date_occurred = :date,
        time_occurred = :time, image = :img, additional_information = :add
     WHERE id = :id"
)->execute([
    ':type'  => $type,
    ':title' => $title,
    ':desc'  => $description,
    ':cat'   => $categoryId,
    ':loc'   => $location,
    ':date'  => $dateOccurred,
    ':time'  => $timeOccurred ?: null,
    ':img'   => $imagePath,
    ':add'   => $additional ?: null,
    ':id'    => $itemId,
]);

$stmt = $db->prepare(
    "SELECT i.*, c.name AS category_name, u.full_name AS poster_name
     FROM items i LEFT JOIN categories c ON c.id = i.category_id
     LEFT JOIN users u ON u.id = i.user_id WHERE i.id = :id"
);
$stmt->execute([':id' => $itemId]);
$updated = $stmt->fetch();
$updated['image_url'] = !empty($updated['image'])
    ? UPLOAD_URL . basename($updated['image']) : null;

successResponse('Item updated successfully.', $updated);

function uploadItemImage(string $fieldName): array {
    $file   = $_FILES[$fieldName] ?? null;
    $absDir = __DIR__ . '/../uploads/items/';
    if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'message' => 'File upload error.'];
    }
    if ($file['size'] > MAX_FILE_SIZE) {
        return ['success' => false, 'message' => 'Image must be smaller than 5 MB.'];
    }
    $finfo    = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    if (!in_array($mimeType, ALLOWED_MIME, true)) {
        return ['success' => false, 'message' => 'Only JPEG, PNG, and WebP images are allowed.'];
    }
    $ext = match ($mimeType) {
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
    };
    if (!is_dir($absDir)) mkdir($absDir, 0755, true);
    $filename = bin2hex(random_bytes(16)) . '.' . $ext;
    if (!move_uploaded_file($file['tmp_name'], $absDir . $filename)) {
        return ['success' => false, 'message' => 'Could not save uploaded image.'];
    }
    return ['success' => true, 'path' => 'uploads/items/' . $filename];
}
