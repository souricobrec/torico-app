# Painel oficial e auditoria de logout Android — 1.0.0 (8)

## Diagnóstico

- Painel: `lib/screens/painel_screen.dart` desenhava TORICO via `Text`, com `Colors.white`. Substituído por `ToricoPanelBrand`, que reutiliza `assets/images/torico_logo.png` completo (símbolo, nome dourado e slogan), com proporção preservada. Nenhum asset ou ícone Android foi modificado.
- Autenticação: não há chamada a `authenticate`, login Firebase ou lightweight authentication em main/initialização/dispose. Google só é iniciado por ação explícita de login. A persistência Firebase ao fechar normalmente é intencional.
- Falha confirmada no código anterior: logout Google dependia de `_googleInitialization != null`. Em processo novo, uma sessão Firebase restaurada pode existir com essa variável nula; Sair limpava Firebase, mas pulava o Credential Manager Google. Agora inicializa somente o adaptador e chama signOut (que o plugin Android 7.2.18 encaminha para clearCredentialState); não autentica e não revoga a autorização Mercado Pago/Google.
- Corrida possível: login assíncrono iniciado antes de Sair podia completar depois, restaurando Firebase. Contador de geração da sessão invalida resultados anteriores ao logout, inclusive entre instâncias AuthService. Credenciais pendentes para vinculação não são reutilizadas entre gerações de sessão.
- Erros: SDK Android pode reportar canceled para interrupções do fluxo. A UI agora usa mensagem neutra de login não concluído; clientConfigurationError e demais falhas continuam sendo erros, não cancelamentos voluntários. Popup concorrente interrompido também não é rotulado como cancelamento voluntário.
- A tela Google observada no emulador não foi reproduzida nesta missão. Os dois defeitos acima foram identificados por auditoria e cobertos por testes; a confirmação no dispositivo continua necessária.

## Comportamento

1. Fechar/reabrir sem Sair: Firebase mantém sessão normalmente; nenhuma autenticação Google é iniciada automaticamente pelo app.
2. Sair: Firebase encerra sessão; Google limpa o estado local, mesmo em cold start. O gate recebe null, remove rotas internas e mostra login.
3. Reabrir depois de Sair: tela de login; novo login Google somente após clicar no botão.
4. Limpeza Google falhar: Firebase permanece desconectado e há diagnóstico local sem dados pessoais/tokens. Não há tentativa automática de login como recuperação. Falha do signOut Firebase é propagada, não apresentada como sucesso.
5. Nenhuma venda, documento, integração Mercado Pago ou usuário é removido. Sem alteração de allowlist, preços, ícones, backend, OAuth, Firebase Console, secrets ou Scheduler.

## Testes / limites

`test/native_logout_brand_test.dart`: logout cold start; reabertura sem logout; novo AuthService após logout; falha de limpeza Google; credencial pendente invalidada; Firebase login completando após logout; classificação de erros; gate removendo sessão e reabrindo login sem clicar; marca oficial em 320/390/768 px.

Testes usam fakes, sem login, OAuth, Firebase/Firestore real ou dados de usuários. Confirmam fluxo do aplicativo; não substituem teste do Credential Manager no Android real/emulador.

## Build e homologação

Build Android com versionName=1.0.0, versionCode=8 (7 confirmado no APK anterior). Mantidos os quatro dart-defines públicos já aprovados: PILOT_ALLOWED_UIDS, PILOT_ALLOWED_EMAILS, OFFICIAL_APP_HOSTS e FIREBASE_AUTH_DOMAIN. Não executar build/deploy PWA ou site nesta missão.

Backup dos artefatos anteriores: `.tmp-native-logout/backups/app-v7.aab` e `app-v7.apk`. Assinatura existente e configuração Firebase local não alteradas. Nenhum binário/credencial versionado.

Checklist manual no novo APK:

- Verificar símbolo e nome dourados do Painel em celular pequeno, rotação e escala de fonte maior.
- Entrar por Google, fechar completamente e reabrir sem Sair: sessão preservada.
- Reabrir com sessão persistida, clicar Conta → Sair, fechar processo e reabrir: login sem UI Google espontânea.
- Novo login Google só após clique; testar cancelamento, rede indisponível e erro de configuração sem mensagem enganosa.
- Repetir login e logout por e-mail/senha.
- Conferir que Mercado Pago e histórico continuam associados à mesma conta; não desconectar para este teste.

Avisos existentes de KGP e jarsigner serão mantidos no relatório de build; não alterar dependências para ocultá-los. Sem publicação na loja ou deploy.

Validação automatizada concluída: `flutter analyze --no-pub`, sem problemas; `flutter test --reporter compact`, 69 testes aprovados (60 anteriores + 9 novos). Falha inicial da fixture de reabertura por stream de assinatura única foi corrigida para broadcast, como o Firebase; suíte final passou integralmente.

## Artefatos finais

- AAB: `build/app/outputs/bundle/release/app-release.aab`; 64018721 bytes; SHA256 `E9E46112947F111218C9E185693335E21DEEA88C82C9C6D46F9A8E8A684B185D`.
- APK: `build/app/outputs/apk/release-test/torico-panel-logout-v8-release.apk`; 63751502 bytes; SHA256 `6A4BCE7DC6A92D69DD860D661A7483B61C0A99BE06C1147E6B66AABEBF695051`.
- applicationId br.com.meutorico.app; versionName 1.0.0; versionCode 8; minSdk 24; targetSdk 36.
- Bundletool validate: sucesso. Jarsigner: jar verified, com os avisos conhecidos de certificado autoassinado/sem timestamp e leitura JarFile/JarInputStream. APK: assinatura v2/v3 válida, um assinante.
- Certificado SHA256: `8C15309583E8FD117A638EF348C774AEFC98D7713993C086C83FD4640D0389A6`, igual às versões anteriores.
- Permissões finais permanecem INTERNET, ACCESS_NETWORK_STATE, USE_BIOMETRIC, USE_FINGERPRINT, READ_GSERVICES e permissão interna DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION.
- Logs seguros locais: .tmp-native-logout/analyze.log, tests.log, android-build.log, aab-manifest.xml, apk-badging.txt, apk-signature.txt e aab-signature.txt. Não versionados.
- Instalação de homologação, mantendo os dados locais: `adb install -r build/app/outputs/apk/release-test/torico-panel-logout-v8-release.apk`. Nenhuma instalação realizada nesta missão.
- Nenhum build/deploy web/site ou publicação na Google Play. Ícones, allowlist, preços, Firebase Android e dependências sem alterações.
