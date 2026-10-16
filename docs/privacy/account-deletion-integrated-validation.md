# Homologação integrada do recebimento de solicitações

Base: branch `codex/account-deletion-hardening`, commit `bbeb526`.
Entrega: branch `codex/account-deletion-integrated-validation`.

**Parecer:** fluxo de recebimento/consulta aprovado neste ensaio local, com as limitações abaixo. Apto para planejar a próxima homologação isolada em clientes reais; **não autoriza ativação em produção** nem exclusão efetiva.

## Ambiente e isolamento

- Projeto único `demo-torico-intake`; Auth Emulator em `127.0.0.1:19099`, Firestore Emulator em `127.0.0.1:18891` e API em `127.0.0.1:18893`.
- Ferramentas oficiais já instaladas: Auth Emulator do `firebase-tools`, Firestore Emulator JAR 1.21.0, Flutter e Java locais. Nenhum instalador/download ou infraestrutura nova.
- Runner recusa `.env` na raiz/backend, portas ocupadas e configuração divergente. Não reutiliza/importa banco de emulador existente.
- Ambiente filho construído por allowlist: variáveis públicas do sistema operacional, caminhos de ferramentas e parâmetros `demo-*`. HOME/APPDATA/configuração de usuário apontam para diretório isolado. Não herda ADC, tokens Firebase CLI, caminhos de credenciais, secrets Mercado Pago ou configuração Cloud SDK.
- O launcher importa o **server.js real**, seus endpoints e gate existentes. No processo de teste, restringe o bind de `0.0.0.0` para loopback e bloqueia rotas fora de health/intake antes do Express. Não introduz flag/configuração de produção.
- O cliente HTTP Flutter recusa qualquer destino fora de `127.0.0.1` nas duas portas de API/Auth. Não utiliza o endpoint oficial como fallback.
- Usuários têm e-mails `@example.invalid`. Perfis, vendas, totais e credenciais fictícias foram criados exclusivamente no emulador. Não há clientes, senhas ou integrações reais nas fixtures.
- Não foram consultados Firebase Console, Cloud Run, IAM, Rules implantadas ou banco remoto. Não se executou deploy, OAuth, webhook, Scheduler, APK/AAB, expurgo ou exclusão de usuário/documento.

## Caminho efetivamente exercitado

```text
AccountDeletionScreen + AccountDeletionIntakeService reais
  → adapter de sessão Firebase simulado no Flutter
  → login/reautenticação por REST no Auth Emulator
  → ID Token emitido pelo emulador, mantido somente em memória/header
  → HTTP real por loopback
  → server.js real / gate / parser / quotas / verificação Firebase Admin
  → transações no Firestore Emulator
  → protocolo e estado reais do emulador
  → apresentação pela tela Flutter
```

`AuthService.reauthenticateCurrentUser` e `logout` são chamados, mas seu FirebaseAuth/User são adapters de teste. A reautenticação por senha do adapter realiza chamada REST real ao Auth Emulator e confere a permanência do UID. SharedPreferences utiliza armazenamento em memória de teste. Não são testes de APK, navegador, popup Google, persistência nativa ou plugin FlutterFire sobre dispositivo. O caminho de consentimento/credenciais nativo precisa de ensaio próprio.

## Cobertura e resultados

