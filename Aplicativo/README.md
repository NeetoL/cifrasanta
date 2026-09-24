# Cifra Santa — Android e iOS

Aplicativo Flutter nativo com catálogo, cifras e repertórios recebidos da API PHP/MySQL. Não há catálogo demonstrativo nem acesso direto ao MySQL. Credenciais de banco não são incluídas na compilação.

## Recursos

- Catálogo remoto com atualização, carregamento, erro de conexão e estado vazio.
- Busca por nome, artista e categoria.
- Leitura das cifras cadastradas no painel, transposição de acordes e baixos, tamanho do texto e rolagem.
- Cadastro/login de usuários e favoritos salvos por conta no banco.
- Repertórios publicados pelo administrador, preservando a ordem das músicas.

O catálogo público dispensa conta. O token de login fica somente em memória; após encerrar o aplicativo é necessário entrar novamente para acessar favoritos. Os favoritos persistem no servidor. Sem internet não há download inicial do catálogo; uma cifra já aberta permanece disponível durante a sessão.

## Plataforma católica

O aplicativo tem menu lateral (`lib/ui/navigation/`) e uma casca única (`lib/ui/app_shell.dart`) que troca a área atual sem empilhar telas; o botão voltar retorna ao Início.

- **Início**: liturgia de hoje (mesmo repositório e cache da tela de Liturgia), acessos rápidos, palavra do dia, continue de onde parou, cifras em destaque, oração do dia e igrejas apoiadoras (seções sem dados reais não aparecem).
- **Orações** e **Santo Terço**: conteúdo em `assets/data/oracoes.json` e `assets/data/terco.json`. Novas orações entram apenas no JSON.
- **Calendário Litúrgico**: escolhe uma data e abre a Liturgia daquele dia.
- **Favoritos**: cifras (conta) e orações/versículos/leituras (aparelho, `LocalFavoritesStore`).
- **Igrejas Apoiadoras**: modelo e `ChurchRepository` prontos; sem igrejas cadastradas a tela mostra um estado vazio. Basta implementar o repositório (API, banco ou Firebase).

### Limitações conhecidas

- **Bíblia Católica**: a estrutura dos 73 livros está pronta (`biblia_catolica_canone.json`), mas nenhum texto foi integrado, pois não foi verificada uma tradução católica completa com licença de uso. Para habilitar, implemente `BibleTextSource` (`lib/core/bible.dart`) e passe em `AppServices`.
- **Santo do Dia**: sem fonte confiável e licenciada verificada; a tela informa isso. Implemente `SaintRepository` (`lib/core/saints.dart`) para habilitar.

## Servidor

Endereço padrão: `https://www.englishsam.com.br/cifrasanta/api.php`. Publique primeiro a pasta do servidor seguindo `../Site/README.md`. O endereço é definido na compilação, sem permitir HTTP em builds de lançamento.

## Desenvolver e compilar

Validado com Flutter 3.47.5 / Dart 3.13.4. Android requer Android SDK e Java 17 ou superior; iOS requer Mac com Xcode.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

Para outro servidor HTTPS:

```sh
flutter build apk --debug --dart-define=API_BASE_URL=https://seu-dominio/cifrasanta/api.php
```

O APK fica em `build/app/outputs/flutter-apk/app-debug.apk`. Nenhum APK antigo de demonstração recebe essas alterações automaticamente: é necessário recompilar. O identificador Android é `com.cifrasanta.app`. Para lojas, configure assinatura de lançamento e gere `flutter build appbundle --release`; para iOS configure a equipe Apple antes de `flutter build ipa`.

## Testes

Os testes usam respostas controladas da API, somente no diretório `test`. Conferem catálogo vazio/remoto, erro e recuperação de conexão, autenticação para favoritos, falhas sem atualização falsa da interface, navegação com mais de três repertórios e transposição do conteúdo cadastrado. Os testes completos do backend ficam em `../Site/tests`.

## APK de teste 0.2.0

A compilação desta versão está em `../dist/CifraSanta-0.2.0-teste.apk`, assinada para testes, com suporte a Android 7+ e às arquiteturas ARM, ARM64 e x86_64. Usa a API de produção. O checksum SHA-256 acompanha o arquivo em `dist` (artefatos ignorados pelo Git).

O novo ícone tem fonte vetorial em `design/cifra-santa-icon.svg`, versões adaptativa e temática no Android e tamanhos de ícone para iOS. A abertura Android acompanha o tema escuro.

## Correção do leitor — 0.2.1

A cifra se ajusta à largura do celular e mantém somente a rolagem vertical. Linhas longas são divididas junto com os acordes, preservando a sequência, a letra e o alinhamento. O ajuste considera o tamanho de texto escolhido e a escala de acessibilidade do aparelho.

APK atualizado: `../dist/CifraSanta-0.2.1-teste.apk`. Instale como atualização da versão 0.2.0; atualizar apenas o catálogo não altera a interface do leitor.

## Leitura e busca — 0.2.2

O texto da cifra começa em 12 e permite ajustes de 8 a 28. Puxe a lista para baixo a partir do topo para atualizar o catálogo; o botão de atualização foi removido. Uma falha nessa atualização preserva o catálogo já carregado e a consulta aberta.

A busca vazia mostra somente as últimas dez músicas abertas pela busca, sem duplicatas, salvas no aparelho entre sessões. Digitar filtra o catálogo completo; selecionar um momento mostra a categoria correspondente. Os momentos incluem as partes da missa, adoração e louvor, com equivalência entre Oferta/Ofertório e Envio/Final.

APK: `../dist/CifraSanta-0.2.2-teste.apk`. Instale por cima da versão anterior. Os testes também verificam persistência e limite do histórico, atualização por gesto, filtros e os limites do texto.

## Tela inteira, listas pessoais e login — 0.3.0

Na cifra, o botão de tela inteira abre somente a cifra e um botão para voltar. Mantém o tom transposto e o tamanho de texto, com rolagem vertical. No Android, a integração nativa oculta as barras do sistema e as restaura ao sair.

A aba Listas permite criar, renomear, selecionar/remover músicas, ordenar e excluir listas. Listas criadas sem conta ficam no aparelho. Listas criadas com login ficam privadas na conta; as listas locais continuam separadas e não são enviadas automaticamente. O editor protege contra troca de conta e edições concorrentes. Máximo de 100 listas e 100 músicas por lista.

O cliente envia o tamanho do JSON explicitamente para ser aceito pela hospedagem. Falha ao carregar favoritos após autenticação não desfaz um login válido. Cadastro/login foram verificados em produção com conta temporária, removida ao final.

Instalador: `../dist/CifraSanta-0.3.0-teste.apk`. A API precisa da atualização `../dist/CifraSanta-API-0.3.0.zip` para habilitar listas na conta. As tabelas da migração `003_playlists` já foram criadas no banco configurado. Listas locais e tela inteira não dependem dessa publicação.
