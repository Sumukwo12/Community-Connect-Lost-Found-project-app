<?php
/**
 * POST /api/auth/logout.php
 * Revoke the current auth token.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed.', 405);
}

$authHeader = $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? '';

if (!empty($authHeader) && str_starts_with($authHeader, 'Bearer ')) {
    $token = trim(substr($authHeader, 7));
    revokeToken($token);
}

successResponse('You have been logged out successfully.');
