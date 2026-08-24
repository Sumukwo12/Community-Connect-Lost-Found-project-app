<?php
/**
 * Community Connect - Global Configuration & Response Helpers
 */
require_once __DIR__ . '/../env.php';

// ─── CORS ────────────────────────────────────────────────────────────────────
function setCorsHeaders(): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $allowed = ALLOWED_ORIGINS;

    if ($allowed === '*') {
        header('Access-Control-Allow-Origin: *');
    } elseif (in_array($origin, explode(',', $allowed), true)) {
        header("Access-Control-Allow-Origin: $origin");
        header('Vary: Origin');
    }

    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Max-Age: 86400');
}

// ─── Security Headers ────────────────────────────────────────────────────────
function setSecurityHeaders(): void {
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('X-XSS-Protection: 1; mode=block');
    header('Referrer-Policy: strict-origin-when-cross-origin');
    if (APP_ENV === 'production') {
        header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
    }
}

// ─── Response Helpers ────────────────────────────────────────────────────────
function jsonResponse(bool $success, string $message, mixed $data = null, int $statusCode = 200): void {
    http_response_code($statusCode);
    $response = ['success' => $success, 'message' => $message];
    if ($data !== null) {
        $response['data'] = $data;
    }
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function successResponse(string $message, mixed $data = null, int $code = 200): void {
    jsonResponse(true, $message, $data, $code);
}

function errorResponse(string $message, int $code = 400): void {
    jsonResponse(false, $message, null, $code);
}

// ─── Request Helpers ─────────────────────────────────────────────────────────
function getRequestBody(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    if (is_array($data)) {
        return $data;
    }
    return !empty($_POST) ? $_POST : [];
}

function sanitizeString(string $value, int $maxLen = 500): string {
    return mb_substr(trim(strip_tags($value)), 0, $maxLen);
}

function isValidEmail(string $email): bool {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function isValidPhone(string $phone): bool {
    return preg_match('/^\+?[0-9\s\-]{7,20}$/', $phone) === 1;
}

// ─── Boot ────────────────────────────────────────────────────────────────────
header('Content-Type: application/json; charset=utf-8');
setCorsHeaders();
setSecurityHeaders();

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
