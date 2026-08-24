<?php
/**
 * GET  /api/auth/profile.php  – Get current user profile
 * POST /api/auth/profile.php  – Update profile (name, phone, profile_image)
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

$method = $_SERVER['REQUEST_METHOD'];
if (!in_array($method, ['GET', 'POST'])) {
    errorResponse('Method not allowed.', 405);
}

$authUser = requireAuth();
$db       = Database::getConnection();

// ─── GET: Return profile ──────────────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $db->prepare(
        "SELECT id, full_name, email, phone, profile_image, created_at
         FROM   users WHERE id = :id"
    );
    $stmt->execute([':id' => $authUser['id']]);
    $user = $stmt->fetch();

    successResponse('Profile retrieved.', $user);
}

// ─── POST: Update profile ─────────────────────────────────────────────────────
$body     = getRequestBody();
$fullName = sanitizeString($body['full_name'] ?? $authUser['full_name'], 150);
$phone    = sanitizeString($body['phone']     ?? '', 30);

$errors = [];
if (mb_strlen($fullName) < 2) {
    $errors[] = 'Full name must be at least 2 characters.';
}
if (!empty($phone) && !isValidPhone($phone)) {
    $errors[] = 'Invalid phone number format.';
}
if (!empty($errors)) {
    jsonResponse(false, 'Validation failed.', ['errors' => $errors], 422);
}

// ─── Handle change password ───────────────────────────────────────────────────
$newPassword     = $body['new_password']     ?? '';
$currentPassword = $body['current_password'] ?? '';

if (!empty($newPassword)) {
    if (strlen($newPassword) < 8) {
        errorResponse('New password must be at least 8 characters.', 422);
    }
    // Verify current password
    $stmt = $db->prepare("SELECT password FROM users WHERE id = :id");
    $stmt->execute([':id' => $authUser['id']]);
    $row = $stmt->fetch();

    if (!$row || !password_verify($currentPassword, $row['password'])) {
        errorResponse('Current password is incorrect.', 401);
    }
    $newHash = password_hash($newPassword, PASSWORD_BCRYPT, ['cost' => 12]);
    $db->prepare("UPDATE users SET password = :pwd WHERE id = :id")
       ->execute([':pwd' => $newHash, ':id' => $authUser['id']]);
}

// ─── Handle profile image upload ──────────────────────────────────────────────
$profileImage = null;
if (!empty($_FILES['profile_image']['tmp_name'])) {
    $uploadResult = handleImageUpload('profile_image', 'uploads/profiles/');
    if (!$uploadResult['success']) {
        errorResponse($uploadResult['message'], 422);
    }
    $profileImage = $uploadResult['path'];
}

// ─── Update user ──────────────────────────────────────────────────────────────
$params = [
    ':name'  => $fullName,
    ':phone' => $phone ?: $authUser['phone'],
    ':id'    => $authUser['id'],
];
$imageClause = '';
if ($profileImage !== null) {
    $imageClause     = ', profile_image = :img';
    $params[':img']  = $profileImage;
}
$db->prepare("UPDATE users SET full_name = :name, phone = :phone{$imageClause} WHERE id = :id")
   ->execute($params);

$stmt = $db->prepare("SELECT id, full_name, email, phone, profile_image, created_at FROM users WHERE id = :id");
$stmt->execute([':id' => $authUser['id']]);
$updated = $stmt->fetch();

successResponse('Profile updated successfully.', $updated);

// ─── Image upload helper ──────────────────────────────────────────────────────
function handleImageUpload(string $fieldName, string $targetDir): array {
    $file    = $_FILES[$fieldName] ?? null;
    $absDir  = __DIR__ . '/../' . $targetDir;

    if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'message' => 'File upload error.'];
    }
    if ($file['size'] > MAX_FILE_SIZE) {
        return ['success' => false, 'message' => 'File size exceeds 5 MB limit.'];
    }
    $finfo    = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);

    if (!in_array($mimeType, ALLOWED_MIME, true)) {
        return ['success' => false, 'message' => 'Only JPEG, PNG, and WebP images are allowed.'];
    }
    $ext      = match ($mimeType) {
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
        default      => '',
    };
    if (!is_dir($absDir)) {
        mkdir($absDir, 0755, true);
    }
    $filename = bin2hex(random_bytes(16)) . '.' . $ext;
    $dest     = $absDir . $filename;

    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        return ['success' => false, 'message' => 'Failed to save uploaded file.'];
    }
    return ['success' => true, 'path' => $targetDir . $filename];
}
