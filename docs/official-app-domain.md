# Acesso oficial controlado do comerciante

`https://app.meutorico.com.br` abre o login e-mail/senha ou Google sem `?pilot=1`.
O host passa obrigatoriamente pelo mesmo gate Firebase: somente UID autorizado
em `PILOT_ALLOWED_UIDS` ou e-mail **verificado** em `PILOT_ALLOWED_EMAILS` entra no app.
Contas fora da lista recebem “Acesso não liberado”; listas vazias permitem ver o
login, mas não acessar o app. No host oficial não há textos de modo piloto.
“Sair da conta” encerra a sessão e retorna ao login, sem desativar o fluxo oficial.

`OFFICIAL_APP_HOSTS` aceita hosts separados por vírgulas, normalizados para
minúsculas, com comparação exata. Default: `app.meutorico.com.br`. Não usar URLs,
caminhos ou curingas. Mesmo removido dessa configuração, o host padrão continua
bloqueado pelo gate público, evitando liberação acidental.

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.meutorico.com.br --dart-define=OFFICIAL_APP_HOSTS=app.meutorico.com.br --dart-define=PILOT_ALLOWED_UIDS=UID_APROVADO --dart-define=PILOT_ALLOWED_EMAILS=piloto@example.com
```

Usar somente UIDs/e-mails aprovados, sem secrets. A configuração do host oficial
não grava preferência piloto. No host técnico, `https://torico-ca479.web.app`
continua pré-lançamento em navegador sem preferência; `?pilot=1`, persistência
local e limpeza `?pilot=0` continuam funcionando como antes. A preferência
persistida permite ao navegador técnico já habilitado continuar sem parâmetro.

Não há criação/migração de identidade nesta mudança. Login, vinculação Google,
UID Firebase e associação existente de vendas/integrações permanecem iguais.
Sessões de navegador são separadas por origem: é esperado entrar novamente no
novo domínio, usando a mesma conta. Conferir o mesmo UID e histórico em teste
manual autorizado; nenhuma venda real foi testada por este commit.

Este gate é controle da interface, não substitui autorização do servidor ou
regras Firestore. A publicação futura exige configuração manual do domínio no
Firebase Hosting/DNS e domínio autorizado no Firebase Authentication, além de
build com allowlists aprovadas. Este trabalho não altera console, DNS, backend,
Cloud Run, Mercado Pago, webhook, REDE/Scheduler ou secrets, e não faz deploy.

Referências operacionais: [login Google](google-pilot-login.md) e
[modo técnico piloto](controlled-pilot-access.md).

Validação local em 2026-10-02: análise sem avisos, 13 testes aprovados e build
web release concluído com host oficial configurado e allowlists vazias.
As identidades dos testes são fictícias; não houve teste real de login no domínio
oficial, mudança de configuração ou publicação.
