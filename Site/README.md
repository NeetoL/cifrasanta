# API e painel Cifra Santa

Requer PHP 8.1+ com `pdo_mysql`, `mbstring`, `session` e HTTPS. A hospedagem Apache deve permitir `.htaccess` e `mod_rewrite`.

## Banco

A conexão local está em `config/database.php` (ignorado pelo Git), com host `50.6.138.204`, porta 3306 e banco `luizr160_curso`. Em outra instalação, copie `config/database.example.php` e preencha os dados. O formato alternativo de ambiente aceita `DATABASE_DSN_PROD`, `DATABASE_USER_PROD` e `DATABASE_PASS_PROD`; variáveis têm prioridade sobre o arquivo local. Não há carregamento automático de `.env`.

```sh
php bin/check-database.php
php bin/migrate.php
```

A migração inicial já foi aplicada ao banco indicado nesta instalação. Ela cria nove tabelas `cifra_santa_` e não modifica as tabelas do sistema English Sam. Não há músicas, cifras ou contas de exemplo no banco.

## Publicar no English Sam

Na raiz deste repositório, prepare a pasta de publicação:

```powershell
./Site/bin/stage.ps1 -Destination C:/xampp/htdocs/cifrasanta
```

Envie **a pasta `cifrasanta` inteira**, inclusive `.htaccess`, `config/database.php` e `config/install.php`, para `public_html/cifrasanta` na hospedagem. O `stage.ps1` copia somente os arquivos de execução (painel, `assets/admin.css`, `assets/admin.js`, `app/Views/admin/kit.php`, `app/Import` e a API); scripts de migração, testes, documentação e a chave de instalação em texto não são publicados. Essa pasta não altera os arquivos existentes do English Sam.

### Importar cifra por URL

No painel, **Importar cifra** pede só a URL. O `ProviderResolver` escolhe o provedor pelo domínio: sites com leitura dedicada em `config/import-providers.php` (opcional, mantido pelo desenvolvedor); o Cifra Club, com provedor próprio; outros catálogos de terceiros (`ProviderResolver::REFERENCE_ONLY`), dos quais vêm só título, artista, tom, afinação e capotraste, sem letra nem cifra; e qualquer outro site, com detecção automática completa (`HtmlChartParser::detect`). Nada é gravado antes de o administrador conferir a prévia, escolher o momento e confirmar que o conteúdo é próprio ou autorizado.

**Cifra Club.** `CifraClubProvider` faz o GET HTTPS (sem JavaScript, sem navegador) e `CifraClubParser` interpreta o HTML com DOM: JSON-LD, `og:title`, atributos `id`/`data-anchor`/`data-chord-name`/`data-tuning` e rótulos visíveis, cada campo com fallback; as classes CSS do site (hashes de build) não são usadas. A cifra sai no formato `[C]palavra` com colunas, linhas em branco, seções e tablaturas preservadas. A letra e a cifra têm direitos autorais: por padrão só os dados da música são importados. Para importar o conteúdo de uma fonte com autorização, o desenvolvedor registra a referência em `config/import-providers.php`: `'cifraclub' => ['authorization' => '...']`.

**Diagnóstico.** Cada tentativa mostra no painel (em "Diagnóstico técnico") e grava no log do PHP: URL solicitada e final, redirects, status HTTP, Content-Type, bytes, tempo, IP, erro de DNS/TLS/timeout/rede e qual estratégia do parser encontrou cada campo. Erros do servidor remoto aparecem com o status real (ex.: `HTTP 403`), sem mensagem genérica, e com um trecho do texto da resposta (onde fica, por exemplo, o "Reference #" de um bloqueio da Akamai). Se a fonte negar o acesso (401, 403, 429 ou 451), o bloqueio não é contornado: a tela abre a revisão da mesma URL para cadastro manual, com título e artista sugeridos pelo endereço.

A antiga tela "Fontes autorizadas" foi removida: `admin-fontes.php` agora só redireciona. Na hospedagem, apague `app/Import/SourceStore.php` e `app/Import/ProviderRegistry.php` se ainda existirem (o `stage.ps1` copia arquivos, mas não remove). A tabela `cifra_santa_importacao_fonte` deixou de ser usada e pode ser descartada.

Se a hospedagem exigir `localhost` para o MySQL local, ajuste somente o host em `config/database.php` no servidor. Mantenha o nome `luizr160_curso`. Se houver um proxy HTTPS, configure o servidor para reconhecer HTTPS; não aceite cabeçalhos de proxy sem uma lista de proxies confiáveis.

Endereços após a publicação:

- Painel: https://www.englishsam.com.br/cifrasanta/admin.php
- Catálogo: https://www.englishsam.com.br/cifrasanta/api.php?route=catalog

O endpoint de catálogo deve responder HTTP 200 com listas vazias até a primeira publicação. A pasta local do XAMPP não é uma publicação na internet.

## Primeiro administrador

A chave desta instalação fica em `../admin-install-key.txt`, fora de `Site` e ignorada pelo Git. Abra o painel, informe essa chave e escolha seu nome, e-mail e senha (mínimo 10 caracteres). Não envie o arquivo de chave à hospedagem.

Para outra instalação sem chave, execute `php bin/create-install-key.php`. O comando não substitui uma chave já existente. O arquivo `config/install.php` contém apenas seu hash. Depois de existir um administrador, o formulário inicial é desativado. O primeiro administrador ainda precisa ser escolhido pelo responsável pelo sistema.

No painel:

1. Cadastre título, artista, momento e tom da música.
2. Escreva a cifra com acordes entre colchetes: `[C]Sua letra [G]continua`.
3. Marque **Publicar no aplicativo** ou salve como rascunho.
4. Monte repertórios usando os IDs das músicas na ordem desejada.
5. No aplicativo, toque em **Atualizar catálogo** para receber as mudanças.

## Desenvolvimento e testes

```sh
php -S 127.0.0.1:8097 -t Site
```

O comando acima parte da raiz do repositório. Abra `http://127.0.0.1:8097/admin.php`. O servidor embutido é somente para desenvolvimento local; em produção use Apache com o `.htaccess` fornecido para bloquear as pastas internas.

Com o servidor local ativo:

```sh
php Site/tests/integration.php --allow-configured-database
```

O teste cria contas e conteúdo identificados por sufixo aleatório nas tabelas configuradas e os remove ao final, inclusive em caso de falha. Valida autenticação, autorização, CSRF, publicações, rascunhos, favoritos isolados e revogação. Não execute contra um banco diferente sem revisar sua configuração.

Testes da importação: `php Site/tests/import-cifraclub.php` (parser Cifra Club offline, HTML → DTO; `CIFRACLUB_SAMPLE=/caminho/pagina.html` valida também uma página salva localmente, fora do Git) e `php Site/tests/import-parser.php [--network]`. Os testes `import-service.php` e `import-http.php` gravam no banco configurado; use `DATABASE_DSN_PROD`/`DATABASE_USER_PROD`/`DATABASE_PASS_PROD` para apontá-los a um banco local e `TEST_BASE_URL` para o servidor. Com o servidor iniciado com `CIFRA_IMPORT_PROVIDER_CONFIG=Site/tests/import-providers-blocked.fixture.php`, `TEST_BLOCKED_URL=https://httpbin.org/status/403` testa também o fluxo de bloqueio.

Veja `API.md` para o contrato completo e a estrutura das tabelas. Os arquivos MVC anteriores em `app/Views` e `app/Models` não são usados nem publicados por esta API/painel.
