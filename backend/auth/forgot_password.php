<?php
/**
 * POST /api/auth/forgot_password.php
 * Initiates password reset by generating a reset token.
 * In production, send the token via email. For now, returns it in the response
 * so you can wire up any email provider (PHPMailer, SendGrid, etc.)
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$body  = getRequestBody();
$email = sanitizeString($body['email'] ?? '', 200);

if (!isValidEmail($email)) {
    errorResponse('Please provide a valid email address.', 422);
}

$db   = Database::getConnection();
$stmt = $db->prepare("SELECT id, full_name FROM users WHERE email = :email AND status = 'active' LIMIT 1");
$stmt->execute([':email' => $email]);
$user = $stmt->fetch();

// Always return success to prevent email enumeration
if (!$user) {
    successResponse('If an account with that email exists, a reset link has been sent.');
}

$token   = bin2hex(random_bytes(32));
$expires = date('Y-m-d H:i:s', strtotime('+1 hour'));

$db->prepare("UPDATE users SET reset_token = :token, reset_expires = :exp WHERE id = :id")
   ->execute([':token' => $token, ':exp' => $expires, ':id' => $user['id']]);

// TODO: Integrate with your email provider (PHPMailer, SendGrid, Mailgun, etc.)
// $resetLink = APP_URL . '/reset-password?token=' . $token;
// sendEmail($email, 'Password Reset', "Click here to reset: $resetLink");

// For development: return token directly (REMOVE in production)
$responseData = APP_ENV === 'development'
    ? ['reset_token' => $token, 'expires_at' => $expires]
    : null;

successResponse('If an account with that email exists, a reset link has been sent.', $responseData);
