<?php
declare(strict_types=1);
require __DIR__.'/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Import\CifraImportService;
use CifraSanta\Import\ChartParser;
use CifraSanta\Import\ImportDiagnosticException;
require __DIR__.'/app/Views/admin/kit.php';
header("Content-Security-Policy: default-src 'none'; img-src 'self'; style-src 'self'; script-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'");
if(!secure_transport()){http_response_code(403);exit('Acesse o painel por HTTPS.');}
start_admin_session();
const IMPORT_MOMENTS=['Entrada','Comunhão','Louvor','Envio'];
$user=null;$message='';$isError=false;$draft=null;$token='';$editing=false;$diagnostic=null;
try {
    if(empty($_SESSION['admin_id']) || (int)($_SESSION['expires']??0)<time())throw new RuntimeException('Entre como administrador para importar cifras.',401);
    $db=Database::connection();
    $q=$db->prepare("SELECT id,nome FROM cifra_santa_usuario WHERE id=? AND papel='admin' AND ativo=1");$q->execute([$_SESSION['admin_id']]);$user=$q->fetch();
    if(!$user)throw new RuntimeException('Acesso exclusivo de administradores.',403);
    foreach($_SESSION['imports']??[] as $key=>$item)if(($item['expires']??0)<time())unset($_SESSION['imports'][$key]);
    $import=new CifraImportService($db);
    if($_SERVER['REQUEST_METHOD']==='POST') {
        if(!is_string($_POST['csrf']??null) || !hash_equals($_SESSION['csrf'],$_POST['csrf']))throw new RuntimeException('Sessão expirada. Atualize a página.',419);
        $action=$_POST['action']??'';
        if($action==='extract'){
            if(!is_string($_POST['url']??null) || trim($_POST['url'])==='')throw new RuntimeException('Cole o endereço da cifra.',422);
            $draft=$import->identify($_POST['url'],(int)$user['id']);
            $diagnostic=$draft['diagnostico']??null;
            $token=bin2hex(random_bytes(24));
            while(count($_SESSION['imports']??[])>=3)array_shift($_SESSION['imports']);
            $_SESSION['imports'][$token]=['draft'=>$draft,'expires'=>time()+1800];
            $editing=$draft['conteudo']==='' || $draft['tom']==='' || $draft['artista']==='';
        }elseif(in_array($action,['preview','save','cancel'],true)){
            $token=is_string($_POST['token']??null)?$_POST['token']:'';
            $entry=$_SESSION['imports'][$token]??null;
            if(!$entry)throw new RuntimeException('Esta importação expirou. Cole a URL novamente.',419);
            if($action==='cancel'){unset($_SESSION['imports'][$token]);header('Location: admin-import.php',true,303);exit;}
            // Origem e provedor vêm da sessão; o formulário só traz os campos editáveis.
            $draft=$entry['draft'];
            foreach(['titulo','artista','tom','categoria','afinacao','capotraste','conteudo','formato'] as $field)if(is_string($_POST[$field]??null))$draft[$field]=$_POST[$field];
            $draft['publicada']=isset($_POST['publicada'])?'1':'';
            $_SESSION['imports'][$token]['draft']=$draft;
            if($action==='preview'){
                $draft=[...$draft,...$import->prepare($draft,$draft,(int)$user['id'])];
                $_SESSION['imports'][$token]['draft']=$draft;$editing=true;
                $message='Prévia atualizada. Confira e salve.';
            }else{
                if(($_POST['autorizado']??'')!=='1')throw new RuntimeException('Confirme que o conteúdo é próprio ou que você tem autorização para usá-lo.',422);
                $data=$import->prepare($draft,$draft,(int)$user['id']);
                $id=$import->save($data,(int)$user['id']);
                unset($_SESSION['imports'][$token]);$_SESSION['notice']='Cifra importada e salva. '.($data['publicada']?'Já está disponível no aplicativo.':'Foi salva como rascunho.');
                header('Location: admin.php?song='.$id.'#musicas',true,303);exit;
            }
        }else throw new RuntimeException('Ação inválida.',400);
    }elseif($_SERVER['REQUEST_METHOD']!=='GET'){http_response_code(405);header('Allow: GET, POST');exit;}
}catch(Throwable $error){
    $status=(int)$error->getCode();$expected=!($error instanceof PDOException)&&in_array($status,[400,401,403,404,409,419,422,429,502,504],true);
    http_response_code($expected?$status:503);if($status===429)header('Retry-After: 900');
    $isError=true;$message=$expected?$error->getMessage():'Não foi possível concluir a importação. Confira a configuração e a migração do servidor.';
    error_log('Cifra Santa import error type='.get_class($error).' code='.$status.' admin='.(int)($user['id']??0));
    if($error instanceof ImportDiagnosticException)$diagnostic=$error->diagnostico;
    // Fonte recusou o acesso: sem contornar o bloqueio, abre a revisão da mesma URL para cadastro manual.
    if(($action??'')==='extract' && isset($import,$user) && $error instanceof ImportDiagnosticException
        && ($error->diagnostico['erro']['etapa']??'')==='http' && in_array($error->diagnostico['status']??0,[401,403,429,451],true)){
        try{
            $draft=$import->manualDraft((string)$_POST['url'],(int)$user['id'],$error->getMessage());
            $token=bin2hex(random_bytes(24));
            while(count($_SESSION['imports']??[])>=3)array_shift($_SESSION['imports']);
            $_SESSION['imports'][$token]=['draft'=>$draft,'expires'=>time()+1800];
            $editing=true;$message='A página não pôde ser lida automaticamente. Preencha os dados e a cifra para continuar.';
        }catch(Throwable){$draft=null;$token='';}
    }
    // Um erro de validação abre a edição para o admin corrigir o campo apontado.
    if($draft && $token!=='')$editing=true;
}
function importCsrf():void{echo '<input type="hidden" name="csrf" value="'.escape($_SESSION['csrf']??'').'">';}
/** Diagnóstico técnico real da última tentativa (somente no painel admin). */
function importDiagnostic(?array $d,bool $failed):void{
    if(!$d)return;
    $redirects=array_map(fn($r)=>$r['status'].' → '.$r['para'],$d['redirects']??[]);
    $rows=['Etapa com falha'=>isset($d['erro'])?$d['erro']['etapa'].': '.$d['erro']['detalhe']:'','URL solicitada'=>$d['url_solicitada']??'','URL final'=>$d['url_final']??'','Status HTTP'=>(string)($d['status']??'sem resposta'),'Redirects'=>$redirects?implode(' · ',$redirects):'nenhum','Content-Type'=>$d['content_type']??'','Tamanho'=>number_format((int)($d['bytes']??0),0,',','.').' bytes','Tempo'=>(int)($d['tempo_ms']??0).' ms','IP remoto'=>$d['ip']??'','Servidor'=>$d['servidor']??'','Resposta remota'=>$d['resposta']??''];
    foreach($d['parser']['deteccao']??[] as $field=>$how)$rows['Parser · '.$field]=$how;
    if(isset($d['parser']['estrutura']))$rows['Parser · estrutura']=implode(', ',array_map(fn($k,$v)=>$k.' '.$v,array_keys($d['parser']['estrutura']),$d['parser']['estrutura']));
    echo '<details class="adv diag"'.($failed?' open':'').'><summary>Diagnóstico técnico <em>· requisição e leitura da página</em></summary><dl class="found">';
    foreach($rows as $label=>$value)if($value!=='')echo '<dt>'.escape($label).'</dt><dd>'.escape($value).'</dd>';
    echo '</dl></details>';
}