| Cenário | Execução/evidência | Resultado |
|---|---|---|
| Inicialização isolada | Emuladores novos, projeto demo, configuração sanitizada e portas exclusivas | PASS |
| Bloqueio Cloud Run | Servidor real local com `K_SERVICE=local-cloudrun-simulation`, mantendo projeto demo | 404 `feature_disabled` |
| Flag desligada | Servidor real local com flag `false`, corpo inválido/excessivo | 404 antes do parser |
| Matriz completa do gate | Testes backend com configurações sintéticas, sem conectar a projeto real | PASS |
| Registro e consulta pela tela | Checkbox, AuthService/reauth adapter, API real e exibição do protocolo/estado | PASS |
| Autenticação recente | Reautenticação real no Auth Emulator via adapter; teste dedicado do router com relógio injetado +301 s | PASS; stale rejeitado com 403 no teste dedicado |
| Tokens válidos/inválidos/revogados | Teste dedicado Auth + Firestore Emulator usando Firebase Admin | PASS; revogação somente de fixture Firebase local |
| Repetição/concorrência | Chamadas Flutter paralelas e novas chaves ao mesmo UID | Mesmo protocolo |
| Resposta perdida | Backend recebe POST; transporte de teste descarta a resposta após recebê-la; repetição/consulta recuperam o pedido | Sem segundo protocolo |
| Isolamento | Segundo usuário tem protocolo distinto; consulta de ID alheio pelo primeiro | 404 |
| Limpeza local | Remoção das chaves locais; consulta e novo POST autenticado | Protocolo recuperável no servidor |
| Logout | AuthService encerra adapter de sessão; serviço recusa consulta sem UID; novo login recupera pedido | PASS |
| Troca durante resposta | Resposta HTTP real chega após logout/troca de UID no adapter | Protocolo descartado; erro de sessão |
| Falha de rede | Injeção explícita de falha no transporte da tela | Recebimento não confirmado; sem protocolo inventado |
| JSON inválido | Transporte simula 202 com corpo inválido | Recebimento não confirmado; sem protocolo inventado |
| Firestore indisponível | Processo do emulador efetivamente encerrado antes de um POST Flutter | Falha segura; não confirma recebimento |
| Ausência de mutação destrutiva | Conferência de dez documentos protegidos, dois usuários Auth, dois protocolos e outbox não executável | Perfis/vendas/totais/integrações preservados; lifecycle ausente |
| Rules locais | Teste dedicado tenta leitura direta privada pelo titular e outro UID | 403 |

Os dois protocolos correspondem a dois usuários diferentes. As repetições não contam como pedidos novos. A preservação compara os documentos de perfil, venda, total diário, integração privada/ciphertext fictício e status legível de cada usuário, antes/depois do fluxo normal. A interrupção posterior do emulador descarta apenas memória de teste; não demonstra preservação de backups ou retenção de produção.

Validações finais executadas: `flutter analyze --no-pub` sem problemas; suíte Flutter padrão com **91 testes aprovados**; backend com **33 testes aprovados**; integrado com **5 + 1 testes aprovados**; teste dedicado Auth/Firestore Emulator com PASS. Os seis testes opt-in não fazem parte dos 91 da descoberta padrão.

### Limite observado na indisponibilidade

O teste com Firestore desligado completou em aproximadamente 20 segundos, a janela de timeout do cliente. Confirma comunicação de falha segura, **não** um SLA de resposta 503 da API. O teste aceita somente `service_unavailable`, timeout ou erro de transporte — erros de autorização não são aceitos como prova de indisponibilidade. Antes de produção, definir e testar deadline do backend, tratamento de commit incerto e observabilidade de requisições pendentes. Nenhum timeout de produção foi alterado nesta missão.

## Comandos de reprodução

Executar na raiz do repositório, com ferramentas locais já instaladas e portas livres:

```powershell
node backend/test-support/run-deletion-integrated.cjs C:/Users/CRZ/AppData/Roaming/npm/node_modules/firebase-tools/lib/emulator/auth/index.js C:/Users/CRZ/.cache/firebase/emulators/cloud-firestore-emulator-v1.21.0.jar C:/flutter
node backend/test-support/run-deletion-emulators.cjs C:/Users/CRZ/AppData/Roaming/npm/node_modules/firebase-tools/lib/emulator/auth/index.js C:/Users/CRZ/.cache/firebase/emulators/cloud-firestore-emulator-v1.21.0.jar
flutter analyze --no-pub
flutter test --no-pub --reporter compact
node --test backend/test/*.test.js
```

