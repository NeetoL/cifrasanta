<?php
declare(strict_types=1);
namespace CifraSanta\Core;

use PDO;
use RuntimeException;

final class Service
{
    public function __construct(private PDO $db) {}

    public function query(string $sql, array $args = []): \PDOStatement {
        $query = $this->db->prepare($sql);
        $query->execute($args);
        return $query;
    }

    public static function field(array $data, string $key, int $max, bool $optional = false): string {
        if (isset($data[$key]) && !is_string($data[$key])) throw new RuntimeException('Campo inválido: ' . $key, 422);
        $value = trim($data[$key] ?? '');
        if ((!$optional && $value === '') || mb_strlen($value) > $max) throw new RuntimeException('Preencha corretamente: ' . $key, 422);
        return $value;
    }

    public static function id(mixed $value): int {
        $id = filter_var($value, FILTER_VALIDATE_INT);
        if ($id === false || $id < 1) throw new RuntimeException('Identificador inválido.', 422);
        return $id;
    }

    public function throttle(string $scope, int $limit): void {
        $key = hash('sha256', $scope);
        $window = intdiv(time(), 900);
        $this->query('INSERT INTO cifra_santa_limite_acesso (chave, tentativas, janela) VALUES (?, 1, ?) ON DUPLICATE KEY UPDATE tentativas = IF(janela = VALUES(janela), tentativas + 1, 1), janela = VALUES(janela)', [$key, $window]);
        if ((int) $this->query('SELECT tentativas FROM cifra_santa_limite_acesso WHERE chave = ?', [$key])->fetchColumn() > $limit) {
            throw new RuntimeException('Muitas tentativas. Aguarde 15 minutos.', 429);
        }
    }

