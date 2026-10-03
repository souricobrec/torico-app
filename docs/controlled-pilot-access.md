# Acesso piloto controlado — fase pré-lojas

O bloqueio público de `DomainBlockService` permanece intacto. Hosts de produção
mostram pré-lançamento por padrão; localhost, preview e apps nativos mantêm seu
comportamento anterior. Nenhuma alteração de backend, regras Firestore ou configuração Firebase.

`?pilot=1` solicita a tela de login piloto. Não é senha, convite secreto nem
autorização por si só. O app só é mostrado após Firebase Authentication confirmar
um UID presente em `PILOT_ALLOWED_UIDS`, configurado no build. Lista vazia (default)
bloqueia todos os pilotos, inclusive com parâmetro ou preferência salva.

Os UIDs são identificadores públicos, não credenciais. Nunca colocar tokens,
senhas, chaves de integração ou segredos em dart-define, URLs ou localStorage.

```powershell
flutter build web --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.meutorico.com.br --dart-define=PILOT_ALLOWED_UIDS=UID_AUTORIZADO_1,UID_AUTORIZADO_2
```

Substituir somente por UIDs reais aprovados do Firebase Authentication. A lista
nesta documentação é ilustrativa; não há pilotos reais configurados no fonte.
As contas piloto devem já existir; o login dedicado não cria usuários.

## Uso e limpeza

- Público sem preferência: `https://torico-ca479.web.app` → pré-lançamento.
- Piloto: `https://torico-ca479.web.app/?pilot=1` → login → app somente para UID autorizado.
- Preferência de modo piloto persistida via shared_preferences/localStorage; UID
é verificado novamente pela sessão Firebase a cada abertura. Troca de usuário ou
logout derruba todo o Navigator interno do app, inclusive rotas já abertas.
- `https://torico-ca479.web.app/?pilot=0` remove a preferência ao iniciar.
- Botão “Sair do modo piloto” remove somente a preferência piloto, bloqueia o app
imediatamente e tenta encerrar a sessão Firebase, sem apagar histórico local.
- Se a URL ainda contém `pilot=1`, um reload volta a solicitar login; usar `pilot=0`
ou remover o parâmetro para manter o modo limpo.
- Falha de armazenamento mantém o pré-lançamento. Não há fallback liberando acesso.

## Limites da proteção

Este é controle de rollout da **interface** em cliente público, não uma nova
barreira de autorização das APIs ou do Firestore. Um cliente modificado pode
ignorar controles Flutter. As proteções reais continuam sendo as existentes no
servidor e nas regras Firebase; não foram alteradas nesta missão. Para autorização
centralizada/revogação imediata seriam necessários controles no servidor, fora
do escopo autorizado. Remover UID do build exige republicação e atualização do PWA;
um build antigo em cache não é uma forma de revogação centralizada.

## Validação

```powershell
flutter analyze --no-pub
flutter test --no-pub test/pilot_access_test.dart test/api_config_test.dart
```

Validação local em 2026-10-02: análise sem avisos, seis testes aprovados e
build web release de produção concluído com lista piloto vazia (bloqueio padrão).
O teste de widget usa UIDs fictícios para verificar login, rejeição de usuário,
acesso autorizado e encerramento de rotas ao sair. Não houve teste com conta real
nem publicação deste build.

Testar depois em ambiente autorizado: navegador limpo bloqueado; link piloto;
login de conta fora da lista bloqueado; UID convidado acessa app; preferência
persiste; pilot=0 limpa; logout e troca de usuário não preservam rotas internas.
Testar Mercado Pago manualmente com piloto real depois de publicar um build aprovado.
Este PR não realiza deploy nem altera OAuth, Mercado Pago, REDE, Cloud Run, Scheduler
ou webhooks.
