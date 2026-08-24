<?php
/**
 * GET /api/messages/list.php
 * List conversations for the authenticated user.
 *
 * Query params:
 *   conversation_with – user_id to load a specific conversation
 *   item_id           – filter by item
 *   page              – pagination
 *   per_page          – results per page (default 30)
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    errorResponse('Method not allowed.', 405);
}

$authUser = requireAuth();
$db       = Database::getConnection();

$withUser = (int) ($_GET['conversation_with'] ?? 0);
$itemId   = (int) ($_GET['item_id']           ?? 0);
$page     = max(1, (int) ($_GET['page']     ?? 1));
$perPage  = min(100, max(1, (int) ($_GET['per_page'] ?? 30)));
$offset   = ($page - 1) * $perPage;

if ($withUser > 0) {
    // Load specific conversation
    $params  = [':me' => $authUser['id'], ':other' => $withUser];
    $where   = "(m.sender_id = :me AND m.receiver_id = :other)
             OR (m.sender_id = :other2 AND m.receiver_id = :me2)";
    $params[':other2'] = $withUser;
    $params[':me2']    = $authUser['id'];

    if ($itemId > 0) {
        $where           .= ' AND m.item_id = :iid';
        $params[':iid']   = $itemId;
    }

    $sql = "SELECT m.*, s.full_name AS sender_name, r.full_name AS receiver_name
            FROM   messages m
            JOIN   users s ON s.id = m.sender_id
            JOIN   users r ON r.id = m.receiver_id
            WHERE  $where
            ORDER  BY m.created_at ASC
            LIMIT  :limit OFFSET :offset";

    $params[':limit']  = $perPage;
    $params[':offset'] = $offset;

    $stmt = $db->prepare($sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v, is_int($v) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->execute();
    $messages = $stmt->fetchAll();

    // Mark messages as read
    $db->prepare(
        "UPDATE messages SET is_read = 1
         WHERE sender_id = :other AND receiver_id = :me AND is_read = 0"
    )->execute([':other' => $withUser, ':me' => $authUser['id']]);

    successResponse('Conversation retrieved.', ['messages' => $messages]);

} else {
    // List all unique conversations
    $sql = "SELECT
                CASE WHEN m.sender_id = :me THEN m.receiver_id ELSE m.sender_id END AS other_user_id,
                CASE WHEN m.sender_id = :me2 THEN r.full_name ELSE s.full_name END AS other_user_name,
                MAX(m.created_at) AS last_message_at,
                (SELECT msg2.message FROM messages msg2
                 WHERE (msg2.sender_id = :me3 AND msg2.receiver_id = other_user_id)
                    OR (msg2.sender_id = other_user_id AND msg2.receiver_id = :me4)
                 ORDER BY msg2.created_at DESC LIMIT 1) AS last_message,
                SUM(CASE WHEN m.receiver_id = :me5 AND m.is_read = 0 THEN 1 ELSE 0 END) AS unread_count
            FROM messages m
            JOIN users s ON s.id = m.sender_id
            JOIN users r ON r.id = m.receiver_id
            WHERE m.sender_id = :me6 OR m.receiver_id = :me7
            GROUP BY other_user_id, other_user_name
            ORDER BY last_message_at DESC
            LIMIT :limit OFFSET :offset";

    $uid = (int) $authUser['id'];
    $stmt = $db->prepare($sql);
    $stmt->bindValue(':me',     $uid, PDO::PARAM_INT);
    $stmt->bindValue(':me2',    $uid, PDO::PARAM_INT);
    $stmt->bindValue(':me3',    $uid, PDO::PARAM_INT);
    $stmt->bindValue(':me4',    $uid, PDO::PARAM_INT);
    $stmt->bindValue(':me5',    $uid, PDO::PARAM_INT);
    $stmt->bindValue(':me6',    $uid, PDO::PARAM_INT);
    $stmt->bindValue(':me7',    $uid, PDO::PARAM_INT);
    $stmt->bindValue(':limit',  $perPage, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset,  PDO::PARAM_INT);
    $stmt->execute();
    $conversations = $stmt->fetchAll();

    successResponse('Conversations retrieved.', ['conversations' => $conversations]);
}
