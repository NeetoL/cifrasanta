<?php
declare(strict_types=1);
// HTML → CifraClubParser → DTO, sem rede. Usa tests/fixtures/cifraclub-estrutura.html (estrutura real, letra inventada).
// Opcional: CIFRACLUB_SAMPLE=/caminho/pagina.html também valida uma página real salva localmente (não versionada).
require dirname(__DIR__).'/app/server.php';
use CifraSanta\Import\ChartParser;
use CifraSanta\Import\CifraClubParser;
use CifraSanta\Import\CifraClubProvider;
use CifraSanta\Import\ProviderResolver;
$checks=0;
function checkCc(bool $pass,string $label):void{global $checks;if(!$pass)throw new RuntimeException('Falhou: '.$label);$checks++;}
function rejectsCc(callable $fn,string $needle,string $label):void{try{$fn();}catch(RuntimeException $e){checkCc(str_contains($e->getMessage(),$needle),$label.' ('.$e->getMessage().')');return;}throw new RuntimeException('Falhou: '.$label);}
/** Linha de acordes que a prévia remonta para uma linha de letra. */
function chordsAbove(string $content,string $lyric):?string{foreach(ChartParser::preview($content) as [$chords,$text])if(rtrim($text)===$lyric)return $chords;return null;}

$html=file_get_contents(__DIR__.'/fixtures/cifraclub-estrutura.html');
$parser=new CifraClubParser();
$r=$parser->parse($html);

// Metadados
checkCc($r['titulo']==='Canto de Teste','título');
checkCc($r['artista']==='Grupo Fictício','artista');
checkCc($r['tom']==='Bm','tom (sem "com forma de")');
checkCc($r['capotraste']==='5ª casa','capotraste');
checkCc($r['afinacao']==='Padrão','afinação');
checkCc($r['deteccao']['titulo']==='json-ld MusicComposition' && $r['deteccao']['tom']==='data-anchor --chord-tone' && $r['deteccao']['conteudo']==='pre[data-chord-content]','estratégias primárias');

// Estrutura e formatação
$c=$r['conteudo'];$lines=explode("\n",$c);
checkCc($r['estrutura']['acordes']===18 && $r['estrutura']['secoes']===5 && $r['estrutura']['tablaturas']===3,'contagem da estrutura '.json_encode($r['estrutura']));
checkCc($lines[0]==='[Intro]' && ChartParser::preview($lines[1])[0][0]==='        D  E  F#m7(11)  E/G#','seção separada dos acordes da introdução, colunas mantidas');
foreach(['[Tab - Intro]','[Primeira Parte]','[Refrão]','[Final]','Parte 1 de 1'] as $line)checkCc(in_array($line,$lines,true),'linha preservada: '.$line);
foreach(['E|-----0--0---2-------0--0---2--------------|','B|----------------0-------------------------|','G|-2----------------------------------------|'] as $tab)checkCc(in_array($tab,$lines,true),'tablatura intacta');
checkCc(ChartParser::preview($lines[6])[0][0]==='   D              E' && str_starts_with($lines[7],'E|'),'acordes sobre a tablatura não se misturam a ela');
checkCc(chordsAbove($c,'Primeira linha inventada para o teste do parser')==='        D2                      E','colunas dos acordes sobre a letra');
checkCc(chordsAbove($c,'Segunda linha com acentuação: ação')==='    F#m7(11)          E4  E','acordes complexos e acentos');
checkCc(chordsAbove($c,'Curta')==='   A7M(9)','acorde além do fim da letra');
checkCc(chordsAbove($c,'Refrão inventado')==='Bm     G                               A','letra mais curta que a linha de acordes');
checkCc(chordsAbove($c,'        Linha com tab')==='        D','tabs expandidos nas duas linhas');
checkCc(str_contains($c,"Cur[A7M(9)]ta\n\n[Refrão]\n\n[Bm]"),'linhas em branco entre seções preservadas');
checkCc(!str_contains($c,'alert') && !str_contains($c,'Menu') && !str_contains($c,'Rodapé'),'script e outros <pre> ignorados');
checkCc(ChartParser::normalize($c,'inline')===$c,'conteúdo já normalizado');

// Classes CSS com hash trocadas: nada muda.
$renamed=preg_replace_callback('/class="[^"]*"/',fn()=>'class="x'.bin2hex(random_bytes(3)).'"',$html);
$again=$parser->parse($renamed);
checkCc($again['conteudo']===$c && $again['tom']==='Bm' && $again['afinacao']==='Padrão','independente das classes CSS');

