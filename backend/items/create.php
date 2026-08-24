<?php
/**
 * POST /api/items/create.php
 * Create a new lost or found item report.
 * Accepts multipart/form-data (for image upload).
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$authUser = requireAuth();
$db       = Database::getConnection();

// ─── Read POST fields (multipart/form-data) ───────────────────────────────────
$type        = sanitizeString($_POST['type']        ?? '', 10);
$title       = sanitizeString($_POST['title']       ?? '', 255);
$description = sanitizeString($_POST['description'] ?? '', 2000);
$categoryId  = (int) ($_POST['category_id']         ?? 0);
$location    = sanitizeString($_POST['location']     ?? '', 255);
$dateOccurred = sanitizeString($_POST['date_occurred'] ?? '', 20);
$timeOccurred = sanitizeString($_POST['time_occurred'] ?? '', 10);
$additional  = sanitizeString($_POST['additional_information'] ?? '', 1000);

// ─── Validation ──────────────────────────────────────────────────────────────
$errors = [];

if (!in_array($type, ['lost', 'found'], true)) {
    $errors[] = 'Type must be "lost" or "found".';
}
if (mb_strlen($title) < 3) {
    $errors[] = 'Item title must be at least 3 characters.';
}
if (mb_strlen($description) < 10) {
    $errors[] = 'Description must be at least 10 characters.';
}
if (empty($location)) {
    $errors[] = 'Location is required.';
}

$dateObj = DateTime::createFromFormat('Y-m-d', $dateOccurred);
if (!$dateObj || $dateObj->format('Y-m-d') !== $dateOccurred) {
    $errors[] = 'Date must be in YYYY-MM-DD format.';
} elseif ($dateObj > new DateTime()) {
    $errors[] = 'Date cannot be in the future.';
}

if (!empty($timeOccurred) && !preg_match('/^\d{2}:\d{2}(:\d{2})?$/', $timeOccurred)) {
    $errors[] = 'Time must be in HH:MM format.';
}

if ($categoryId > 0) {
    $stmt = $db->prepare("SELECT id FROM categories WHERE id = :id");
    $stmt->execute([':id' => $categoryId]);
    if (!$stmt->fetch()) {
        $errors[] = 'Invalid category.';
        $categoryId = null;
    }
} else {
    $categoryId = null;
}

if (!empty($errors)) {
    jsonResponse(false, 'Validation failed.', ['errors' => $errors], 422);
}

// ─── Handle image upload ──────────────────────────────────────────────────────
$imagePath = null;
if (!empty($_FILES['image']['tmp_name'])) {
    $result = uploadItemImage('image');
    if (!$result['success']) {
        errorResponse($result['message'], 422);
    }
    $imagePath = $result['path'];
}

// ─── Insert item ──────────────────────────────────────────────────────────────
$stmt = $db->prepare(
    "INSERT INTO items
        (user_id, category_id, type, title, description, location,
         date_occurred, time_occurred, image, additional_information)
     VALUES
        (:uid, :cat, :type, :title, :desc, :loc, :date, :time, :img, :add)"
);
$stmt->execute([
    ':uid'   => $authUser['id'],
    ':cat'   => $categoryId,
    ':type'  => $type,
    ':title' => $title,
    ':desc'  => $description,
    ':loc'   => $location,
    ':date'  => $dateOccurred,
    ':time'  => $timeOccurred ?: null,
    ':img'   => $imagePath,
    ':add'   => $additional ?: null,
]);
$itemId = (int) $db->lastInsertId();

// Fetch the created item
$stmt = $db->prepare(
    "SELECT i.*, c.name AS category_name, u.full_name AS poster_name
     FROM   items i
     LEFT JOIN categories c ON c.id = i.category_id
     LEFT JOIN users       u ON u.id = i.user_id
     WHERE  i.id = :id"
);
$stmt->execute([':id' => $itemId]);
$item = $stmt->fetch();

successResponse('Item reported successfully.', formatItem($item), 201);

// ─── Helpers ──────────────────────────────────────────────────────────────────
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
    if (!is_dir($absDir)) {
        mkdir($absDir, 0755, true);
    }
    $filename = bin2hex(random_bytes(16)) . '.' . $ext;
    if (!move_uploaded_file($file['tmp_name'], $absDir . $filename)) {
        return ['success' => false, 'message' => 'Could not save uploaded image.'];
    }
    return ['success' => true, 'path' => 'uploads/items/' . $filename];
}

function formatItem(array $item): array {
    if (!empty($item['image'])) {
        $item['image_url'] = UPLOAD_URL . basename($item['image']);
    } else {
        $item['image_url'] = null;
    }
    return $item;
}
