# TORICO — alinhamento do login Android

13/10/2026. Branch `feature/android-current-login`. Sem deploy/publicação.

## Causa encontrada

`DomainBlockService.shouldBlock` retornava false fora da web. `main.dart` não
inicializava PilotAccessService para Android e escolhia SplashScreen diretamente,
sem PilotGate. O splash encaminhava usuário sem sessão para OwnerLoginScreen,
que usa o login antigo. O PWA oficial passava pelo PilotGate/OfficialLoginLayout.
Além disso, AuthService.loginWithGoogle usava somente signInWithPopup, fluxo web.
O AAB anterior não recebia dart-defines de allowlist; isso agora não permite acesso.

## Mudança

- Android usa PilotGate antes do splash e mesma tela OfficialLoginLayout existente:
  marca/logo, slogan, e-mail/senha, recuperação/criação e Google fora do card.
- Inicialização nativa habilita tela oficial de login sem depender de host/URL.
  App autorizado somente por UID na allowlist ou e-mail autorizado **verificado**.
  Nenhum usuário logado/allowlist vazia/usuário não autorizado libera painel.
- Google nativo: plugin oficial google_sign_in 7.2.0, inicialização única, seleção
  de conta e ID token convertido em GoogleAuthProvider.credential para Firebase
  signInWithCredential. Não há Firebase custom token nem associação por e-mail
  no backend. A identidade continua sendo o UID retornado pelo mesmo projeto.
- Web mantém signInWithPopup e configuração/hosts existentes. Testes continuam
  cobrindo app oficial, host técnico sem flag e piloto técnico com flag.
- Conflito de provedor continua exigindo autenticação por senha da conta existente
  antes de linkWithCredential; nenhuma migração, conta adicional ou alteração de
  registros é criada pelo app para resolver conflito.
- Logout encerra Firebase; limpa seleção Google se houve inicialização nativa.
  PilotGate descarta navegação interna quando a identidade deixa de ser autorizada.
- E-mail/senha preservado. Cancelamento/configuração Google mostram erro amigável.

O gate é proteção de UI do piloto, não substitui autorização da API/Firestore.
Pendências de segurança OAuth Mercado Pago continuam fora desta alteração.

## Configuração Android local

JSON oficial ignorado: projeto torico-ca479, package br.com.meutorico.app,
um client Android correspondente e uma entrada OAuth client_type 3 (Web).
Ela gera default_web_client_id pelo Google Services; nenhum client ID foi inventado
ou inserido manualmente no código, nenhum segredo foi adicionado.
A lista oauth_client do JSON contém zero entradas client_type 1; isso foi registrado,
sem inferir que o cadastro remoto está correto ou alterar Firebase/Google Cloud.
Em caso de clientConfigurationError/cancelamento inesperado após escolher conta,
o titular deve verificar package, SHA da assinatura e configuração do cadastro
Android. Essa checagem remota/homologação não foi executada aqui.

Não foram modificados key.properties, keystore, JSON local, Firebase Console,
backend, OAuth Mercado Pago, webhook, secrets, Cloud Run, REDE/Scheduler, banco
ou páginas legais públicas.

## Validação e build

flutter analyze sem problemas e flutter test com **52 testes aprovados**.
Os testes Google usam credenciais fictícias injetadas, sem autenticação real.
Gate nativo cobre login oficial, autorização UID/e-mail verificado, bloqueio e
lista vazia. Logout/limpeza são testados dentro do gate, preservando integração.

Comando do build local (defines públicos, não segredos):

```powershell
flutter build appbundle --release --build-number=2 --dart-define="PILOT_ALLOWED_UIDS=4EGxLrjY5gPNVEFhibfG6dSBCnF3" --dart-define="PILOT_ALLOWED_EMAILS=sourico.br.ec@gmail.com,comercial.artcodex@gmail.com" --dart-define="OFFICIAL_APP_HOSTS=app.meutorico.com.br" --dart-define="FIREBASE_AUTH_DOMAIN=app.meutorico.com.br"
```

UID permitido preservado. notle2012@gmail.com não foi adicionado; conta Mercado
Pago não precisa pertencer à allowlist de login TORICO. Não versionar binários.
Artefatos anteriores guardados localmente em `build/android-release-backups/pre-native-login/`.

Build concluído: AAB 63.875.809 bytes, SHA256
`27F7716F29ADAF85315F781E8CCE38DE6C10F94FAAAC0F8518E99E87A724228C`.
APK universal novo: `build/app/outputs/apk/release-test/torico-native-login-release.apk`,
63.594.829 bytes, SHA256
`7C694909CFBDDC3E6A858B1070EFD5E676F14F7E7BE2BEA21F8110C1BFD5075B`.
Mesmo certificado upload, minSdk 24/targetSdk 36; versionCode 2. Bundletool
validou o AAB; apksigner validou v2/v3 do APK. Nenhuma instalação executada.
Manifest acrescenta USE_BIOMETRIC/USE_FINGERPRINT via AndroidX biometric das
dependências Google; auditar essas permissões antes da submissão.

## Ainda testar no emulador/aparelho

Instalar a versão 1.0.0 (2) sobre APK com mesma assinatura, sem apagar dados.
Conferir login oficial, botão Google, seleção/cancelamento, login e-mail/senha,
recuperação, UID existente, allowlist, lista vazia em build separado, logout/limpeza,
reabertura e navegação. Conferir conta não autorizada e e-mail não verificado.
Google Services/conta no emulador são necessários ao fluxo Google real.
Não considerar testes de mock como homologação com provedor.

Mercado Pago/câmera e retorno ao Android continuam exigindo testes; callback
retorna ao PWA e deep link automático nativo permanece pendente. Não houve OAuth
real ou ação financeira nesta missão.

Referências: [Google Sign-In Android](https://pub.dev/packages/google_sign_in_android),
[Google Sign-In](https://pub.dev/packages/google_sign_in),
[Firebase autenticação federada](https://firebase.google.com/docs/auth/flutter/federated-auth).
