<?php
declare(strict_types=1);
namespace CifraSanta\Models;

final class Catalog {
    public static function songs(): array { return [
        ['id'=>'sacramento-comunhao','title'=>'Sacramento da Comunhão','artist'=>'Nelsinho Corrêa','category'=>'Comunhão','key'=>'D','color'=>'peach','demo'=>false,'source'=>'https://www.cifraclub.com.br/nelsinho-correa/sacramento-da-comunhao/'],
        ['id'=>'hoje-tempo-louvar','title'=>'Hoje é Tempo de Louvar a Deus','artist'=>'Catálogo da comunidade','category'=>'Louvor','key'=>'G','color'=>'lavender','demo'=>false],
        ['id'=>'luz-do-caminho','title'=>'Luz do Caminho','artist'=>'Composição demonstrativa','category'=>'Entrada','key'=>'C','color'=>'blue','demo'=>true],
        ['id'=>'pao-da-partilha','title'=>'Pão da Partilha','artist'=>'Composição demonstrativa','category'=>'Comunhão','key'=>'G','color'=>'gold','demo'=>true],
        ['id'=>'voz-de-esperanca','title'=>'Voz de Esperança','artist'=>'Composição demonstrativa','category'=>'Louvor','key'=>'F','color'=>'mint','demo'=>true],
        ['id'=>'ao-teu-encontro','title'=>'Ao Teu Encontro','artist'=>'Composição demonstrativa','category'=>'Envio','key'=>'A','color'=>'rose','demo'=>true],
    ]; }
    public static function repertoires(): array { return [
        ['id'=>'missa-domingo','title'=>'Missa de domingo','context'=>'Celebração dominical','date'=>'27 SET','color'=>'blue','songs'=>['luz-do-caminho','sacramento-comunhao','pao-da-partilha','ao-teu-encontro']],
        ['id'=>'grupo-oracao','title'=>'Grupo de oração','context'=>'Encontro semanal','date'=>'QUA','color'=>'gold','songs'=>['hoje-tempo-louvar','voz-de-esperanca','luz-do-caminho']],
        ['id'=>'adoracao','title'=>'Noite de adoração','context'=>'Momento de oração','date'=>'SEX','color'=>'lavender','songs'=>['voz-de-esperanca','pao-da-partilha']],
    ]; }
    public static function song(string $id): ?array { foreach (self::songs() as $song) if ($song['id'] === $id) return $song; return null; }
    public static function repertoire(string $id): ?array { foreach (self::repertoires() as $item) if ($item['id'] === $id) return $item; return null; }
    public static function chart(): array { return [
        ['D              A/C#       Bm             Bm/A','Senhor, quando te vejo no sacramento da comunhão'],
        ['G              A  A/C#     D  D/F#     G','Sinto o céu se abrir e uma luz a me atingir'],
        [' Em7                 D/F#  G                 A4  A','Esfriando minha cabeça e esquentando meu coração'],
        ['D              A/C#       Bm                 Bm/A','Senhor, graças e louvores sejam dadas a todo momento',true],
        ['G                A  A/C#     D  D/F#     G','Quero te louvar na dor, na alegria e no sofrimento'],
        ['    Em7          A   A/C#   D  D/F#   G','E se em meio à tribulação, eu me esquecer de ti'],
        ['  Em7                         A4  A','Ilumina minhas trevas com Tua luz'],
        ['  D   A/C#          Bm                    Bm/A','Jesus, fonte de misericórdia que jorra do templo',true],
        [' Em   D/F#       A4  A  A/G','Jesus, o Filho da Rainha'],
        [' F#m  Bbº  Bm           G  C','Jesus, rosto divino do homem'],
        ['  D    Em      A       D','Jesus, rosto humano de Deus'],
        ['  G                      A/G','Chego muitas vezes em Tua casa, meu Senhor',true],
        [' F#m    F#/Bb        Bm   Bm/A','Triste, abatido, precisando de amor'],
        ['    Em             D   C            D','Mas depois da comunhão tua casa é meu coração'],
        ['    Em        D/F#  G         A4  A  D/F#','Então sinto o céu dentro de mim'],
    ]; }
    public static function shapes(): array { return [
        'A'=>'x02220','A/C#'=>'x42220','A/G'=>'3x2220','A4'=>'x02230','B4'=>'x24452','B7'=>'x21202','Bbº'=>'x12020','Bm'=>'x24432','Bm/A'=>'x04432','C'=>'x32010','D'=>'xx0232','Em7'=>'022030','D/F#'=>'2x0232','G'=>'320003',
    ]; }
}
