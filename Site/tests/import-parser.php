<?php
declare(strict_types=1);
require dirname(__DIR__).'/app/server.php';
use CifraSanta\Import\UrlPolicy;
use CifraSanta\Import\HtmlChartParser;
use CifraSanta\Import\ChartParser;
use CifraSanta\Import\SafeHttpClient;
use CifraSanta\Import\ConfiguredHtmlProvider;
use CifraSanta\Import\ProviderResolver;
$checks=0;
function checkImport(bool $pass,string $label):void{global $checks;if(!$pass)throw new RuntimeException($label);$checks++;}
function rejectsImport(callable $fn,string $label):void{try{$fn();}catch(RuntimeException){checkImport(true,$label);return;}throw new RuntimeException($label);}
$policy=new UrlPolicy(['songs.example.org']);
checkImport($policy->normalize('https://SONGS.example.org:443/a/../song/#part')==='https://songs.example.org/song/','URL canônica');
foreach(['http://songs.example.org/a','https://127.0.0.1/a','https://localhost/a','https://songs.example.org.evil.com/a','https://songs.example.org@127.0.0.1/a','https://songs.example.org:8080/a','file:///etc/passwd','https://songs.example.org/abc%0d%0aX:1','https://songs.example.org/\\evil','https://songs.example.org/%zz'] as $url)rejectsImport(fn()=>$policy->normalize($url),'URL bloqueada');
foreach(['127.0.0.1','10.0.0.1','172.16.2.2','192.168.1.1','169.254.169.254','100.64.0.1','198.18.0.1','192.0.2.1','224.0.0.1','0.0.0.0','::1','::ffff:127.0.0.1'] as $ip)checkImport(!UrlPolicy::publicIpv4($ip),'IP bloqueado '.$ip);
checkImport(UrlPolicy::publicIpv4('93.184.215.14'),'IP público');
checkImport($policy->redirect('https://songs.example.org/a/start','../song')==='https://songs.example.org/song','redirect relativo');
rejectsImport(fn()=>$policy->redirect('https://songs.example.org/a','https://evil.example.net/'),'redirect fora allowlist');
$html='<!doctype html><html><head><meta charset="utf-8"></head><body><nav>Menu</nav><h1 id="title">Canção de teste</h1><span id="artist">Autor de teste</span><span id="key">Tom: C</span><span id="capo">2ª casa</span><pre id="chart">[Intro] C  G/B

C       G/B
Uma canção de teste
Am7     F7M
Outra linha inventada
<span class="ad">Publicidade</span><script>alert(1)</script></pre></body></html>';
$config=['selectors'=>['titulo'=>'//*[@id="title"]','artista'=>'//*[@id="artist"]','tom'=>'//*[@id="key"]','capotraste'=>'//*[@id="capo"]','conteudo'=>'//*[@id="chart"]'],'remove'=>['.//*[@class="ad"]'],'strip_prefixes'=>['tom'=>['Tom:']],'format'=>'aligned'];
$result=(new HtmlChartParser())->parse($html,$config);
checkImport($result['titulo']==='Canção de teste' && $result['tom']==='C' && $result['capotraste']==='2ª casa','metadados');
checkImport(!str_contains($result['conteudo'],'Publicidade') && !str_contains($result['conteudo'],'alert'),'limpeza DOM');
checkImport(str_contains($result['conteudo'],'[G/B]') && str_contains($result['conteudo'],'[F7M]'),'acordes complexos');
$rows=ChartParser::preview($result['conteudo']);$found=false;foreach($rows as [$chords,$lyric])if($lyric==='Uma canção de teste'){$found=true;checkImport($chords==='C       G/B','colunas Unicode preservadas');}
checkImport($found,'letra preservada');
$inline='[C]A &amp; B <texto> **literal**';checkImport(ChartParser::normalize($inline,'inline')===$inline,'normalização idempotente');
rejectsImport(fn()=>(new HtmlChartParser())->parse('<html><h1>Vazio</h1></html>',$config),'estrutura ausente');
rejectsImport(fn()=>(new HtmlChartParser())->parse('<!ENTITY x SYSTEM "file:///etc/passwd">',$config),'entidades proibidas');
rejectsImport(fn()=>new ConfiguredHtmlProvider('test',['enabled'=>true,'authorization'=>'']),'autorização não configurada');

// Detecção automática: nenhuma configuração, só o HTML.
$any=new UrlPolicy();
checkImport($any->normalize('https://Qualquer.Site.com.br/a/../musica/')==='https://qualquer.site.com.br/musica/','qualquer domínio público aceito');
foreach(['http://site.com.br/a','https://127.0.0.1/a','https://localhost/a','https://site.com.br:8443/a','https://user@site.com.br/a'] as $url)rejectsImport(fn()=>$any->normalize($url),'URL insegura bloqueada sem lista');
$page='<!doctype html><html><head><title>Hino de teste - Coral Fictício - Meu Site</title><meta property="og:site_name" content="Meu Site">
<script type="application/ld+json">{"@context":"https://schema.org","@graph":[{"@type":"MusicComposition","name":"Hino de teste","byArtist":{"@type":"MusicGroup","name":"Coral Fictício"}}]}</script></head>
<body><nav><pre>Menu</pre></nav><div class="info"><span>Tom:</span> <b>Am</b> <span>Capotraste:</span> 3ª casa <span>Afinação:</span> D A D G B E</div>
<pre class="cifra">[Intro] Am  F

