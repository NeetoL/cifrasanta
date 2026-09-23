<?php
declare(strict_types=1);
namespace CifraSanta\Controllers;
use CifraSanta\Models\Catalog;

final class FavoriteController {
    public function toggle(): void {
        $id = (string) ($_POST['id'] ?? '');
        $token = (string) ($_POST['csrf'] ?? '');
        if (!hash_equals(\csrf_token(), $token)) { http_response_code(419); $this->json(['error'=>'Sessão expirada. Atualize a página.']); return; }
        if (!Catalog::song($id)) { http_response_code(404); $this->json(['error'=>'Música não encontrada.']); return; }
        $favorites = \favorites();
        if (in_array($id, $favorites, true)) $favorites = array_values(array_diff($favorites, [$id]));
        else $favorites[] = $id;
        $_SESSION['favorites'] = $favorites;
        $this->json(['id'=>$id,'favorite'=>in_array($id, $favorites, true),'count'=>count($favorites)]);
    }
    private function json(array $value): void { header('Content-Type: application/json; charset=utf-8'); echo json_encode($value, JSON_UNESCAPED_UNICODE); }
}
