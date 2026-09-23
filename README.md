# Cifra Santa

O projeto está organizado em duas partes:

- **Site/** — versão web em PHP 8, com rotas MVC e dados locais.
- **Aplicativo/** — projeto Flutter nativo para Android e iOS. Funciona de forma independente do PHP, com catálogo demonstrativo local e favoritos guardados no aparelho.

Ambas as versões usam a identidade Cifra Santa. O aplicativo é o foco da experiência no celular. Não há banco de dados, cadastro ou sincronização entre as duas versões nesta etapa.

## Experimentar

O **Site** pode ser publicado na hospedagem PHP conforme `Site/README.md`.

O **Aplicativo** é compilado com Flutter. Consulte `Aplicativo/README.md` para gerar APK, AAB e IPA. A interface é feita com widgets Flutter, sem WebView.

O arquivo **CifraSanta-Android-teste.apk** já está pronto para instalar e testar em um Android. É uma build de teste; a publicação em lojas precisa de uma chave de lançamento própria. O projeto iOS está incluído no mesmo código, mas a build para iPhone precisa ser feita em um Mac com Xcode.

O catálogo demonstrativo é armazenado no próprio código e funciona sem conexão.

## Próxima etapa

Para publicar na Google Play ou na Galaxy Store, será necessário definir o identificador final do pacote, assinar a build e preparar os materiais da loja. Para a App Store, a build iOS exige macOS com Xcode e uma equipe Apple configurada.

As músicas conhecidas aparecem no aplicativo apenas com título e metadados. O leitor mostra letra e acordes originais de demonstração, identificados como tal.
