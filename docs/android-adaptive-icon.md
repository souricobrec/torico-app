# TORICO — ícone Android adaptativo

13/10/2026. Branch `feature/android-adaptive-icon`. Sem deploy/publicação.

## Causa

Havia apenas PNGs legados em mipmap-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi. Não existia
mipmap-anydpi-v26/ic_launcher.xml com camadas adaptativas. A configuração do
flutter_launcher_icons não definia background/foreground. O launcher podia
enquadrar o PNG legado (com moldura já embutida) em um fundo de compatibilidade,
reduzindo o símbolo e apresentando o círculo branco relatado pelo titular.

## Recursos novos

- Fundo adaptativo sólido navy `#031226`, definido em `res/values/colors.xml`.
- Símbolo T dourado extraído deterministicamente do asset oficial, sem criar
  marca nova; removidas partes da moldura externa e do anel.
- Foreground transparente 432×432, equivalente a camada 108 dp; símbolo central
  com até 188 px, preservando os elementos essenciais na área segura de 66 dp.
- Camada monochrome com mesma silhueta para temas Android 13+. Quando o usuário
  ativa ícones temáticos, as cores são escolhidas pelo sistema, não pelo app.
- PNG legado navy/T para Android 7 (API 24/25) nas cinco densidades.
- AndroidManifest usa `@mipmap/ic_launcher` para icon e roundIcon. Activity herda
  ícone da aplicação, inclusive tarefas recentes; não houve alteração de login.

Fontes em `assets/branding/`: android-adaptive-foreground.png,
android-adaptive-monochrome.png e android-launcher-legacy.png.
Recursos em `android/app/src/main/res/`:

- mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png.
- drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png.
- drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_monochrome.png.
- mipmap-anydpi-v26/ic_launcher.xml e values/colors.xml.

Ícone Play 512×512 em store-assets/google-play/icon-512.png preservado: é asset
independente da ficha, com mesmo símbolo/identidade, não a camada adaptativa.
Não foram alterados splash, autenticação, Firebase, assinatura ou integrações.

## Regeneração Android somente

```powershell
# NODE_PATH deve apontar à instalação local de Sharp.
node tools/render_android_icons.cjs
dart run flutter_launcher_icons -f launcher_icons_android.yaml
```

Configuração dedicada sem flavor, ios:false, sem web; grava res/main.
Campos Android equivalentes em pubspec.yaml evitam retorno ao ícone legado em
futura regeneração padrão. Não executar gerador padrão iOS/web nesta missão.
Não houve mudança de versão de SDK/plugin/dependência.

## Prévia e teste no emulador

Análise sem problemas, 52 testes aprovados e AAB release concluído em 213,2 s.
APK: `build/app/outputs/apk/release-test/torico-icon-fixed-release.apk`,
63.599.950 bytes, SHA256
`102F55C84C8B4F6F4FDB331D5DF223240EDDEB447B9B7E9E060973C5F7E46CA5`.
AAB: `build/app/outputs/bundle/release/app-release.aab`, 63.875.395 bytes, SHA256
`BCA059F79149524D0E198714D604220D7283329AA66365C850A52344BBD0C2E1`.
Assinatura v2/v3 válida e mesmo certificado; minSdk24/targetSdk36, versionCode3.
XML adaptativo conferido no APK final; icon/roundIcon usam o mesmo recurso.
Pixels opacos do foreground dentro de raio 123,82 px (área segura: 132 px).

`build/icon-preview/android-icon-masks.png`: simulação local de máscaras circular,
arredondada e squircle; **não é screenshot do emulador**. Revisão visual sem
fragmentos de moldura nem fundo branco. A máscara efetiva depende do launcher.

Após instalar o APK novo sobre a mesma assinatura com `adb -s <SERIAL> install -r`:

1. Confirmar versão 1.0.0 (3) instalada, sem desinstalar/limpar dados.
2. Voltar à tela inicial e abrir gaveta de apps. Verificar T centralizado e navy.
3. Abrir TORICO e abrir visão de recentes; conferir ícone herdado.
4. Conferir tema claro/escuro e, em Android 13+, ícones temáticos ligados/desligados.
5. Se launcher mantiver cache antigo, reiniciar o emulador/launcher de forma
   normal. Não usar pm clear, wipe-data ou desinstalação sem autorização.
6. Registrar screenshots pelo controle do emulador, sem contas/dados reais.

O APK não foi instalado automaticamente nesta missão. Validar também em aparelho
físico e launchers de fabricantes; não homologar comportamento por prévia apenas.

Referência: [adaptive icons Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
