# TORICO — ícone Android adaptativo

13/10/2026. Branch `feature/android-official-icon`. Sem deploy/publicação.

## Causa

Havia apenas PNGs legados em mipmap-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi. Não existia
mipmap-anydpi-v26/ic_launcher.xml com camadas adaptativas. A configuração do
flutter_launcher_icons não definia background/foreground. O launcher podia
enquadrar o PNG legado (com moldura já embutida) em um fundo de compatibilidade,
reduzindo o símbolo e apresentando o círculo branco relatado pelo titular.

A primeira tentativa adaptativa isolou o T e removeu o anel, descaracterizando
a marca. Esta revisão substitui essa extração pela arte oficial **completa**.

## Recursos novos

- Fundo adaptativo sólido navy `#031226`, definido em `res/values/colors.xml`.
- Fonte escolhida: `assets/images/app_icon.png`, 1254×1254, 2.262.445 bytes.
  É o ícone oficial aprovado; a logo horizontal não foi usada como ícone.
- Foreground 432×432 (108 dp): arte completa reduzida para 208×208, centralizada.
  Preserva quadrado arredondado navy, anel dourado, T, brilho e textura. Apenas
  os cantos externos recebem transparência seguindo o contorno arredondado;
  não há recorte interno, isolamento do T ou remoção do anel.
- Camada monochrome mantém contornos dourados completos, incluindo anel e T,
  em vez de apenas a letra ou um quadrado opaco. Quando ícones temáticos são
  ativados no Android 13+, as cores são escolhidas pelo sistema, não pelo app.
- PNG legado usa a arte oficial inteira, reduzida para Android 7 (API24/25)
  nas cinco densidades. Não foi criada moldura branca externa.
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

Registro histórico da tentativa anterior (T isolado, substituída): análise sem
problemas, 52 testes e AAB concluído em 213,2 s. Não usar esse APK para a marca final.
APK: `build/app/outputs/apk/release-test/torico-icon-fixed-release.apk`,
63.599.950 bytes, SHA256
`102F55C84C8B4F6F4FDB331D5DF223240EDDEB447B9B7E9E060973C5F7E46CA5`.
AAB: `build/app/outputs/bundle/release/app-release.aab`, 63.875.395 bytes, SHA256
`BCA059F79149524D0E198714D604220D7283329AA66365C850A52344BBD0C2E1`.
Assinatura v2/v3 válida e mesmo certificado; minSdk24/targetSdk36, versionCode3.
XML adaptativo conferido no APK final; icon/roundIcon usam o mesmo recurso.
Os dados acima pertencem ao build anterior; os novos artefatos são registrados
na seção Resultado oficial completo ao final deste documento.

`build/icon-preview/android-icon-official-masks.png`: simulação local de máscaras circular,
arredondada e squircle; **não é screenshot do emulador**. Revisão visual sem
perda do anel/T/brilho nem fundo branco. A máscara efetiva depende do launcher;
o quadrado da marca fica dentro da máscara do sistema, sem tentar forçá-la.

Após instalar `torico-icon-official-release.apk` sobre a mesma assinatura com
`adb -s <SERIAL> install -r`:

1. Confirmar versão 1.0.0 (4) instalada, sem desinstalar/limpar dados.
2. Voltar à tela inicial e abrir gaveta de apps. Verificar ícone completo com
   quadrado navy, anel dourado, T e brilho, sem círculo branco externo.
3. Abrir TORICO e abrir visão de recentes; conferir ícone herdado.
4. Conferir tema claro/escuro e, em Android 13+, ícones temáticos ligados/desligados.
5. Se launcher mantiver cache antigo, reiniciar o emulador/launcher de forma
   normal. Não usar pm clear, wipe-data ou desinstalação sem autorização.
6. Registrar screenshots pelo controle do emulador, sem contas/dados reais.

O APK não foi instalado automaticamente nesta missão. Validar também em aparelho
físico e launchers de fabricantes; não homologar comportamento por prévia apenas.

Referência: [adaptive icons Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

## Resultado oficial completo — versão 1.0.0 (4)

- flutter analyze: sem problemas; flutter test: **52 aprovados**.
- AAB release concluído em 102,3 s, 64.030.243 bytes:
  `build/app/outputs/bundle/release/app-release.aab`.
- SHA256 AAB: `D8EB605167898BD13107BB6398093D62CF3B38C8C52649688F6229079B6D287D`.
- APK: `C:/Users/CRZ/Documents/ChatGPT/TORICO/build/app/outputs/apk/release-test/torico-icon-official-release.apk`.
- Tamanho APK: 63.751.502 bytes.
- SHA256 APK: `A607865A0F15FB78F05E2E2116A734C3F09E915E58E5AE1A6FD89C6380CE4C1B`.
- APKS: `build/app/outputs/bundle/release/torico-icon-official-release.apks`.
- Package br.com.meutorico.app; minSdk24/targetSdk36; versionCode4.
- APK v2/v3 válido, mesmo certificado de upload; XML adaptativo presente no APK.
- Foreground opaco dentro de raio 129,47 px, menor que raio seguro de 132 px.
- Legacy 512×512 com pixels idênticos ao ícone Play aprovado, verificado sem
  alterar o asset da ficha. Anel, T e reflexão preservados na prévia das três máscaras.
- Backup do AAB versão3 em `build/android-release-backups/pre-official-icon/`.

Arquivos alterados: 5 mipmaps legados, 5 foregrounds e 5 monochromes nas densidades
mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi, 3 fontes PNG em assets/branding, gerador
tools/render_android_icons.cjs e os documentos android-adaptive-icon.md e
google-play-submission-pack.md. Fundo navy, XML adaptativo e roundIcon existentes
foram mantidos, pois já apontam corretamente às novas camadas. Configuração de
login, assinatura, Firebase, serviços e páginas legais não foi alterada.
Nenhum APK/AAB versionado ou publicado. Instalação/validação no launcher ainda
pendente; não desinstalar nem apagar dados para substituir a versão anterior.
