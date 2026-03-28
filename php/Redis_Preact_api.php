<?php
/**
 * Redis_Preact_api.php — Универсальный Redis API для Preact/WebView2
 * 
 * GET  — чтение данных
 * POST — запись / удаление
 * 
 * Формат ответа: {success, action, key, data, time_ms, error?}
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

$timeStart = microtime(true);

// ── Защита: только localhost ──────────────────────────────────────────────────
$allowedIPs = ['127.0.0.1', '::1'];
$clientIP = $_SERVER['REMOTE_ADDR'] ?? '';
if (!in_array($clientIP, $allowedIPs)) {
    http_response_code(403);
    die(json_encode(['success' => false, 'error' => 'Forbidden']));
}

// ── Белый список action ───────────────────────────────────────────────────────
$allowedActions = [
    // SYSTEM
    'ping', 'info', 'bgsave', 'dump',
    // STRING
    'get', 'set', 'del',
    // HASH
    'hget', 'hgetall', 'hkeys', 'hset', 'hmset', 'hdel',
    // LIST
    'lrange', 'llen', 'rpush', 'lpush', 'ltrim',
    // KEYS
    'keys', 'exists', 'ttl', 'type', 'expire',
    // BATCH
    'mget', 'hmget',
    // COUNTERS
    'incr', 'incrby', 'decr', 'decrby',
    // SET
    'sadd', 'smembers', 'sismember', 'srem', 'scard',
    // SORTED SET
    'zadd', 'zrange', 'zrangebyscore', 'zcard', 'zrem', 'zscore', 'zrevrange',
];

// ── Параметры ─────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $body    = json_decode(file_get_contents('php://input'), true) ?? [];
    $action  = $body['action']  ?? '';
    $key     = $body['key']     ?? '';
    $field   = $body['field']   ?? '';
    $value   = $body['value']   ?? null;
    $data    = $body['data']    ?? [];
    $keys    = $body['keys']    ?? [];   // для mget
    $fields  = $body['fields']  ?? [];   // для hmget
    $members = $body['members'] ?? [];   // для sadd/srem
    $score   = isset($body['score'])  ? (float)$body['score']  : 0.0;
    $score2  = isset($body['score2']) ? (float)$body['score2'] : 0.0;
    $count   = isset($body['count'])  ? (int)$body['count']    : 100;
    $offset  = isset($body['offset']) ? (int)$body['offset']   : 0;
    $ttl     = isset($body['ttl'])    ? (int)$body['ttl']      : 0;
    $amount  = isset($body['amount']) ? (int)$body['amount']   : 1;
    $db      = isset($body['db'])     ? (int)$body['db']       : 0;
    $file    = $body['file']    ?? '';
} else {
    $action  = $_GET['action']  ?? '';
    $key     = $_GET['key']     ?? '';
    $field   = $_GET['field']   ?? '';
    $value   = $_GET['value']   ?? null;
    $keys    = isset($_GET['keys'])    ? explode(',', $_GET['keys'])    : [];
    $fields  = isset($_GET['fields'])  ? explode(',', $_GET['fields'])  : [];
    $members = isset($_GET['members']) ? explode(',', $_GET['members']) : [];
    $score   = isset($_GET['score'])   ? (float)$_GET['score']         : 0.0;
    $score2  = isset($_GET['score2'])  ? (float)$_GET['score2']        : 0.0;
    $count   = isset($_GET['count'])   ? (int)$_GET['count']           : 100;
    $offset  = isset($_GET['offset'])  ? (int)$_GET['offset']          : 0;
    $ttl     = isset($_GET['ttl'])     ? (int)$_GET['ttl']             : 0;
    $amount  = isset($_GET['amount'])  ? (int)$_GET['amount']          : 1;
    $db      = isset($_GET['db'])      ? (int)$_GET['db']              : 0;
    $file    = $_GET['file']    ?? '';
    $data    = [];
}

// ── Валидация action ──────────────────────────────────────────────────────────
if (!in_array($action, $allowedActions)) {
    respond(false, $action, $key, null, 'Unknown action: ' . $action);
}

// ── Лимиты ────────────────────────────────────────────────────────────────────
$count  = min(max($count, 1), 10000);
$offset = max($offset, 0);
$db     = min(max($db, 0), 15);

// ── Подключение к Redis ───────────────────────────────────────────────────────
try {
    $redis = new Redis();
    if (!$redis->connect('127.0.0.1', 6379, 2.0)) {
        respond(false, $action, $key, null, 'Redis connect failed');
    }
    $redis->select($db);
} catch (Exception $e) {
    respond(false, $action, $key, null, 'Redis error: ' . $e->getMessage());
}

// ── Выполнение action ─────────────────────────────────────────────────────────
try {
    $result = null;

    switch ($action) {

        // SYSTEM ───────────────────────────────────────────────────────────────
        case 'ping':
            $result = $redis->ping();
            break;

        case 'info':
            $raw = $redis->info();
            $result = [
                'redis_version'     => $raw['redis_version']     ?? '?',
                'used_memory_human' => $raw['used_memory_human']  ?? '?',
                'connected_clients' => $raw['connected_clients']  ?? '?',
                'uptime_in_seconds' => $raw['uptime_in_seconds']  ?? '?',
                'total_keys'        => $redis->dbSize(),
            ];
            break;

        case 'bgsave':
            // Команда Redis сохранить RDB снапшот в фоне
            $result = $redis->bgSave();
            break;

        case 'dump':
            // Экспорт ключей по паттерну в JSON файл на диске
            $pattern   = $key ?: '*';
            $dumpDir   = __DIR__ . '/redis_dumps/';
            if (!is_dir($dumpDir)) mkdir($dumpDir, 0755, true);

            $fname     = $file ?: ('dump_db' . $db . '_' . date('Y-m-d_H-i-s') . '.json');
            // Безопасность: только имя файла, без путей
            $fname     = basename($fname);
            if (!preg_match('/^[\w\-\.]+\.json$/', $fname)) {
                respond(false, $action, $key, null, 'Invalid file name');
            }
            $fullPath  = $dumpDir . $fname;

            $allKeys   = $redis->keys($pattern) ?: [];
            $export    = ['db' => $db, 'pattern' => $pattern, 'date' => date('c'), 'keys' => []];

            foreach ($allKeys as $k) {
                $type = $redis->type($k);
                $entry = ['type' => $type];
                switch ($type) {
                    case Redis::REDIS_STRING:
                        $entry['value'] = tryDecodeJson($redis->get($k));
                        break;
                    case Redis::REDIS_HASH:
                        $raw = $redis->hGetAll($k);
                        $entry['value'] = array_map('tryDecodeJson', $raw);
                        break;
                    case Redis::REDIS_LIST:
                        $entry['value'] = array_map('tryDecodeJson', $redis->lRange($k, 0, -1));
                        break;
                    case Redis::REDIS_SET:
                        $entry['value'] = array_values($redis->sMembers($k));
                        break;
                    case Redis::REDIS_ZSET:
                        $raw = $redis->zRange($k, 0, -1, true);
                        $entry['value'] = [];
                        foreach ($raw as $v => $s) {
                            $entry['value'][] = ['value' => tryDecodeJson($v), 'score' => $s];
                        }
                        break;
                }
                $ttlVal = $redis->ttl($k);
                if ($ttlVal > 0) $entry['ttl'] = $ttlVal;
                $export['keys'][$k] = $entry;
            }

            $written = file_put_contents($fullPath, json_encode($export, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
            $result  = [
                'file'      => $fname,
                'path'      => 'php/redis_dumps/' . $fname,
                'keys_count'=> count($allKeys),
                'bytes'     => $written,
            ];
            break;

        // STRING ───────────────────────────────────────────────────────────────
        case 'get':
            requireKey($key);
            $raw = $redis->get($key);
            $result = ($raw !== false) ? tryDecodeJson($raw) : null;
            break;

        case 'set':
            requireKey($key);
            $val = is_array($value) ? json_encode($value, JSON_UNESCAPED_UNICODE) : (string)$value;
            $result = $ttl > 0 ? $redis->setex($key, $ttl, $val) : $redis->set($key, $val);
            break;

        case 'del':
            requireKey($key);
            $result = $redis->del($key);
            break;

        // HASH ─────────────────────────────────────────────────────────────────
        case 'hget':
            requireKey($key);
            requireField($field);
            $raw = $redis->hGet($key, $field);
            $result = ($raw !== false) ? tryDecodeJson($raw) : null;
            break;

        case 'hgetall':
            requireKey($key);
            $raw = $redis->hGetAll($key);
            $result = [];
            foreach ($raw as $f => $v) {
                $result[$f] = tryDecodeJson($v);
            }
            break;

        case 'hkeys':
            requireKey($key);
            $result = $redis->hKeys($key);
            break;

        case 'hset':
            requireKey($key);
            requireField($field);
            $val = is_array($value) ? json_encode($value, JSON_UNESCAPED_UNICODE) : (string)$value;
            $result = $redis->hSet($key, $field, $val);
            break;

        case 'hmset':
            requireKey($key);
            if (empty($data) || !is_array($data)) {
                respond(false, $action, $key, null, 'data required for hmset');
            }
            $encoded = [];
            foreach ($data as $f => $v) {
                $encoded[$f] = is_array($v) ? json_encode($v, JSON_UNESCAPED_UNICODE) : (string)$v;
            }
            $result = $redis->hMSet($key, $encoded);
            break;

        case 'hdel':
            requireKey($key);
            requireField($field);
            $result = $redis->hDel($key, $field);
            break;

        // LIST ─────────────────────────────────────────────────────────────────
        case 'lrange':
            requireKey($key);
            $start = $offset;
            $end   = ($count === 0) ? -1 : ($offset + $count - 1);
            $raw   = $redis->lRange($key, $start, $end);
            $result = array_map('tryDecodeJson', $raw ?: []);
            break;

        case 'llen':
            requireKey($key);
            $result = $redis->lLen($key);
            break;

        case 'rpush':
            requireKey($key);
            $val = is_array($value) ? json_encode($value, JSON_UNESCAPED_UNICODE) : (string)$value;
            $result = $redis->rPush($key, $val);
            break;

        case 'lpush':
            requireKey($key);
            $val = is_array($value) ? json_encode($value, JSON_UNESCAPED_UNICODE) : (string)$value;
            $result = $redis->lPush($key, $val);
            break;

        case 'ltrim':
            requireKey($key);
            // ltrim key offset count → оставить последние count элементов
            $result = $redis->lTrim($key, $offset, $offset + $count - 1);
            break;

        // BATCH ────────────────────────────────────────────────────────────────
        case 'mget':
            if (empty($keys)) respond(false, $action, '', null, 'keys[] required for mget');
            $keys = array_slice($keys, 0, 100);
            $raw = $redis->mGet($keys);
            $result = [];
            foreach ($keys as $i => $k) {
                $result[$k] = ($raw[$i] !== false) ? tryDecodeJson($raw[$i]) : null;
            }
            break;

        case 'hmget':
            requireKey($key);
            if (empty($fields)) respond(false, $action, $key, null, 'fields[] required for hmget');
            $raw = $redis->hMGet($key, $fields);
            $result = [];
            foreach ($fields as $f) {
                $result[$f] = ($raw[$f] !== false) ? tryDecodeJson($raw[$f]) : null;
            }
            break;

        // COUNTERS ─────────────────────────────────────────────────────────────
        case 'incr':
            requireKey($key);
            $result = $redis->incr($key);
            break;

        case 'incrby':
            requireKey($key);
            $result = $redis->incrBy($key, $amount);
            break;

        case 'decr':
            requireKey($key);
            $result = $redis->decr($key);
            break;

        case 'decrby':
            requireKey($key);
            $result = $redis->decrBy($key, $amount);
            break;

        // SET ──────────────────────────────────────────────────────────────────
        case 'sadd':
            requireKey($key);
            if (empty($members)) respond(false, $action, $key, null, 'members[] required for sadd');
            $result = $redis->sAdd($key, ...$members);
            break;

        case 'smembers':
            requireKey($key);
            $result = array_values($redis->sMembers($key) ?: []);
            break;

        case 'sismember':
            requireKey($key);
            if ($value === null) respond(false, $action, $key, null, 'value required for sismember');
            $result = (bool)$redis->sIsMember($key, (string)$value);
            break;

        case 'srem':
            requireKey($key);
            if (empty($members)) respond(false, $action, $key, null, 'members[] required for srem');
            $result = $redis->sRem($key, ...$members);
            break;

        case 'scard':
            requireKey($key);
            $result = $redis->sCard($key);
            break;

        // SORTED SET ───────────────────────────────────────────────────────────
        case 'zadd':
            requireKey($key);
            if ($value === null) respond(false, $action, $key, null, 'value required for zadd');
            $val = is_array($value) ? json_encode($value, JSON_UNESCAPED_UNICODE) : (string)$value;
            $result = $redis->zAdd($key, $score, $val);
            break;

        case 'zrange':
            requireKey($key);
            $raw = $redis->zRange($key, $offset, $offset + $count - 1, true);
            $result = [];
            foreach ($raw as $v => $s) {
                $result[] = ['value' => tryDecodeJson($v), 'score' => $s];
            }
            break;

        case 'zrevrange':
            requireKey($key);
            $raw = $redis->zRevRange($key, $offset, $offset + $count - 1, true);
            $result = [];
            foreach ($raw as $v => $s) {
                $result[] = ['value' => tryDecodeJson($v), 'score' => $s];
            }
            break;

        case 'zrangebyscore':
            requireKey($key);
            // score=min, score2=max; используй -inf/+inf через score=-INF score2=INF
            $min = ($score  <= -PHP_INT_MAX) ? '-inf' : $score;
            $max = ($score2 >= PHP_INT_MAX)  ? '+inf' : $score2;
            $opts = ['withscores' => true, 'limit' => [$offset, $count]];
            $raw = $redis->zRangeByScore($key, $min, $max, $opts);
            $result = [];
            foreach ($raw as $v => $s) {
                $result[] = ['value' => tryDecodeJson($v), 'score' => $s];
            }
            break;

        case 'zcard':
            requireKey($key);
            $result = $redis->zCard($key);
            break;

        case 'zrem':
            requireKey($key);
            if ($value === null) respond(false, $action, $key, null, 'value required for zrem');
            $result = $redis->zRem($key, (string)$value);
            break;

        case 'zscore':
            requireKey($key);
            if ($value === null) respond(false, $action, $key, null, 'value required for zscore');
            $result = $redis->zScore($key, (string)$value);
            break;

        // KEYS ─────────────────────────────────────────────────────────────────        case 'keys':
            $pattern = $key ?: '*';
            $all = $redis->keys($pattern);
            $result = array_slice($all ?: [], 0, $count);
            break;

        case 'exists':
            requireKey($key);
            $result = (bool)$redis->exists($key);
            break;

        case 'ttl':
            requireKey($key);
            $result = $redis->ttl($key);
            break;

        case 'type':
            requireKey($key);
            $result = $redis->type($key);
            break;

        case 'expire':
            requireKey($key);
            $result = $redis->expire($key, $ttl);
            break;
    }

    $redis->close();
    respond(true, $action, $key, $result);

} catch (Exception $e) {
    respond(false, $action, $key, null, $e->getMessage());
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function respond(bool $success, string $action, string $key, $data, string $error = ''): void {
    global $timeStart;
    $out = [
        'success' => $success,
        'action'  => $action,
        'key'     => $key,
        'data'    => $data,
        'time_ms' => round((microtime(true) - $timeStart) * 1000, 2),
    ];
    if ($error) $out['error'] = $error;
    if (!$success) http_response_code(400);
    echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

function requireKey(string $key): void {
    if (empty($key)) respond(false, '', '', null, 'key is required');
}

function requireField(string $field): void {
    if (empty($field)) respond(false, '', '', null, 'field is required');
}

function tryDecodeJson($val) {
    if (!is_string($val)) return $val;
    $decoded = json_decode($val, true);
    return ($decoded !== null) ? $decoded : $val;
}
