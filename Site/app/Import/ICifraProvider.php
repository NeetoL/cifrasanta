<?php
declare(strict_types=1);
namespace CifraSanta\Import;
interface ICifraProvider {
    public function id():string;
    public function name():string;
    /** Hosts atendidos com exclusividade por este provedor; vazio = escolhido pelo ProviderResolver. */
    public function domains():array;
    public function normalizeUrl(string $url):string;
    public function extract(string $url):array;
}
