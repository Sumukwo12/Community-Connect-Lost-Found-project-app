<?php
/**
 * POST /api/auth/login.php
 * Authenticate a user and return a token.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$body     = getRequestBody();
$email    = sanitizeString($body['email']    ?? '', 200);
$password = $body['password'] ?? '';

if (empty($email) || empty($password)) {
    errorResponse('Email and password are required.', 422);
}

if (!isValidEmail($email)) {
    errorResponse('Invalid email address.', 422);
}

$db   = Database::getConnection();
$stmt = $db->prepare(
    "SELECT id, full_name, email, phone, profile_image, password, status
     FROM   users
     WHERE  email = :email
     LIMIT  1"
);
$stmt->execute([':email' => $email]);
$user = $stmt->fetch();

// Use constant-time comparison to prevent timing attacks
if (!$user || !password_verify($password, $user['password'])) {
    errorResponse('Invalid email or password.', 401);
}

if ($user['status'] !== 'active') {
    errorResponse('Your account has been suspended. Please contact support.', 403);
}

$token = createAuthToken((int) $user['id']);

// Rehash if needed (e.g., after cost factor change)
if (password_needs_rehash($user['password'], PASSWORD_BCRYPT, ['cost' => 12])) {
    $newHash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    $db->prepare("UPDATE users SET password = :pwd WHERE id = :id")
       ->execute([':pwd' => $newHash, ':id' => $user['id']]);
}

successResponse('Login successful.', [
    'token' => $token,
    'user'  => [
        'id'            => (int) $user['id'],
        'full_name'     => $user['full_name'],
        'email'         => $user['email'],
        'phone'         => $user['phone'],
        'profile_image' => $user['profile_image'],
    ],
]);
