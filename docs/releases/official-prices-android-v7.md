# TORICO — preços oficiais / Android 1.0.0 (7)

Fonte: branch `codex/official-plan-prices`, código `30dc44d` (inclui `afeed29`, identidade da conta; ícone oficial; Firebase Android e login nativo). Nenhuma alteração funcional nova além dos preços aprovados. Alterações locais antigas e arquivos gerados não foram incluídos no commit.

## Escopo autorizado

- SAGA: somente `/opt/torico-site-production/public/index.html` e `termos.html`, substituições de texto comercial. Básico R$ 24,90/mês; Plus R$ 39,90/mês, Em breve, sem contratação.
- Sem migração institucional. Raiz/www continuam no Hosting compartilhado do Firebase. `/planos` público continua sendo entregue pelo PWA, sem nova página institucional em produção.
- Nginx, Compose, DNS, proxy e certificados preservados. `nginx -t` e reload do container isolado aprovados. Rotas internas `/`, `/privacidade`, `/termos`, `/contato`, `/healthz`: 200; inexistente: 404. Apenas index e termos diferem do backup.
- Conferência visual em cópia exata dos arquivos públicos do SAGA: 1440/768/390/320 px, sem overflow horizontal, preços corretos e Plus Em breve. SSH bloqueia port-forward; não foi alterada a política. Healthcheck real foi conferido no próprio servidor, não no servidor temporário local.

## Backups e rollback

SAGA: `/opt/torico-site-production/backups/prices-v7-20261015/` contém public, nginx e docker-compose.yml. Para reverter somente os textos, restaurar index.html e termos.html de `public` para `/opt/torico-site-production/public`, validar `docker exec torico-site-production nginx -t`, depois `docker exec torico-site-production nginx -s reload`. Não restaurar configurações desnecessariamente.

Local: `.tmp-price-release/backups/` contém AAB/APK anteriores (versionCode 6), build Web anterior, firebase.json, .firebaserc, pubspec.yaml e inventário/configuração da release Hosting. Diretório não versionado; não contém cópia de keystore ou senhas.

Hosting anterior: release `sites/torico-ca479/releases/1791861693429000`, versão `sites/torico-ca479/versions/97dc2d1ac5a07198`. Rollback pelo histórico de releases do site `torico-ca479` no Firebase Hosting, escolhendo a versão anterior. Isso reverte o site compartilhado inteiro; conferir páginas legais e os hosts após rollback. Não envolve Auth/Firestore/Cloud Run.

Android: manter AAB/APK versionCode 6 no backup; esta entrega não instala nem publica nada. Para teste local, voltar ao APK anterior conforme compatibilidade de downgrade do aparelho. Não limpar dados do usuário como parte do rollback automático.

## Build e publicação

Executados `flutter analyze --no-pub`, `flutter test --reporter compact`: sem problemas / 60 testes aprovados.

Build Web:

```powershell
flutter build web --release --dart-define="PILOT_ALLOWED_UIDS=4EGxLrjY5gPNVEFhibfG6dSBCnF3" --dart-define="PILOT_ALLOWED_EMAILS=sourico.br.ec@gmail.com,comercial.artcodex@gmail.com" --dart-define="OFFICIAL_APP_HOSTS=app.meutorico.com.br" --dart-define="FIREBASE_AUTH_DOMAIN=app.meutorico.com.br"
```

Publicação usa a API oficial Firebase Hosting com autenticação do CLI instalado: clona a release atual, mantém configuração e cinco arquivos legais com hashes idênticos, substitui os arquivos gerados em build/web, verifica ausência de release concorrente e publica somente o site torico-ca479. Não usa `firebase deploy` com configuração local incompleta para as rotas legais. Helper local: `.tmp-price-release/publish-web.cjs`; relatórios locais: `.tmp-price-release/hosting-deploy/`.

Android usa os mesmos quatro dart-defines públicos, com:

```powershell
flutter build appbundle --release --build-name=1.0.0 --build-number=7 <dart-defines acima>
```

Assinatura release via configuração local existente, sem fallback debug. APK universal via bundletool oficial 1.18.3, SHA256 da ferramenta A099CFA1543F55593BC2ED16A70A7C67FE54B1747BB7301F37FDFD6D91028E29. Helper Java local lê key.properties em memória; senhas não aparecem nos argumentos do processo, logs ou Git.

