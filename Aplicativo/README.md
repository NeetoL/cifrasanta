# Cifra Santa — aplicativo Android e iOS

Projeto **Flutter** com interface nativa, sem WebView e sem dependência do site PHP. O mesmo código Dart atende Android e iOS. Catálogo e repertórios são dados locais de demonstração; favoritos são guardados no aparelho.

## Telas e recursos

- Início, busca por música/artista/momento, favoritos e repertórios.
- Leitor com transposição, ajuste de texto e rolagem automática.
- Identidade original com cruz, igreja, cálice, pomba, caminho e livro desenhados no próprio Flutter.
- Cifras conhecidas aparecem apenas com títulos e metadados. O leitor usa texto e acordes originais de demonstração.

## APK para testar no Android

O arquivo `../CifraSanta-Android-teste.apk` já foi compilado. É um **APK de teste**, assinado com a chave de depuração do Flutter. Copie o arquivo para um celular Android, abra-o no gerenciador de arquivos e permita a instalação pelo aplicativo usado para abrir o APK quando o Android solicitar. Ele funciona sem o site PHP e sem conexão para o catálogo demonstrativo.

Este pacote ainda não é uma publicação de loja. A Google Play e a Galaxy Store exigem configuração de assinatura de lançamento e materiais próprios da loja.

## Desenvolvimento

Requer Flutter 3.47 ou superior, Android SDK e JDK 17 ou superior. Na pasta `Aplicativo`:

```bash
flutter pub get
flutter test
flutter run
flutter build apk --debug
```

O APK gerado fica em `build/app/outputs/flutter-apk/`. Para publicar no Android, configure uma chave de lançamento privada no Gradle e depois gere `flutter build appbundle --release`. Para iOS, abra este mesmo projeto em um Mac com Xcode, configure a equipe Apple e execute `flutter build ipa`.

O identificador atual é `com.cifrasanta.app`; confirme que será o definitivo antes da publicação. Nenhuma chave privada de lançamento é incluída neste projeto. O código iOS foi preparado, mas a compilação iOS não foi executada neste computador Windows.
