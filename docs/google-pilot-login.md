# Google no PWA piloto

E-mail/senha permanece disponível. No PWA, “Entrar com Google” usa o popup do
Firebase Authentication, sem SDK adicional ou secrets no cliente. O bloqueio
público continua intacto: `?pilot=1` apenas solicita login. A preferência piloto
e a limpeza por `?pilot=0`/“Sair do modo piloto” seguem funcionando.

O acesso exige UID em `PILOT_ALLOWED_UIDS` **ou** e-mail verificado pelo Firebase
em `PILOT_ALLOWED_EMAILS`. E-mails são normalizados (trim/minúsculas), com comparação
exata, sem curingas. Nenhum UID/e-mail real foi adicionado. Essas listas são públicas
no build; são controle de interface, não autorização de API/Firestore.

```powershell
flutter build web --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.meutorico.com.br --dart-define=PILOT_ALLOWED_UIDS=UID_APROVADO --dart-define=PILOT_ALLOWED_EMAILS=piloto@example.com
```

Substituir exemplos apenas por pilotos aprovados. Uma lista pode ser omitida;
ambas vazias mantêm todos bloqueados.

## Configuração manual antes de publicar

No Firebase Authentication, habilitar Google com e-mail de suporte e confirmar
que `torico-ca479.web.app` está nos domínios autorizados. **Manter “uma conta por
endereço de e-mail” / vincular contas com o mesmo e-mail**, para evitar identidades
duplicadas. Nenhuma configuração do console foi alterada por este trabalho.

Firebase pode reconhecer/vincular automaticamente a identidade Google ao e-mail
existente conforme sua política de provedores confiáveis. Se retornar
`account-exists-with-different-credential`, a tela solicita e-mail/senha; após
autenticar a conta de mesmo e-mail, vincula a credencial Google ao UID existente.
A credencial pendente fica apenas em memória, não em storage/logs. Outro e-mail
não recebe essa vinculação. Nunca criamos conta alternativa para resolver conflito,
nem migramos vendas ou integrações. Cancelamento/popup bloqueado mantém opção de senha.

Antes do teste real, registrar o UID existente; depois de entrar com Google,
confirmar **o mesmo UID**, histórico e Mercado Pago conectado. A allowlist por
e-mail não comprova continuidade de UID. Se houver duplicação prévia ou política
de múltiplas contas por e-mail, parar: este código não mescla usuários/dados.
Validar também que a senha existente continua funcionando, pois o comportamento
de vinculação automática depende das configurações/políticas do Firebase.

## Verificação

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Validação local em 2026-10-02: análise sem avisos, dez testes aprovados e build
web release de produção concluído com as allowlists vazias (bloqueio padrão).

Testes cobrem e-mail não verificado/fora da lista, modo público, UID, limpeza,
botão Google e vinculação de conflito mantendo UID. O build release valida
compilação; popup/OAuth e continuidade real de dados exigem teste manual com conta
piloto autorizada após publicação aprovada. Não houve deploy, alteração de backend,
Mercado Pago, REDE, Scheduler, Cloud Run, webhooks ou secrets.

Referências: [Google no Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth),
[vinculação de contas](https://firebase.google.com/docs/auth/flutter/account-linking).