if(!$user):
    adm_page_start(['title'=>'Importar cifra · Cifra Santa','user'=>null]);
    ?>
<div class="auth-brand"><?=adm_mark(68)?><h1>Importar cifra</h1><p>Área exclusiva de administradores.</p></div>
<?php adm_notice($message,$isError);?>
<div class="card empty-state"><span class="stat-ico"><?=adm_icon('shield',26)?></span><h3>Acesso restrito</h3><p>Entre no painel administrativo para importar cifras.</p><a class="btn btn-primary" href="admin.php">Entrar no painel administrativo</a></div>
<?php
    adm_page_end(false);
    return;
endif;

$val=static fn(string $key):string=>is_string($draft[$key]??null)?$draft[$key]:'';
adm_page_start(['title'=>'Importar cifra · Cifra Santa','user'=>$user,'active'=>'importar','crumb'=>'Importar cifra']);
?>
<div class="page-head">
  <div><span class="eyebrow">CIFRA SANTA · IMPORTAÇÃO</span><h1>Importar cifra</h1><p>Cole abaixo o endereço da cifra que deseja importar. O sistema identifica a página e prepara tudo para você conferir.</p></div>
  <div class="actions"><a class="btn btn-ghost" href="admin.php#musicas"><?=adm_icon('music',17)?><span>Voltar à biblioteca</span></a></div>
</div>

<?php adm_notice($message,$isError);?>
<?php importDiagnostic($diagnostic,$isError);?>

<?php if(!$draft):?>
<div class="card card-pad">
  <form method="post" class="stack" data-import-url><?php importCsrf();?><input type="hidden" name="action" value="extract">
    <label class="field"><span class="lbl">URL da cifra</span><input type="url" name="url" required maxlength="1000" autofocus placeholder="https://..." value="<?=escape(is_string($_POST['url']??null)?$_POST['url']:'')?>"></label>
    <div class="form-foot"><span class="hint">Nada é gravado antes da sua confirmação.</span><button class="btn btn-primary" type="submit" data-busy="Analisando página..."><?=adm_icon('download',17)?><span>Importar cifra</span></button></div>
  </form>
</div>
<?php else:
  $hasContent=trim($val('conteudo'))!=='';
  $info=['Título'=>$val('titulo'),'Artista'=>$val('artista'),'Tom'=>$val('tom'),'Afinação'=>$val('afinacao'),'Capotraste'=>$val('capotraste')];
