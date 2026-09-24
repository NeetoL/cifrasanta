# API Cifra Santa

Base de publicação: `https://www.englishsam.com.br/cifrasanta/api.php`.
Todas as rotas usam o parâmetro `route`. Escritas recebem `Content-Type: application/json`. Respostas são JSON UTF-8. A API exige HTTPS, com exceção de acesso local por loopback. Não há acesso MySQL direto no aplicativo.

| Método | Rota | Autenticação | Finalidade |
| --- | --- | --- | --- |
| GET | `?route=catalog` | Pública | Cifras e repertórios publicados |
| POST | `?route=register` | Pública | Criar conta comum |
| POST | `?route=login` | Pública | Entrar na conta |
| GET | `?route=me` | Bearer | Consultar a conta atual |
| POST | `?route=logout` | Bearer | Revogar o token atual |
| GET | `?route=favorites` | Bearer | Consultar favoritos da conta |
| PUT | `?route=favorites` | Bearer | Adicionar ou remover favorito |
| GET | `?route=bible&livro=gn` | Bearer + `admin` | Capítulos existentes do livro |
| GET | `?route=bible&livro=gn&capitulo=1` | Bearer + `admin` | Versículos do capítulo |

## Conta e favoritos

Cadastro: `{"nome":"Seu nome","email":"voce@example.com","senha":"sua-senha-de-10-ou-mais-caracteres"}`.

Login: `{"email":"voce@example.com","senha":"sua-senha"}`.

Cadastro e login devolvem `{"token":"...","usuario":{"id":"1","nome":"...","email":"...","papel":"usuario"}}`. Envie `Authorization: Bearer TOKEN` nas chamadas protegidas. O token expira em 30 dias; o banco armazena apenas seu hash, e tokens vencidos da conta são apagados a cada novo login. O aplicativo guarda o token no armazenamento do próprio app e confirma a sessão com `me` ao abrir.

Escritas devem informar `Content-Length`. O Mod_Security da hospedagem recusa corpo em `Transfer-Encoding: chunked` com HTTP 406 e página HTML. Senhas usam `password_hash`/`password_verify`.

Favorito: `{"songId":"1","favorite":true}`. Use `false` para remover. A operação é idempotente; a resposta contém a lista atual em `favorites`. O ID do usuário vem da autenticação, nunca do corpo da requisição.

Logout recebe `{}`. Um token revogado ou uma conta desativada recebe HTTP 401 nas próximas chamadas.

## Bíblia

A tradução importada (Ave-Maria) não tem licença de distribuição, por isso a rota `bible` só atende contas com papel `admin`; outras contas recebem 403. `livro` usa os IDs de `Aplicativo/assets/data/biblia_catolica_canone.json` (`gn`, `jo`, `1cor`…).

- Sem `capitulo`: `{"livro":"gn","capitulos":[1,2,...]}`. A lista traz só os capítulos que existem no banco.
- Com `capitulo`: `{"livro":"gn","capitulo":1,"versiculos":[{"numero":1,"texto":"..."}]}`.

O texto é carregado por `php bin/import-biblia.php caminho/biblia.json`, que cria as tabelas pela migração `002_biblia` na primeira vez e substitui todo o conteúdo a cada execução. O JSON fica fora do repositório.

## Catálogo

```json
{
  "songs": [
    {"id":"1","title":"Título cadastrado","artist":"Artista cadastrado","category":"Entrada","originalKey":"C","chart":"[C]Texto cadastrado [G]continua"}
  ],
  "repertoires": [
    {"id":"1","title":"Celebração","subtitle":"Descrição","songIds":["1"]}
  ]
}
```

O exemplo acima documenta o contrato e não é inserido no banco. Um banco vazio devolve listas vazias. Rascunhos não aparecem, inclusive dentro de repertórios. IDs são strings no contrato. Os acordes ficam entre colchetes no texto, imediatamente antes da sílaba correspondente. O leitor separa acordes e letras e transpõe o tom, incluindo acordes com baixo.

## Administração

`admin.php` é a interface para criar/editar músicas, cifras e repertórios e publicá-los ou recolocá-los em rascunho. Suas escritas usam sessão PHP, papel `admin`, validação de campos e CSRF. O cadastro público da API sempre cria `usuario`, mesmo que o cliente envie outro papel.

O primeiro administrador é criado no próprio painel com nome, e-mail, senha e chave de instalação. A chave é entregue separadamente em `admin-install-key.txt`; o servidor guarda somente seu hash. O cadastro inicial deixa de aceitar novas contas assim que existe um administrador. A criação inicial usa bloqueio no banco para evitar duas inicializações simultâneas.

## Respostas de erro

Erros têm formato `{"error":"Mensagem"}`. Códigos: 400 JSON inválido; 401 sessão ausente/inválida; 403 HTTPS obrigatório ou acesso proibido; 404 recurso ausente; 405 método incorreto; 409 conflito de cadastro; 413 corpo excessivo; 415 tipo de conteúdo incorreto; 422 campos inválidos; 429 limite de tentativas; 503 indisponibilidade do servidor. Erros do driver e credenciais não são devolvidos ao cliente.

Login tem limites por endereço de origem e e-mail, em janelas de 15 minutos. Cadastro tem limite por origem. Não há envio de e-mail nem recuperação automática de senha nesta versão.

## Estrutura do banco

- `cifra_santa_usuario`: contas e papéis.
- `cifra_santa_musica`: título, artista, categoria e autoria do cadastro.
- `cifra_santa_cifra`: uma cifra por música, com tom, conteúdo e publicação.
- `cifra_santa_favorito`: relação única entre usuário e música.
- `cifra_santa_repertorio`: sequências publicadas pelo administrador.
- `cifra_santa_repertorio_musica`: músicas e ordem de cada repertório.
- `cifra_santa_token`: sessões da API, com hash e validade.
- `cifra_santa_limite_acesso`: controle de tentativas de acesso.
- `cifra_santa_migracao`: histórico e checksum da instalação.
- `cifra_santa_biblia_livro`: os 73 livros, com o mesmo ID do aplicativo, ordem, abreviação e testamento.
- `cifra_santa_biblia_versiculo`: texto por livro, capítulo e versículo.

O arquivo `database/001_initial.sql` cria apenas essas tabelas. `bin/migrate.php` recusa tabelas com esse prefixo sem histórico compatível e é idempotente após a instalação. DDL do MySQL não é transacional: se uma instalação nova falhar parcialmente, revise antes de reaplicar. Não edite uma migração já aplicada; crie uma nova para futuras mudanças.

## Listas pessoais

`GET ?route=playlists`, com Bearer, retorna `{ "playlists": [{ "id": "...", "title": "...", "version": 1, "songIds": ["5"] }] }`, somente da conta autenticada.

`POST ?route=playlists` com JSON `{ "action": "save", "title": "Domingo", "songIds": ["5", "6"] }` cria uma lista. Para editar, envie também `id` e `version`. Para excluir, envie `{ "action": "delete", "id": "...", "version": 1 }`. As respostas retornam as listas atualizadas da conta. Versão obsoleta retorna 409; acesso a uma lista de outra conta retorna 404. Listas não integram o catálogo público.

Migração: `php bin/migrate-playlists.php`. Validação HTTP: inicie `php -S 127.0.0.1:8101 -t Site` na raiz do projeto e execute `php Site/tests/playlists.php`. O teste cria e remove contas e listas temporárias. O endereço pode ser configurado por `CIFRA_TEST_API`.
