# Domínio do login Google

Antes de inicializar Firebase no web, `FirebaseAuthConfig` escolhe o authDomain
somente para hosts de `OFFICIAL_APP_HOSTS` (padrão `app.meutorico.com.br`). Sem
override usa o host oficial atual; `FIREBASE_AUTH_DOMAIN` permite escolher outro
host oficial explícito. URLs, caminhos e hosts fora da lista falham antes do login.
Hosts técnicos, preview e localhost mantêm as opções geradas pelo FlutterFire,
mesmo com esse define; `?pilot=1` não muda a seleção. Android permanece intacto.

O arquivo gerado `firebase_options.dart` não foi modificado. Todas as opções,
incluindo projeto/app/API key pública, são preservadas; apenas authDomain muda.
Não há migração de conta, alteração de UID ou mudança no serviço de autenticação.
O gate e as allowlists continuam obrigatórios.

## Pré-condições antes de publicar

Confirmar manualmente que o domínio está ligado ao Hosting do mesmo projeto,
autorizado no Firebase Auth, e que o cliente OAuth Google usado pelo Firebase tem
`https://app.meutorico.com.br/__/auth/handler` em Authorized redirect URIs, mantendo
o URI técnico existente. O código sozinho não autoriza esse callback; caso falte,
o Google pode retornar `redirect_uri_mismatch`. Não alterar o OAuth Mercado Pago.
Nenhum console, DNS ou Hosting foi alterado nesta tarefa.

Referência oficial: https://firebase.google.com/docs/auth/web/google-signin#customizing_the_redirect_domain_for_google_sign-in

## Build de validação (sem deploy)

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=FIREBASE_AUTH_DOMAIN=app.meutorico.com.br
```

Na futura publicação autorizada, manter também os defines `PILOT_ALLOWED_UIDS`,
`PILOT_ALLOWED_EMAILS` e `OFFICIAL_APP_HOSTS` já usados em produção. Build sem
allowlists não libera usuários. Validar em navegador novo o domínio no consentimento
Google, o mesmo UID após login, e-mail/senha, histórico, painel e fluxo técnico.
