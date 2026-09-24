# Cifra Santa

Aplicativo Flutter de cifras, conectado a uma API PHP/MySQL, com painel administrativo web.

- **Aplicativo/**: catálogo remoto, busca, leitor com transposição, rolagem, contas e favoritos sincronizados.
- **Site/**: API, painel de cadastro de músicas/cifras/repertórios e estrutura do banco.

O aplicativo não contém músicas ou repertórios demonstrativos. O catálogo começa vazio e é alimentado pelo painel. A conta é necessária para favoritos; consultar cifras publicadas é livre.

## Instalação

O banco configurado é `luizr160_curso`, com tabelas exclusivas prefixadas por `cifra_santa_`. As credenciais ficam em arquivos locais ignorados pelo Git. Não são incluídas no aplicativo.

Consulte [Site/README.md](Site/README.md) para publicar o servidor e criar o primeiro administrador; [Site/API.md](Site/API.md) documenta as rotas e as tabelas. A compilação e os testes do aplicativo estão em [Aplicativo/README.md](Aplicativo/README.md).

A pasta `C:\xampp\htdocs\cifrasanta` pode ser preparada com `Site/bin/stage.ps1`. Envie essa pasta para a raiz pública da hospedagem English Sam para disponibilizar `/cifrasanta/admin.php` e `/cifrasanta/api.php`. Copiar para o XAMPP local não publica automaticamente na internet.