    public function register(array $data): array {
        $this->throttle('register:' . ($_SERVER['REMOTE_ADDR'] ?? 'cli'), 10);
        $name = self::field($data, 'nome', 120);
        $email = strtolower(self::field($data, 'email', 190));
        $password = $data['senha'] ?? '';
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) throw new RuntimeException('E-mail inválido.', 422);
        if (!is_string($password) || strlen($password) < 10 || strlen($password) > 72) throw new RuntimeException('Use uma senha de 10 a 72 bytes.', 422);
        try {
            $this->query('INSERT INTO cifra_santa_usuario (nome, email, senha_hash) VALUES (?, ?, ?)', [$name, $email, password_hash($password, PASSWORD_DEFAULT)]);
        } catch (\PDOException $error) {
            if (($error->errorInfo[1] ?? 0) === 1062) throw new RuntimeException('Não foi possível cadastrar este e-mail.', 409);
            throw $error;
        }
        return ['id' => (string) $this->db->lastInsertId(), 'nome' => $name, 'email' => $email, 'papel' => 'usuario'];
    }

    public function login(array $data, bool $admin = false): array {
        $email = strtolower(self::field($data, 'email', 190));
        $this->throttle('login-ip:' . ($_SERVER['REMOTE_ADDR'] ?? 'cli'), 50);
        $this->throttle('login-email:' . $email, 15);
        $password = $data['senha'] ?? '';
        if (!is_string($password) || strlen($password) > 72) throw new RuntimeException('E-mail ou senha incorretos.', 401);
        $user = $this->query('SELECT * FROM cifra_santa_usuario WHERE email = ?', [$email])->fetch();
        $valid = password_verify($password, $user['senha_hash'] ?? '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.');
        if (!$user || !$valid || !$user['ativo'] || ($admin && $user['papel'] !== 'admin')) throw new RuntimeException('E-mail ou senha incorretos.', 401);
        unset($user['senha_hash']);
        return $user;
    }

    public function issueToken(array $user): array {
        $token = bin2hex(random_bytes(32));
        $this->query('INSERT INTO cifra_santa_token (token_hash, usuario_id, expira_em) VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY))', [hash('sha256', $token), $user['id']]);
        $this->query('DELETE FROM cifra_santa_token WHERE usuario_id = ? AND expira_em <= UTC_TIMESTAMP()', [$user['id']]);
        return ['token' => $token, 'usuario' => ['id' => (string) $user['id'], 'nome' => $user['nome'], 'email' => $user['email'], 'papel' => $user['papel'] ?? 'usuario']];
    }

    public function authenticate(string $token): array {
        $user = $this->query('SELECT u.id, u.nome, u.email, u.papel FROM cifra_santa_token t JOIN cifra_santa_usuario u ON u.id = t.usuario_id WHERE t.token_hash = ? AND t.expira_em > UTC_TIMESTAMP() AND u.ativo = 1', [hash('sha256', $token)])->fetch();
        if (!$user) throw new RuntimeException('Entre na sua conta para continuar.', 401);
        $user['id'] = (string) $user['id'];
        return $user;
    }

    public static function bibleBook(mixed $value): string {
        if (!is_string($value) || !preg_match('/^[a-z0-9-]{1,12}$/D', $value)) throw new RuntimeException('Livro inválido.', 422);
        return $value;
    }

    public function bibleChapters(string $book): array {
        if (!$this->query('SELECT id FROM cifra_santa_biblia_livro WHERE id = ?', [$book])->fetchColumn()) throw new RuntimeException('Livro não encontrado.', 404);
        $chapters = $this->query('SELECT DISTINCT capitulo FROM cifra_santa_biblia_versiculo WHERE livro_id = ? ORDER BY capitulo', [$book])->fetchAll(PDO::FETCH_COLUMN);
        return ['livro' => $book, 'capitulos' => array_map('intval', $chapters)];
    }

    public function bibleVerses(string $book, int $chapter): array {
        $verses = $this->query('SELECT versiculo AS numero, texto FROM cifra_santa_biblia_versiculo WHERE livro_id = ? AND capitulo = ? ORDER BY versiculo', [$book, $chapter])->fetchAll();
        if (!$verses) throw new RuntimeException('Capítulo não encontrado.', 404);
        foreach ($verses as &$verse) $verse['numero'] = (int) $verse['numero'];
        unset($verse);
        return ['livro' => $book, 'capitulo' => $chapter, 'versiculos' => $verses];
    }

    public function catalog(): array {
        $songs = $this->query('SELECT m.id, m.titulo AS title, m.artista AS artist, m.categoria AS category, c.tom AS originalKey, c.conteudo AS chart FROM cifra_santa_musica m JOIN cifra_santa_cifra c ON c.musica_id = m.id WHERE c.publicada = 1 ORDER BY m.titulo, m.id')->fetchAll();
        foreach ($songs as &$song) $song['id'] = (string) $song['id'];
        unset($song);
        $repertoires = $this->query('SELECT id, titulo AS title, descricao AS subtitle FROM cifra_santa_repertorio WHERE publicado = 1 ORDER BY id DESC')->fetchAll();
        $links = $this->query('SELECT rm.repertorio_id, rm.musica_id FROM cifra_santa_repertorio_musica rm JOIN cifra_santa_cifra c ON c.musica_id = rm.musica_id WHERE c.publicada = 1 ORDER BY rm.repertorio_id, rm.posicao')->fetchAll();
        $grouped = [];
        foreach ($links as $link) $grouped[$link['repertorio_id']][] = (string) $link['musica_id'];
        foreach ($repertoires as &$item) {
            $item['id'] = (string) $item['id'];
            $item['songIds'] = $grouped[$item['id']] ?? [];
        }
        return ['songs' => $songs, 'repertoires' => $repertoires];
    }

    public function favorites(int $userId): array {
        return array_map('strval', $this->query('SELECT f.musica_id FROM cifra_santa_favorito f JOIN cifra_santa_cifra c ON c.musica_id = f.musica_id WHERE f.usuario_id = ? AND c.publicada = 1 ORDER BY f.criado_em', [$userId])->fetchAll(PDO::FETCH_COLUMN));
    }

    public function setFavorite(int $userId, int $songId, bool $favorite): array {
        if ($favorite) {
            if (!$this->query('SELECT id FROM cifra_santa_cifra WHERE musica_id = ? AND publicada = 1', [$songId])->fetchColumn()) throw new RuntimeException('Música indisponível.', 404);
            $this->query('INSERT IGNORE INTO cifra_santa_favorito (usuario_id, musica_id) VALUES (?, ?)', [$userId, $songId]);
        } else {
            $this->query('DELETE FROM cifra_santa_favorito WHERE usuario_id = ? AND musica_id = ?', [$userId, $songId]);
        }
        return $this->favorites($userId);
    }

    public function saveSong(array $data, int $adminId): int {
        $title = self::field($data, 'titulo', 200);
        $artist = self::field($data, 'artista', 200);
        $category = self::field($data, 'categoria', 80);
        $key = self::field($data, 'tom', 12);
        if (!preg_match('/^[A-G](?:#|b)?m?$/D', $key)) throw new RuntimeException('Tom inválido. Exemplos: C, F#, Bm.', 422);
        $chart = self::field($data, 'conteudo', 100000);
        $published = isset($data['publicada']) ? 1 : 0;
        $id = empty($data['id']) ? null : self::id($data['id']);
        $this->db->beginTransaction();
        try {
            if ($id !== null) {
                if (!$this->query('SELECT id FROM cifra_santa_musica WHERE id = ? FOR UPDATE', [$id])->fetchColumn()) throw new RuntimeException('Música não encontrada.', 404);
                $this->query('UPDATE cifra_santa_musica SET titulo = ?, artista = ?, categoria = ? WHERE id = ?', [$title, $artist, $category, $id]);
            } else {
                $this->query('INSERT INTO cifra_santa_musica (titulo, artista, categoria, criado_por) VALUES (?, ?, ?, ?)', [$title, $artist, $category, $adminId]);
                $id = (int) $this->db->lastInsertId();
            }
            $this->query('INSERT INTO cifra_santa_cifra (musica_id, tom, conteudo, publicada) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE tom = VALUES(tom), conteudo = VALUES(conteudo), publicada = VALUES(publicada)', [$id, $key, $chart, $published]);
            $this->db->commit();
            return $id;
        } catch (\Throwable $error) { $this->db->rollBack(); throw $error; }
    }

    public function saveRepertoire(array $data, int $adminId): int {
        $title = self::field($data, 'titulo', 200);
        $description = self::field($data, 'descricao', 255, true);
        $raw = self::field($data, 'musicas', 10000, true);
        $ids = $raw === '' ? [] : array_map([self::class, 'id'], preg_split('/[\s,]+/', $raw));
        if (count($ids) !== count(array_unique($ids))) throw new RuntimeException('Não repita músicas no repertório.', 422);
        $id = empty($data['id']) ? null : self::id($data['id']);
        $this->db->beginTransaction();
        try {
            foreach ($ids as $songId) if (!$this->query('SELECT id FROM cifra_santa_musica WHERE id = ?', [$songId])->fetchColumn()) throw new RuntimeException('Uma música do repertório não existe.', 422);
            if ($id !== null) {
                if (!$this->query('SELECT id FROM cifra_santa_repertorio WHERE id = ? FOR UPDATE', [$id])->fetchColumn()) throw new RuntimeException('Repertório não encontrado.', 404);
                $this->query('UPDATE cifra_santa_repertorio SET titulo = ?, descricao = ?, publicado = ? WHERE id = ?', [$title, $description, isset($data['publicado']) ? 1 : 0, $id]);
                $this->query('DELETE FROM cifra_santa_repertorio_musica WHERE repertorio_id = ?', [$id]);
            } else {
                $this->query('INSERT INTO cifra_santa_repertorio (titulo, descricao, publicado, criado_por) VALUES (?, ?, ?, ?)', [$title, $description, isset($data['publicado']) ? 1 : 0, $adminId]);
                $id = (int) $this->db->lastInsertId();
            }
            foreach ($ids as $position => $songId) $this->query('INSERT INTO cifra_santa_repertorio_musica (repertorio_id, musica_id, posicao) VALUES (?, ?, ?)', [$id, $songId, $position]);
            $this->db->commit();
            return $id;
        } catch (\Throwable $error) { $this->db->rollBack(); throw $error; }
    }
}