?>
<form method="post" class="editor"><?php importCsrf();?><input type="hidden" name="token" value="<?=escape($token)?>">
  <div class="card card-pad stack">
    <div><span class="eyebrow"><?=$hasContent?'CIFRA ENCONTRADA':'MÚSICA IDENTIFICADA'?></span>
      <dl class="found">
        <?php foreach($info as $label=>$value):?><dt><?=escape($label)?></dt><dd<?=$value===''?' class="muted"':''?>><?=$value!==''?escape($value):'não informado'?></dd><?php endforeach;?>
      </dl>
      <div class="source-line"><?=adm_icon('link',16)?><span class="muted">Fonte:</span><a href="<?=escape($val('url_origem'))?>" target="_blank" rel="noopener noreferrer"><?=escape($val('provider_nome')?:$val('url_origem'))?></a></div>
    </div>
    <?php if($val('aviso')!==''):?><div class="callout"><?=adm_icon('shield',18)?><p><?=escape($val('aviso'))?></p></div><?php endif;?>

    <div class="field"><span class="lbl">Momento da celebração</span>
      <select name="categoria"><option value="">Escolha…</option><?php foreach(array_unique([...IMPORT_MOMENTS,...($val('categoria')!==''?[$val('categoria')]:[])]) as $moment):?><option <?=$val('categoria')===$moment?'selected':''?>><?=escape($moment)?></option><?php endforeach;?></select>
    </div>

    <details class="adv"<?=$editing?' open':''?>><summary>Editar <em>· título, artista, tom e a cifra</em></summary>
      <div class="stack">
        <div class="form-grid">
          <?php foreach(['titulo'=>'Música','artista'=>'Artista','tom'=>'Tom','afinacao'=>'Afinação','capotraste'=>'Capotraste'] as $field=>$label):?>
          <label class="field"><span class="lbl"><?=escape($label)?><?=in_array($field,['afinacao','capotraste'],true)?' <em>· opcional</em>':''?></span><input name="<?=escape($field)?>" value="<?=escape($val($field))?>" maxlength="<?=in_array($field,['titulo','artista'],true)?200:($field==='tom'?12:80)?>"<?=$field==='tom'?' placeholder="C, F#, Bm"':''?>></label>
          <?php endforeach;?>
        </div>
        <input type="hidden" name="formato" value="<?=$hasContent?'inline':'aligned'?>">
        <div class="field"><label><span class="lbl">Cifra<?=$hasContent?' <em>· formato [C]palavra</em>':' <em>· cole com os acordes acima da letra</em>'?></span><textarea name="conteudo" rows="16" maxlength="100000" spellcheck="false" data-import-content><?=escape($val('conteudo'))?></textarea></label><div class="counter js-only" id="import-counter"></div></div>
        <div><button class="btn btn-secondary" name="action" value="preview"><?=adm_icon('eye',17)?><span>Atualizar prévia</span></button></div>
      </div>
    </details>

    <div class="form-foot">
      <div class="stack">
        <label class="switch"><input type="checkbox" name="autorizado" value="1" <?=($_POST['autorizado']??'')==='1'?'checked':''?>><span class="track"></span><span>Conteúdo próprio ou autorizado<small>Confirmo que posso usar esta cifra no Cifra Santa.</small></span></label>
        <label class="switch"><input type="checkbox" name="publicada" value="1" <?=$val('publicada')==='1'?'checked':''?>><span class="track"></span><span>Publicar no aplicativo<small>Desmarcado, a cifra é salva como rascunho.</small></span></label>
      </div>
      <div class="actions">
        <button class="btn btn-ghost" name="action" value="cancel" formnovalidate>Cancelar</button>
        <button class="btn btn-primary" name="action" value="save"><?=adm_icon('check',17)?><span>Salvar cifra</span></button>
      </div>
    </div>
  </div>
  <aside class="preview" aria-label="Pré-visualização da cifra">
    <div class="preview-head"><span class="eyebrow">PRÉ-VISUALIZAÇÃO DA CIFRA</span><span class="muted">Como aparece no aplicativo</span></div>
    <div class="preview-meta"><h3><?=escape($val('titulo'))?></h3><p><?=escape($val('artista'))?></p><span class="tom-badge"><?=$val('tom')!==''?'Tom '.escape($val('tom')):'Tom não informado'?></span></div>
    <?php if($hasContent):?>
    <div class="chart" role="img" aria-label="Prévia da cifra"><?php foreach(ChartParser::preview($val('conteudo')) as [$chords,$lyric]):?><?php if($chords==='' && trim($lyric)===''):?><div class="gap"></div><?php elseif($chords==='' && preg_match('/^\[[^\]]{1,80}\]$/u',trim($lyric))):?><span class="sec"><?=escape(trim($lyric,'[] '))?></span><?php else:?><div class="row"><?php if($chords!==''):?><pre class="chords"><?=escape($chords)?></pre><?php endif;?><pre><?=escape($lyric===''?' ':$lyric)?></pre></div><?php endif;?><?php endforeach;?></div>
    <?php else:?><div class="empty-note">A cifra não foi importada desta fonte. Cole-a em “Editar” e clique em “Atualizar prévia”.</div><?php endif;?>
  </aside>
</form>
<?php endif;?>
<?php adm_page_end(true);
