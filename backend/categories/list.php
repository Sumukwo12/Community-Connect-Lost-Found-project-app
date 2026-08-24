<?php
/**
 * GET /api/categories/list.php
 * Returns all active categories.
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    errorResponse('Method not allowed.', 405);
}

$db   = Database::getConnection();
$stmt = $db->query("SELECT id, name, icon, description FROM categories ORDER BY name ASC");
$cats = $stmt->fetchAll();

successResponse('Categories retrieved.', $cats);