// Fallbacks: sem JSON-LD, sem data-anchor e sem ids dos cartões.
$bare=preg_replace(['~<script type="application/ld\+json">.*?</script>~s','/\sdata-anchor="[^"]*"/','/\sid="(key|capo|tuning)"/'],'',$html);
$f=$parser->parse($bare);
checkCc($f['titulo']==='Canto de Teste' && $f['artista']==='Grupo Fictício' && $f['deteccao']['titulo']==='og:title','título/artista por og:title');
checkCc($f['tom']==='Bm' && $f['capotraste']==='5ª casa' && $f['afinacao']==='Padrão' && str_starts_with($f['deteccao']['tom'],'rótulo'),'tom/capo/afinação pelos rótulos visíveis');
// Sem os cartões: afinação pelos diagramas (data-tuning) e tom pelo "Tom:" do bloco de configuração.
$noCards=preg_replace('~<ul class="_k983">.*?</ul>~s','',$bare);
$g=$parser->parse($noCards);
checkCc($g['afinacao']==='Padrão' && $g['deteccao']['afinacao']==='data-tuning' && $g['tom']==='Bm' && $g['capotraste']==='5ª casa','fallback data-tuning e bloco de configuração');
// Sem data-chord-content: o <pre> com mais acordes marcados.
$h=$parser->parse(str_replace(' data-chord-content="true"','',$html));
checkCc($h['conteudo']===$c && $h['deteccao']['conteudo']==='pre com mais [data-chord-name]','fallback do bloco da cifra');
$tuned=$parser->parse(preg_replace('~<ul class="_k983">.*?</ul>~s','',str_replace('E A D G B E','D A D G B E',$html)));
checkCc($tuned['afinacao']==='D A D G B E','afinação alternativa pelos diagramas');

// Erros com a etapa real
rejectsCc(fn()=>$parser->parse('<html><body><pre>[C]x</pre></body></html>'),'título não encontrado','sem título');
rejectsCc(fn()=>$parser->parse('<html><head><title>X - Y - Cifra Club</title></head><body><p>nada</p></body></html>'),'bloco da cifra não encontrado','sem cifra');
rejectsCc(fn()=>$parser->parse('<!ENTITY x SYSTEM "file:///etc/passwd">'),'não permitido','entidades');

// Provedor e resolução só pela URL
$resolver=new ProviderResolver([]);
$provider=$resolver->resolve('https://www.cifraclub.com.br/comunidade-gerados-pela-imaculada/odres-novos/');
checkCc($provider instanceof CifraClubProvider && $provider->id()==='cifraclub' && !$provider->importsContent(),'Cifra Club → provedor dedicado, conteúdo não autorizado por padrão');
checkCc($resolver->resolve('https://cifraclub.com.br/a/b/') instanceof CifraClubProvider,'domínio raiz');
checkCc(!($resolver->resolve('https://notcifraclub.com.br/a/') instanceof CifraClubProvider),'sufixo parecido não engana');
rejectsCc(fn()=>$provider->normalizeUrl('https://evil.example.org/a/'),'não permitido','allowlist de hosts');
rejectsCc(fn()=>$provider->normalizeUrl('http://www.cifraclub.com.br/a/'),'HTTPS','somente HTTPS');
$config=tempnam(sys_get_temp_dir(),'cs-cc-');file_put_contents($config,"<?php return ['cifraclub'=>['authorization'=>'Licença de teste']];");
putenv('CIFRA_IMPORT_PROVIDER_CONFIG='.$config);
try{$authorized=(new ProviderResolver())->resolve('https://www.cifraclub.com.br/a/b/');checkCc($authorized instanceof CifraClubProvider && $authorized->importsContent(),'autorização configurada pelo desenvolvedor libera o conteúdo');}
finally{putenv('CIFRA_IMPORT_PROVIDER_CONFIG');@unlink($config);}

// Amostra real salva localmente (opcional, fora do Git).
if(($sample=getenv('CIFRACLUB_SAMPLE')) && is_file($sample)){
 $real=$parser->parse(file_get_contents($sample));
 foreach(['titulo','artista','tom','capotraste','afinacao'] as $k)echo str_pad($k,11),': ',$real[$k]===''?'(não encontrado)':$real[$k],'  ← ',$real['deteccao'][$k],"\n";
 echo 'estrutura  : ',json_encode($real['estrutura']),'  ← ',$real['deteccao']['conteudo'],"\n";
 checkCc($real['titulo']!=='' && $real['artista']!=='' && $real['tom']!=='' && $real['estrutura']['acordes']>0,'amostra real');
}
echo "$checks verificações do parser Cifra Club passaram.\n";