## Restrições preservadas / homologação

Nenhuma intervenção em backend, Cloud Run, OAuth, webhook, Auth, Firestore, usuários/planos, DNS, proxy, certificados, REDE ou Scheduler. Nenhuma cobrança. O estado operacional do Scheduler não é revalidado por esta entrega; nenhum comando de alteração foi executado.

Pendentes testes nativos em aparelho/emulador: login Google/e-mail, plano com preços, allowlist, painel/histórico, som e retorno OAuth. Nenhum login, OAuth, desconexão ou alteração de dados reais foi executado nesta validação. Sem publicação Google Play.

## Publicação PWA concluída

- Release nova: `sites/torico-ca479/releases/1792024154034000`.
- Versão nova: `sites/torico-ca479/versions/fe99efd517d84c8b`.
- Configuração Hosting preservada; cinco arquivos legais preservados por hash.
- JavaScript público igual ao build local, SHA256 `95814334F05003DA7F4EFAC1DA9958A3ECE95EDC488E5BC41D977EAD80E2B4FE`.
- Cinco hosts HTTPS 200: app, raiz, www, torico-ca479.web.app e torico-ca479.firebaseapp.com. Raiz continua redirecionando para www.
- Quatro páginas legais www HTTP 200, HTML público e não fallback do PWA.
- Capturas sem login: app oficial abre login; web.app sem flag abre pré-lançamento; web.app com pilot=1 abre login técnico.
- Preços/allowlist confirmados no JavaScript publicado. Tela de plano validada pelos testes widget; navegação autenticada em produção não foi executada.
- Evidências em `official-prices-v7-evidence/` (SAGA: cópia exata do conteúdo isolado; PWA: capturas das URLs públicas).

## Android concluído

- Versão: **1.0.0 (7)**, confirmada no AAB e APK; anterior local confirmado como versionCode 6.
- ApplicationId: **br.com.meutorico.app**; minSdk **24**, targetSdk **36**.
- AAB: `build/app/outputs/bundle/release/app-release.aab` — 64011409 bytes.
- SHA256 AAB: `102ABDAFEB0EEB6E930E256912FFEDA716AD442603ED9B3392962FBA11497CBC`.
- APK universal: `build/app/outputs/apk/release-test/torico-prices-v7-release.apk` — 63751502 bytes.
- SHA256 APK: `A9B44324AA2C7929591CA8A078AE81E750211E302B32240BD68CAF5B441A0ED2`.
- APKS intermediário: `build/app/outputs/bundle/release/torico-prices-v7-release.apks`.
- Bundletool validate aprovado; jarsigner: jar verified (código 0); apksigner: Verifies, assinatura v2/v3, um assinante.
- Certificado SHA256: `8C:15:30:95:83:E8:FD:11:7A:63:8E:F3:48:C7:74:AE:FC:98:D7:71:39:93:C0:86:C8:3F:D4:64:0D:03:89:A6`, igual ao anterior.
- Preços 24,90/39,90, UID permitido e os dois e-mails aprovados confirmados no libapp.so arm64 do APK final.
- Permissões: INTERNET, ACCESS_NETWORK_STATE, USE_BIOMETRIC, USE_FINGERPRINT, READ_GSERVICES e br.com.meutorico.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. Sem câmera/microfone/localização adicionados.
- Avisos preservados: audioplayers_android usa KGP; jarsigner informa certificado autoassinado, ausência de timestamp e diferenças JarFile/JarInputStream. Mesmos tipos de avisos já registrados em android-release-build.md; não foram mascarados e nenhuma dependência/assinatura foi alterada.
- pubspec.yaml permanece inalterado: versionCode 7 passado explicitamente no build. Nenhum binário, chave, JSON Firebase ou senha versionado.

Logs/relatórios locais adicionais: .tmp-price-release/android-build.log, aab-manifest.xml, aab-signature.txt, apk-signature.txt e apk-badging.txt.

Comparação direta com APK versionCode 6: conjunto de permissões final idêntico. Manifest/assinatura e binários foram inspecionados sem instalar ou executar o app.
