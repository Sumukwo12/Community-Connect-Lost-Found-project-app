<?php
/**
 * Community Connect - Authentication Middleware
 *
 * Call requireAuth() at the top of any protected endpoint.
 * Returns the authenticated user row or sends a 401 response.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

function requireAuth(): array {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION']
                ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
                ?? '';

    if (empty($authHeader) || !str_starts_with($authHeader, 'Bearer ')) {
        errorResponse('Authentication required. Please log in.', 401);
    }

    $token = trim(substr($authHeader, 7));

    if (empty($token) || strlen($token) < 32) {
        errorResponse('Invalid authentication token.', 401);
    }

    $db  = Database::getConnection();
    $sql = "SELECT u.id, u.full_name, u.email, u.phone, u.profile_image, u.status
            FROM   auth_tokens t
            JOIN   users u ON u.id = t.user_id
            WHERE  t.token      = :token
              AND  t.expires_at > NOW()
              AND  u.status     = 'active'
            LIMIT  1";

    $stmt = $db->prepare($sql);
    $stmt->execute([':token' => $token]);
    $user = $stmt->fetch();

    if (!$user) {
        errorResponse('Session expired or invalid. Please log in again.', 401);
    }

    return $user;
}

/**
 * Generate a secure random token.
 */
function generateToken(): string {
    return bin2hex(random_bytes(32));
}

/**
 * Store token in auth_tokens and return it.
 */
function createAuthToken(int $userId): string {
    $db      = Database::getConnection();
    $token   = generateToken();
    $expires = date('Y-m-d H:i:s', strtotime('+' . TOKEN_LIFETIME_DAYS . ' days'));

    // Remove expired tokens for this user first (housekeeping)
    $db->prepare("DELETE FROM auth_tokens WHERE user_id = :uid AND expires_at < NOW()")
       ->execute([':uid' => $userId]);

    $stmt = $db->prepare(
        "INSERT INTO auth_tokens (user_id, token, expires_at) VALUES (:uid, :token, :exp)"
    );
    $stmt->execute([':uid' => $userId, ':token' => $token, ':exp' => $expires]);

    return $token;
}

/**
 * Revoke a specific token.
 */
function revokeToken(string $token): void {
    $db = Database::getConnection();
    $db->prepare("DELETE FROM auth_tokens WHERE token = :token")
       ->execute([':token' => $token]);
}
