<?php
declare(strict_types=1);
namespace CifraSanta\Controllers;
use CifraSanta\Models\Catalog;

final class PageController {
    public function home(): void { \render('home', ['title'=>'Início · Cifra Santa', 'songs'=>Catalog::songs(), 'repertoires'=>Catalog::repertoires()]); }
    public function search(): void {
        $query = trim((string) ($_GET['q'] ?? ''));
        $category = trim((string) ($_GET['momento'] ?? ''));
        $key = trim((string) ($_GET['tom'] ?? ''));
        $songs = array_values(array_filter(Catalog::songs(), static function (array $song) use ($query, $category, $key): bool {
            $contains = static fn(string $haystack): bool => function_exists('mb_stripos') ? mb_stripos($haystack, $query) !== false : stripos($haystack, $query) !== false;
            $matches = $query === '' || $contains($song['title']) || $contains($song['artist']) || $contains($song['category']);
            return $matches && ($category === '' || $song['category'] === $category) && ($key === '' || $song['key'] === $key);
        }));
        \render('search', compact('songs','query','category','key') + ['title'=>'Buscar cifras · Cifra Santa','allSongs'=>Catalog::songs()]);
    }
    public function favorites(): void {
        $songs = array_values(array_filter(Catalog::songs(), static fn(array $song): bool => \is_favorite($song['id'])));
        \render('favorites', ['title'=>'Favoritos · Cifra Santa','songs'=>$songs]);
    }
    public function repertoires(): void { \render('repertoires', ['title'=>'Repertórios · Cifra Santa','repertoires'=>Catalog::repertoires()]); }
    public function repertoire(string $id): void {
        $item = Catalog::repertoire($id);
        if (!$item) { http_response_code(404); \render('not-found', ['title'=>'Repertório não encontrado · Cifra Santa']); return; }
        \render('repertoire', ['title'=>$item['title'].' · Cifra Santa','item'=>$item]);
    }
    public function song(string $id): void {
        $song = Catalog::song($id);
        if (!$song) { http_response_code(404); \render('not-found', ['title'=>'Cifra não encontrada · Cifra Santa']); return; }
        if ($id === 'sacramento-comunhao') {
            \render('reader', ['title'=>$song['title'].' · Cifra Santa','song'=>$song,'chart'=>Catalog::chart(),'shapes'=>Catalog::shapes()], true);
            return;
        }
        \render('song', ['title'=>$song['title'].' · Cifra Santa','song'=>$song]);
    }
}