Adaptar somente caminhos das ferramentas em outra máquina. Não executar simultaneamente os dois runners de emuladores: eles recusam portas ocupadas. O teste Flutter integrado fica em `test-support/flutter/`, fora da descoberta automática, e exige marcador explícito de projeto demo. Sem esse marcador, recusa execução. O runner o executa duas vezes: cinco cenários normais e um de indisponibilidade real.

## Evidências locais

Ensaio integrado concluído com exit code 0 em `run-2026-10-16T00-41-46-699Z` (UTC; noite de 15/10 no Brasil).

- `.tmp-deletion-integrated/latest.json`: índice do ensaio e checks aprovados, sem UID/token.
- `.tmp-deletion-integrated/run-2026-10-16T00-41-46-699Z/summary.json`: status `passed`.
- Mesmo diretório: `flutter-normal.log` (5 aprovados), `flutter-outage.log` (1 aprovado), `backend.log` e `firestore.log`.
- Logs do teste dedicado: saída `PASS Auth + Firestore Emulator: valid/invalid/revoked tokens, recent auth, UID isolation, concurrency, private Rules`.

Logs ficam locais, fora do commit. Contêm apenas fixtures e diagnósticos de teste; não são registros de atendimento ou produção. O teste não imprime corpos de login nem tokens. O relatório versionado registra resultados, não credenciais.

Resumo seguro versionado: [evidência JSON](evidence/account-deletion-integrated-local.json), com checks, contagens e SHA256 dos logs locais. O backend registrou dois recebimentos, cinco duplicidades e uma rejeição de consulta alheia. Os três logs de API/Flutter foram verificados sem JWT completo ou senha da fixture; os eventos JSON do intake têm somente os quatro campos sanitizados previstos. Isso não substitui auditoria de observabilidade em produção.

## Problemas encontrados durante preparação

1. Ambiente sanitizado inicialmente omitia variáveis públicas exigidas pelo Flutter no Windows (`PATHEXT`, diretórios Program Files). Corrigido no runner com allowlist explícita, sem herdar o ambiente completo.
2. O primeiro helper de UI aguardava um Completer criado no relógio FakeAsync a partir da zona de I/O real. Causava timeout do próprio teste mesmo com POST concluído. Corrigido criando o Completer dentro de `runAsync`; não houve alteração na aplicação.
3. O primeiro teardown aguardava novamente um processo já encerrado por sinal. Corrigido verificando também `signalCode`; a execução final encerrou normalmente e gravou o resumo.
4. Estilo/anotação do teste opt-in foi ajustado; o uso de SharedPreferences de teste está documentado como exclusivo deste target fora de `test/`.

Essas tentativas preliminares não são contadas como aprovação. Não foi necessária correção no código funcional do aplicativo/backend.

## Limitações e próxima fase

- Não homologados Android/PWA reais, FlutterFire sobre plugin nativo/web, Google popup/redirect, persistência real de sessão/storage, rede móvel e retomada do processo.
- Auth Emulator aceita JWTs não assinados; os testes não comprovam assinatura criptográfica de tokens de produção. A verificação real continua delegada ao SDK Firebase Admin.
- Não é ensaio de carga, múltiplos processos Cloud Run, WAF, IAM, restore de backup, retenção, notificações ou atendimento administrativo.
- Não implementa exclusão, revogação Mercado Pago, bloqueio de ingestão, processamento de pedidos ou confirmação final. Outbox permanece `executionAllowed=false`.
- Antes de qualquer ativação: revisar deadline/monitoramento, borda/quotas e orçamento; aprovar retenção e atendimento; revisar IAM/Rules implantadas sob autorização própria; homologar cliente real em ambiente demo e revisar controles novamente.

**Bloqueio de produção preservado:** não se alterou código funcional, gate, dart-defines de release, backend implantado ou infraestrutura. Os testes de bloqueio foram locais; o estado remoto não foi consultado. Nenhuma autorização de ativação está implícita neste parecer.
