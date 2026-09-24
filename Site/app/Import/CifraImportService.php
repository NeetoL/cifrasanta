<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use CifraSanta\Core\Service;
use PDO;
use RuntimeException;

final class CifraImportService {
    private Service $service;
    public function __construct(private PDO $db, private ProviderResolver $resolver=new ProviderResolver()) {$this->service=new Service($db);}
    public function requireAdmin(int $id): array {
        $user=$this->service->query("SELECT id,nome FROM cifra_santa_usuario WHERE id=? AND papel='admin' AND ativo=1",[$id])->fetch();
        if(!$user)throw new RuntimeException('Acesso exclusivo de administradores.',403);
        return $user;
    }
    /** URL → provedor → download → detecção. Nada é gravado aqui. */
    public function identify(string $url,int $adminId):array {
        $this->requireAdmin($adminId);
        $provider=$this->resolver->resolve($url);
        $url=$provider->normalizeUrl($url);
        $this->duplicate($url);
        $this->service->throttle('import-identify:'.$adminId,30);
        $draft=$provider->extract($url);
        $this->duplicate($draft['url_origem']);
        return $draft;
    }
    /**
     * A fonte recusou o acesso (ex.: HTTP 403): rascunho vazio da mesma URL para o admin preencher à mão.
     * Título e artista são só sugestões tiradas do endereço (".../artista/musica/") e ficam editáveis.
     */
    public function manualDraft(string $url,int $adminId,string $reason):array {
        $this->requireAdmin($adminId);
        $provider=$this->resolver->resolve($url);
        $url=$provider->normalizeUrl($url);
        $this->duplicate($url);
        $segments=array_values(array_filter(explode('/',(string)parse_url($url,PHP_URL_PATH)),static fn($s)=>preg_match('/^[a-z0-9-]{2,120}$/',$s)===1 && preg_match('/[a-z]/',$s)===1));
        $guess=static function(string $slug):string{
            $words=explode(' ',str_replace('-',' ',$slug));
            foreach($words as $i=>$word)$words[$i]=$i>0 && in_array($word,['a','o','as','os','e','de','da','do','das','dos','em','na','no','pela','pelo','para','com'],true)?$word:mb_convert_case($word,MB_CASE_TITLE,'UTF-8');
            return implode(' ',$words);
        };
        $count=count($segments);
        return ['url_origem'=>$url,'provider'=>$provider->id(),'provider_nome'=>$provider->name(),
            'titulo'=>$count>=1?$guess($segments[$count-1]):'','artista'=>$count>=2?$guess($segments[$count-2]):'',
            'tom'=>'','capotraste'=>'','afinacao'=>'','conteudo'=>'','formato'=>'inline','categoria'=>'','publicada'=>'',
            'aviso'=>$reason.' Título e artista foram sugeridos pelo endereço: confira, informe o tom e cole a cifra de uma fonte própria ou autorizada em "Editar".'];
    }
    private const LABELS=['titulo'=>'Música','artista'=>'Artista','categoria'=>'Momento','tom'=>'Tom','capotraste'=>'Capotraste','afinacao'=>'Afinação'];
    public function prepare(array $draft,array $input,int $adminId):array {
        $this->requireAdmin($adminId);
        $data=['url_origem'=>$draft['url_origem'],'provider'=>$draft['provider']];
        foreach(['titulo'=>200,'artista'=>200,'categoria'=>80,'tom'=>12,'capotraste'=>80,'afinacao'=>80] as $key=>$max){
            $optional=in_array($key,['capotraste','afinacao'],true);
            $value=$input[$key]??'';
            if(!is_string($value))throw new RuntimeException('Campo inválido: '.self::LABELS[$key].'.',422);
            $value=trim($value);
            if(!$optional && $value==='')throw new RuntimeException($key==='categoria'?'Escolha o momento da celebração.':'Informe o campo "'.self::LABELS[$key].'" em Editar.',422);
            if(mb_strlen($value)>$max)throw new RuntimeException('O campo "'.self::LABELS[$key].'" passou de '.$max.' caracteres.',422);
            $data[$key]=$value;
        }
        if(!preg_match('/^[A-G](?:#|b)?m?$/D',$data['tom']))throw new RuntimeException('Informe um tom válido em Editar: C, F#, Bm...',422);
        $content=$input['conteudo']??'';
        if(!is_string($content))throw new RuntimeException('Cifra inválida.',422);
        if(trim($content)==='')throw new RuntimeException('A cifra está vazia. Cole a cifra em "Editar" antes de salvar.',422);
        $format=$input['formato']??'inline';
        $data['conteudo']=ChartParser::normalize($content,is_string($format)?$format:'');
        $data['formato']='inline';$data['publicada']=($input['publicada']??'')==='1'?'1':'';
        return $data;
    }
    private function duplicate(string $url,?array $data=null):void {
        if($this->service->query('SELECT musica_id FROM cifra_santa_importacao WHERE url_hash=?',[hash('sha256',$url)])->fetchColumn())throw new RuntimeException('Esta cifra já está cadastrada.',409);
        if($data && $this->service->query('SELECT id FROM cifra_santa_musica WHERE titulo=? AND artista=?',[$data['titulo'],$data['artista']])->fetchColumn())throw new RuntimeException('Já existe uma música com este título e artista. Edite o cadastro existente.',409);
    }
    public function save(array $data,int $adminId):int {
        $this->requireAdmin($adminId);
        // Revalida também chamadas diretas do serviço.
        $provider=$this->resolver->resolve((string)($data['url_origem']??''));
        $source=['url_origem'=>$provider->normalizeUrl($data['url_origem']),'provider'=>$provider->id()];
        if(empty($data['publicada']))unset($data['publicada']);
        $data=$this->prepare($source,$data,$adminId);
        $this->service->throttle('import-save:'.$adminId,30);
        if((int)$this->db->query("SELECT GET_LOCK('cifra_santa_import_save',5)")->fetchColumn()!==1)throw new RuntimeException('Outra importação está sendo salva. Tente novamente.',409);
        try {
            $this->db->beginTransaction();
            try {
                $this->duplicate($data['url_origem'],$data);
                $this->service->query('INSERT INTO cifra_santa_musica(titulo,artista,categoria,criado_por) VALUES(?,?,?,?)',[$data['titulo'],$data['artista'],$data['categoria'],$adminId]);
                $id=(int)$this->db->lastInsertId();
                $this->service->query('INSERT INTO cifra_santa_cifra(musica_id,tom,conteudo,publicada) VALUES(?,?,?,?)',[$id,$data['tom'],$data['conteudo'],$data['publicada']==='1'?1:0]);
                $this->service->query('INSERT INTO cifra_santa_importacao(musica_id,url_origem,url_hash,provider,capotraste,afinacao,conteudo_hash,criado_por) VALUES(?,?,?,?,?,?,?,?)',[$id,$data['url_origem'],hash('sha256',$data['url_origem']),$data['provider'],$data['capotraste'],$data['afinacao'],hash('sha256',$data['conteudo']),$adminId]);
                $this->db->commit();
                error_log('Cifra Santa import saved admin='.$adminId.' song='.$id);
                return $id;
            }catch(\Throwable $e){if($this->db->inTransaction())$this->db->rollBack();if($e instanceof \PDOException && ($e->errorInfo[1]??0)===1062)throw new RuntimeException('Esta cifra já está cadastrada.',409);throw $e;}
        }finally{$this->db->query("SELECT RELEASE_LOCK('cifra_santa_import_save')");}
    }
}
