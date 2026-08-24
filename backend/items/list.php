<?php
/**
 * GET /api/items/list.php
 * List items with search, filters, and pagination.
 *
 * Query params:
 *   type        – lost | found
 *   category_id – integer
 *   location    – string (partial match)
 *   search      – string (full-text on title/description/location)
 *   status      – active | resolved (default: active)
 *   my_items    – 1 to return only authenticated user's items
 *   date_from   – YYYY-MM-DD
 *   date_to     – YYYY-MM-DD
 *   page        – integer (default: 1)
 *   per_page    – integer (default: 15, max: 50)
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    errorResponse('Method not allowed.', 405);
}

// Optional auth (public browsing allowed, my_items requires auth)
$authUser = null;
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
if (!empty($authHeader) && str_starts_with($authHeader, 'Bearer ')) {
    try { $authUser = requireAuth(); } catch (\Throwable) {}
}

$myItems    = (int) ($_GET['my_items']    ?? 0) === 1;
if ($myItems && !$authUser) {
    errorResponse('Authentication required to view your items.', 401);
}

$type       = $_GET['type']        ?? '';
$catId      = (int) ($_GET['category_id'] ?? 0);
$location   = sanitizeString($_GET['location'] ?? '', 255);
$search     = sanitizeString($_GET['search']   ?? '', 255);
$status     = in_array($_GET['status'] ?? 'active', ['active', 'resolved'], true)
              ? ($_GET['status'] ?? 'active') : 'active';
$dateFrom   = $_GET['date_from'] ?? '';
$dateTo     = $_GET['date_to']   ?? '';
$page       = max(1, (int) ($_GET['page']     ?? 1));
$perPage    = min(50, max(1, (int) ($_GET['per_page'] ?? 15)));
$offset     = ($page - 1) * $perPage;

$db     = Database::getConnection();
$where  = ['i.status = :status'];
$params = [':status' => $status];

if ($myItems) {
    $where[]          = 'i.user_id = :uid';
    $params[':uid']   = $authUser['id'];
}
if (in_array($type, ['lost', 'found'], true)) {
    $where[]           = 'i.type = :type';
    $params[':type']   = $type;
}
if ($catId > 0) {
    $where[]           = 'i.category_id = :cat';
    $params[':cat']    = $catId;
}
if (!empty($location)) {
    $where[]           = 'i.location LIKE :loc';
    $params[':loc']    = '%' . $location . '%';
}
if (!empty($search)) {
    $where[]           = 'MATCH(i.title, i.description, i.location) AGAINST(:search IN BOOLEAN MODE)';
    $params[':search'] = $search . '*';
}
if (!empty($dateFrom)) {
    $where[]              = 'i.date_occurred >= :df';
    $params[':df']        = $dateFrom;
}
if (!empty($dateTo)) {
    $where[]              = 'i.date_occurred <= :dt';
    $params[':dt']        = $dateTo;
}

$whereClause = 'WHERE ' . implode(' AND ', $where);

// Count total
$countSql  = "SELECT COUNT(*) FROM items i $whereClause";
$countStmt = $db->prepare($countSql);
$countStmt->execute($params);
$total = (int) $countStmt->fetchColumn();

// Fetch items
$sql = "SELECT i.id, i.type, i.title, i.description, i.location, i.date_occurred,
               i.time_occurred, i.image, i.status, i.created_at,
               c.name AS category_name,
               u.full_name AS poster_name
        FROM   items i
        LEFT JOIN categories c ON c.id = i.category_id
        LEFT JOIN users       u ON u.id = i.user_id
        $whereClause
        ORDER  BY i.created_at DESC
        LIMIT  :limit OFFSET :offset";

$params[':limit']  = $perPage;
$params[':offset'] = $offset;

$stmt = $db->prepare($sql);
// PDO requires integer binding for LIMIT/OFFSET
foreach ($params as $key => $val) {
    $type_ = is_int($val) ? PDO::PARAM_INT : PDO::PARAM_STR;
    $stmt->bindValue($key, $val, $type_);
}
$stmt->execute();
$items = $stmt->fetchAll();

// Append image URLs
$items = array_map(function ($item) {
    $item['image_url'] = !empty($item['image'])
        ? UPLOAD_URL . basename($item['image'])
        : null;
    return $item;
}, $items);

successResponse('Items retrieved.', [
    'items'       => $items,
    'pagination'  => [
        'total'       => $total,
        'page'        => $page,
        'per_page'    => $perPage,
        'total_pages' => (int) ceil($total / $perPage),
    ],
]);