Am          F
Primeira linha inventada
C        G/B
Segunda linha inventada
<script>alert(1)</script></pre><footer>Rodapé</footer></body></html>';
$found=(new HtmlChartParser())->detect($page);
checkImport($found['titulo']==='Hino de teste' && $found['artista']==='Coral Fictício','título e artista por JSON-LD');
checkImport($found['tom']==='Am' && $found['capotraste']==='3ª casa' && $found['afinacao']==='D A D G B E','tom, capotraste e afinação pelos rótulos');
checkImport(str_contains($found['conteudo'],'[G/B]') && str_contains($found['conteudo'],'[Am]Primeira') && !str_contains($found['conteudo'],'alert') && !str_contains($found['conteudo'],'Menu'),'bloco da cifra escolhido e limpo');
$meta=(new HtmlChartParser())->detect($page,false);
checkImport($meta['conteudo']==='' && $meta['titulo']==='Hino de teste','modo só metadados não traz a cifra');
$og=(new HtmlChartParser())->detect('<html><head><meta property="og:title" content="Canto simples - Autor Fictício"></head><body><pre>[C]Canto [G]simples de [Am]teste [F]aqui</pre></body></html>');
checkImport($og['titulo']==='Canto simples' && $og['artista']==='Autor Fictício' && str_contains($og['conteudo'],'[C]Canto'),'og:title e formato [C]palavra');
rejectsImport(fn()=>(new HtmlChartParser())->detect('<html><head><title>Sem cifra</title></head><body><p>Só texto.</p></body></html>'),'página sem cifra recusada');

// Resolução do provedor só pela URL.
$owned=new ConfiguredHtmlProvider('owned',(require __DIR__.'/import-providers.fixture.php')['owned']);
$resolver=new ProviderResolver([$owned]);
checkImport($resolver->resolve('https://owned.example.org/x/')===$owned,'provedor dedicado pelo domínio');
checkImport($resolver->resolve('https://www.cifraclub.com.br/artista/musica/')->id()==='cifraclub','Cifra Club: provedor dedicado');
checkImport($resolver->resolve('https://www.letras.mus.br/artista/musica/')->id()==='referencia','catálogo de terceiros só com metadados');
checkImport($resolver->resolve('https://cifraclub.com.br/a/')->name()==='Cifra Club','domínio raiz do catálogo');
checkImport($resolver->resolve('https://paroquia.example.org/canto/')->id()==='automatico','demais sites: detecção automática');
checkImport($resolver->resolve('https://notcifraclub.com.br/a/')->id()==='automatico','sufixo parecido não engana o resolvedor');
rejectsImport(fn()=>$resolver->resolve('https://10.0.0.1/a'),'resolvedor recusa IP');
// Trecho da resposta de bloqueio exibido no diagnóstico (formato da página "Access Denied" da Akamai).
$denied='<HTML><HEAD><TITLE>Access Denied</TITLE><style>b{x:y}</style></HEAD><BODY><H1>Access Denied</H1>You don\'t have permission to access "http&#58;&#47;&#47;www&#46;example&#46;com&#47;a&#47;" on this server.<P>Reference&#32;&#35;18&#46;abc123&#46;1727200000&#46;deadbeef<P>https&#58;&#47;&#47;errors&#46;edgesuite&#46;net&#47;18&#46;abc</BODY></HTML>';
$snippet=SafeHttpClient::bodySnippet($denied);
checkImport(str_starts_with($snippet,'Access Denied Access Denied You don\'t have permission') && str_contains($snippet,'Reference #18.abc123.1727200000.deadbeef') && !str_contains($snippet,'<') && !str_contains($snippet,'x:y'),'trecho do bloqueio legível, sem HTML nem CSS');
checkImport(mb_strlen(SafeHttpClient::bodySnippet(str_repeat('<p>texto longo</p>',200)))===301 && SafeHttpClient::bodySnippet('')==='','trecho limitado a 300 caracteres');
checkImport(SafeHttpClient::bodySnippet("\xff\xfeinv\xc3lido")!=='' ,'bytes inválidos não quebram o diagnóstico');
if(in_array('--network',$argv,true)){
 $response=(new SafeHttpClient())->get('https://example.com/',new UrlPolicy(['example.com']));
 checkImport(str_contains($response['html'],'Example Domain'),'download HTTPS real');
 rejectsImport(fn()=>(new HtmlChartParser())->parse($response['html'],$config),'página real sem cifra rejeitada');
 // Caso real informado pelo usuário: catálogo de terceiros → só metadados. Não imprime conteúdo da página.
 $url='https://www.cifraclub.com.br/comunidade-gerados-pela-imaculada/odres-novos/';
 $provider=(new ProviderResolver([]))->resolve($url);
 checkImport($provider->id()==='cifraclub' && $provider->name()==='Cifra Club','provedor do caso real');
 $draft=$provider->extract($url);
 checkImport($draft['url_origem']===$url && $draft['titulo']!=='' && $draft['artista']!=='' && $draft['conteudo']==='' && $draft['aviso']!=='','metadados do caso real sem conteúdo protegido');
 foreach(['titulo','artista','tom','afinacao','capotraste'] as $key)echo str_pad($key,11),': ',$draft[$key]===''?'(não encontrado)':$draft[$key],"\n";
 $d=$draft['diagnostico'];
 echo 'HTTP ',$d['status'],' · ',$d['content_type'],' · ',$d['bytes'],' bytes · ',$d['tempo_ms'],' ms · redirects: ',count($d['redirects']),' · estrutura: ',json_encode($d['parser']['estrutura']),"\n";
 checkImport($d['status']===200 && $d['parser']['estrutura']['acordes']>0,'diagnóstico do caso real');
}
echo "$checks verificações de segurança, DOM e formatação passaram.\n";
