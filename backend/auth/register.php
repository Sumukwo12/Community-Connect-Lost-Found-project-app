<?php
/**
 * POST /api/auth/register.php
 * Register a new user account.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$body = getRequestBody();

// ─── Validation ──────────────────────────────────────────────────────────────
$fullName   = sanitizeString($body['full_name']   ?? '', 150);
$email      = sanitizeString($body['email']       ?? '', 200);
$phone      = sanitizeString($body['phone']       ?? '', 30);
$password   = $body['password']         ?? '';
$confirmPwd = $body['confirm_password'] ?? '';

$errors = [];

if (empty($fullName) || mb_strlen($fullName) < 2) {
    $errors[] = 'Full name must be at least 2 characters.';
}
if (!isValidEmail($email)) {
    $errors[] = 'Please provide a valid email address.';
}
if (!isValidPhone($phone)) {
    $errors[] = 'Please provide a valid phone number.';
}
if (strlen($password) < 8) {
    $errors[] = 'Password must be at least 8 characters.';
}
if ($password !== $confirmPwd) {
    $errors[] = 'Passwords do not match.';
}

if (!empty($errors)) {
    jsonResponse(false, 'Validation failed.', ['errors' => $errors], 422);
}

// ─── Check duplicate email ────────────────────────────────────────────────────
$db   = Database::getConnection();
$stmt = $db->prepare("SELECT id FROM users WHERE email = :email LIMIT 1");
$stmt->execute([':email' => $email]);

if ($stmt->fetch()) {
    errorResponse('An account with this email already exists.', 409);
}

// ─── Insert user ──────────────────────────────────────────────────────────────
$hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
$stmt = $db->prepare(
    "INSERT INTO users (full_name, email, phone, password) VALUES (:name, :email, :phone, :pwd)"
);
$stmt->execute([
    ':name'  => $fullName,
    ':email' => $email,
    ':phone' => $phone,
    ':pwd'   => $hash,
]);
$userId = (int) $db->lastInsertId();

// ─── Create auth token ────────────────────────────────────────────────────────
$token = createAuthToken($userId);

successResponse('Registration successful. Welcome to Community Connect!', [
    'token' => $token,
    'user'  => [
        'id'        => $userId,
        'full_name' => $fullName,
        'email'     => $email,
        'phone'     => $phone,
    ],
], 201);
