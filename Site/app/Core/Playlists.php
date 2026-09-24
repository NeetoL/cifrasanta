<?php
declare(strict_types=1);
namespace CifraSanta\Core;
use PDO;
use RuntimeException;

final class Playlists {
    private Service $service;
    public function __construct(private PDO $db) { $this->service = new Service($db); }
    public function all(int $userId): array {
        $items = $this->service->query('SELECT id, titulo AS title, versao AS version FROM cifra_santa_playlist WHERE usuario_id=? ORDER BY atualizado_em DESC, id DESC', [$userId])->fetchAll();
        $links = $this->service->query('SELECT pm.playlist_id, pm.musica_id FROM cifra_santa_playlist_musica pm JOIN cifra_santa_playlist p ON p.id=pm.playlist_id WHERE p.usuario_id=? ORDER BY pm.playlist_id, pm.posicao', [$userId])->fetchAll();
        $grouped = [];
        foreach ($links as $link) $grouped[$link['playlist_id']][] = (string)$link['musica_id'];
        foreach ($items as &$item) {
            $item['id'] = (string)$item['id'];
            $item['version'] = (int)$item['version'];
            $item['songIds'] = $grouped[$item['id']] ?? [];
        }
        return $items;
    }
    public function mutate(int $userId, array $data): array {
        $action = Service::field($data, 'action', 10);
        if (!in_array($action, ['save','delete'], true)) throw new RuntimeException('Ação inválida.', 422);
        $id = isset($data['id']) ? Service::id($data['id']) : null;
        if ($action === 'delete' && $id === null) throw new RuntimeException('Lista inválida.', 422);
        $title = $action === 'save' ? Service::field($data, 'title', 120) : '';
        $ids = $data['songIds'] ?? [];
        if (!is_array($ids) || !array_is_list($ids) || count($ids)>100) throw new RuntimeException('Escolha até 100 músicas.',422);
        $ids = array_map([Service::class,'id'], $ids);
        if (count($ids)!==count(array_unique($ids))) throw new RuntimeException('Não repita músicas na lista.',422);
        $this->db->beginTransaction();
        try {
            // Serializa alterações do mesmo usuário, incluindo novas listas.
            $this->service->query('SELECT id FROM cifra_santa_usuario WHERE id=? FOR UPDATE',[$userId]);
            $oldIds = [];
            if ($id !== null) {
                $current = $this->service->query('SELECT versao FROM cifra_santa_playlist WHERE id=? AND usuario_id=? FOR UPDATE',[$id,$userId])->fetchColumn();
                if ($current === false) throw new RuntimeException('Lista não encontrada.',404);
                if (Service::id($data['version'] ?? null) !== (int)$current) throw new RuntimeException('Esta lista mudou em outro aparelho. Volte e atualize antes de editar.',409);
                $oldIds = $this->service->query('SELECT musica_id FROM cifra_santa_playlist_musica WHERE playlist_id=?',[$id])->fetchAll(PDO::FETCH_COLUMN);
            }
            if ($action === 'delete') {
                $this->service->query('DELETE FROM cifra_santa_playlist WHERE id=? AND usuario_id=?',[$id,$userId]);
            } else {
                foreach ($ids as $songId) {
                    if (!in_array($songId, $oldIds) && !$this->service->query('SELECT id FROM cifra_santa_cifra WHERE musica_id=? AND publicada=1',[$songId])->fetchColumn()) throw new RuntimeException('Uma música não está mais disponível.',422);
                }
                if ($id === null) {
                    if ((int)$this->service->query('SELECT COUNT(*) FROM cifra_santa_playlist WHERE usuario_id=?',[$userId])->fetchColumn() >= 100) throw new RuntimeException('Limite de 100 listas por conta.',422);
                    $this->service->query('INSERT INTO cifra_santa_playlist(usuario_id,titulo) VALUES(?,?)',[$userId,$title]);
                    $id = (int)$this->db->lastInsertId();
                } else {
                    $this->service->query('UPDATE cifra_santa_playlist SET titulo=?, versao=versao+1 WHERE id=? AND usuario_id=?',[$title,$id,$userId]);
                    $this->service->query('DELETE FROM cifra_santa_playlist_musica WHERE playlist_id=?',[$id]);
                }
                foreach ($ids as $position=>$songId) $this->service->query('INSERT INTO cifra_santa_playlist_musica(playlist_id,musica_id,posicao) VALUES(?,?,?)',[$id,$songId,$position]);
            }
            $this->db->commit();
        } catch (\Throwable $e) { $this->db->rollBack(); throw $e; }
        return $this->all($userId);
    }
}
