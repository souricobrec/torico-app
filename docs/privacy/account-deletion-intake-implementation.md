# Recebimento autenticado de pedidos — fase 1 implementada, somente local

Status: código para revisão, **não publicado e impossível de habilitar no Cloud Run nesta versão**. Base do desenho: 8c1ce1c. Nenhuma conta, venda, integração, Rule ou configuração real alterada; sem deploy, migração, APK/AAB, revogação ou bloqueio de webhook. Mantidos allowlist, preços, OAuth/callbacks e REDE/Scheduler.

## Escopo implementado

| Contrato | Comportamento |
|---|---|
| POST /v1/account-deletion/requests | ID Token Firebase validado com checkRevoked=true; aud/iss/projeto, UID/sub e single-tenant; auth_time inteiro no passado e até 300 s (parâmetro do desenho); corpo fechado confirmation=delete_account, noticeVersion e policyVersion=intake-review-v1; Idempotency-Key 32–128 caracteres seguros. Retorna 202 apenas após transação durável. |
| GET /v1/account-deletion/requests/current | Token válido do titular; carrega índice privado por hash de UID; sem receber UID do cliente; devolve somente projeção pública do pedido corrente ou 404. |
| GET /v1/account-deletion/requests/{id} | Mesmo controle; só ID do pedido corrente desse titular, nunca lista global ou outro usuário. ID alheio/inexistente retorna 404 indistinguível. Histórico de pedidos não é exposto nesta fase. |

Nenhum endpoint administrativo, de status por recibo, execução, revogação, lifecycle, rejeição ou exclusão foi implementado. Somente estado `received` é criado; leitura reconhece os estados do desenho, sem oferecer mutações. `completed` sem completedAt é recusado, mas só futura implementação revisada poderá produzir esse estado. UI não apresenta ação que execute/prometa exclusão.

Erros: 400 schema/query/header alternativo de UID/chave/JSON inválidos; 401 token inválido/expirado/revogado/disabled; 403 reauthentication_required; 404 pedido ausente/alheio/feature desligada; 409 mesma chave com conteúdo diferente; 413 excesso do parser; 429 rate_limited com Retry-After; 503 dependências indisponíveis ou falha/commit incerto. Nunca há protocolo inventado em erro. Não exibir erro bruto do SDK, corpo de token ou stack.

## Travamento de produção

Backend `server.js` exige simultaneamente: ACCOUNT_DELETION_INTAKE_ENABLED=true, Auth/Firestore Emulator hosts em loopback, FIREBASE_PROJECT_ID começando por demo-, K_SERVICE ausente. Sem isso, 404 feature_disabled antes de autenticação/banco. Mesmo definir a flag em Cloud Run não habilita a função. Nenhuma variável/secret foi configurada nesta missão. Alterar esse gate para produção requer nova revisão/autorização e mudança explícita de código.

Flutter usa dart-define ACCOUNT_DELETION_INTAKE_ENABLED, padrão false. Sem ele a tela mantém o contato manual anterior e não inicia chamadas/reauth. Os testes usam constructor injection e transporte local/falso; não foi feito build release com flag. Controle de UI não é autorização: servidor sempre valida token, propriedade, auth_time e schema.

Não há dependência, índice, IAM, regra, secret ou infraestrutura nova instalada. O módulo de backend recebe Auth/store por injeção, não carrega dotenv, não lê credenciais e não inicia servidor sozinho. A inicialização de server.js preserva o padrão existente, mas o gate impede a rota de chamar esses adapters contra produção.

## Modelo privado efetivamente usado

- account_deletion_requests/{id}: requestId/protocol aleatórios, subjectRef, status received, receivedAt ISO UTC do servidor, revision/schemaVersion, versões do aviso, completedAt=null. Sem UID/e-mail/token/venda no retorno público.
- account_deletion_subjects/{id}: UID e activeRequestId, apenas privados.
- account_deletion_uid_index/{SHA256(uid)}: subjectRef/activeRequestId para exclusividade. Hash de UID não é anonimização; continua dado associado.
- account_deletion_idempotency/{SHA256(uid:key)}: requestId, hash do corpo canônico, createdAt. Chave de usuário diferente não compartilha namespace. Nova chave para mesmo UID retorna protocolo existente; não cria segundo pedido/outbox.
- requests/{id}/events/received: registro mínimo de recebimento.
- account_deletion_outbox/{id}: sinal `intake_received`, executionAllowed=false; **nenhum dispatcher/consumer/worker**. Futuras rotinas devem recusar esse sinal como autorização de exclusão.
- account_deletion_rate_limits/{SHA256(uid:op)}: contador/janela de um minuto. 5 POSTs/minuto, 30 leituras/minuto por UID, compartilhados por transação Firestore entre instâncias. Retries contam no limite, mas não criam pedido duplicado. Limites são valores para revisão local, não política de produção aprovada.

Guarda antes de verificar token: 120 chamadas/minuto por peer, memória limitada a 10.000 peers; não confia em X-Forwarded-For nem altera trust proxy. Limite local não é proteção distribuída de borda e pode agrupar clientes por proxy; topologia/abuso precisam ser revistos antes de ativar produção. Quota autenticada é compartilhada no banco.

As coleções são de raiz e já estão negadas pelo catch-all das Rules atuais. Não se adicionou leitura direta para proprietário ou admin claim. Admin SDK ignora Rules, por isso a API consulta somente o índice/subject do token; consistência de subject/UID e request é conferida. Fluxo escreve exclusivamente nas coleções de controle. Nenhuma escrita em users, sales, daily_totals, integrations ou account_lifecycle.

A transação lê índice e idempotência antes de gravar e gera pedido/subject/índice/chave/evento/outbox atomicamente. Concorrência real foi validada no emulador. Corpo divergente com chave existente gera conflito; IDs/keys e protocolo não são mecanismo de autenticação. Não há expurgo/TTL automático de controles nesta fase, para não introduzir remoção de documentos. Aprovar retenção desses registros e plano de expurgo antes de qualquer ativação real.

## Aplicativo e autenticação recente

Com flag de teste: confirmação de intenção → diálogo de identidade → Firebase reauthenticate (Google ou senha do próprio TORICO) → ID Token após sucesso → registro. Nunca usar signIn para trocar/criar conta como reauth. UID é conferido antes/depois; sessão alterada aborta. Senha fica no controlador do diálogo e no SDK Firebase, não no endpoint, prefs ou logs; token somente no header.

A chave não secreta de idempotência é aleatória de 256 bits, gravada localmente ANTES do POST e separada por UID. Não é recibo de acesso, não contém token e não dá acesso a protocolo sem sessão validada. Prefixo local contém UID codificado, dado associado sujeito à futura política de limpeza. Falha de armazenamento impede envio. Timeout/erro mantém a chave: retry recupera o mesmo pedido; consulta explícita pode confirmar commit cuja resposta se perdeu.

A tela não envia automaticamente ao abrir; exige checkbox, clique e reautenticação. Mostra protocolo e estado recebidos do servidor. Erro de rede: recebimento não confirmado, oferece consultar/repetir. Erro de reauth/cancelamento: sem envio. Consulta sem resultado só é exibida em 404 request_not_found, não em indisponibilidade/feature_disabled. Falha de refresh mantém estado anterior indicado como não atualizado. Voltar/sair não exclui dados nem desconecta Mercado Pago.

## Evidências e resultados

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --reporter compact`: 88 testes aprovados, incluindo 11 novos (serviço/UI/reauth).
- `node --test backend/test/*.test.js`: 27 testes aprovados, incluindo 11 novos de intake.
- Integração HTTP nova: Express em 127.0.0.1, Auth simulado, adaptador Firestore real de produção sobre banco em memória transacional; sem Firebase SDK/credencial no teste HTTP. Verificação de JWT é delegada ao SDK real no código, não implementada manualmente; testes conferem checkRevoked=true, retorno de claims/erros e controles adicionais.
- Teste de health inicia server.js com ambiente sanitizado/projeto de teste, força flag=true e confirma rota 404 fora dos emuladores demo. Não importa .env nem escreve dados.
- Firestore Emulator já instalado: JAR 1.21.0, 127.0.0.1:18891, projeto demo-torico-intake, single-project estrito, Rules locais, sem import/export. Teste opt-in `backend/test-support/account-deletion-intake-emulator.mjs`: cliente Firestore existente em ssl=false/loopback, sem ADC/service account; IDs e dados artificiais. Três registros concorrentes → um protocolo, perfil fixture preservado e lifecycle ausente. REST com JWT não assinado SOMENTE ACEITO PELO EMULADOR: perfil próprio 200 (controle positivo), leitura/listagem privada do titular e de outro usuário 403, escrita privada 403. Isso não é teste de assinatura JWT em produção. Emulador encerrado sem exportar dados.
- Rules em produção não foram consultadas. Rules locais e dependências permanecem intactas. Logs seguros locais em `.tmp-deletion-intake/`: analyze.log, flutter-tests.log, backend-all-tests.log, emulator-tests.log e firestore-emulator.log. Não versionados.
- Nenhum teste acionou login/OAuth real, usuário real, APIs de revogação, Firebase Console, banco remoto, Scheduler ou Cloud Run.

## Repetição segura dos testes

Suíte Flutter e `node --test backend/test/*.test.js` não exigem produção; teste de health se recusa a rodar com backend/.env presente. Teste separado do Firestore só aceita FIRESTORE_EMULATOR_HOST=127.0.0.1:18891, TORICO_INTAKE_EMULATOR_TEST=demo-torico-intake e K_SERVICE ausente; requer emulador já iniciado com projeto demo/Rules locais. Recusa destinos diferentes; não contém limpeza/deleção de conta/documento. O usuário fictício/profile criado é apenas fixture em memória do emulador, descartado ao encerrar o processo, não dado real.

Não foi executado fluxo criptográfico completo com Auth Emulator e cliente Android/PWA; esse teste e homologação de reauth/provider, rede, limites e UI em dispositivo continuam pendentes. Testes backend já existentes de Mercado Pago usam VM/fakes; não houve OAuth ou webhook real.

## Pendências para ativação

1. Revisão independente de segurança dos contratos, quotas, Privacidade e do código; aprovação dos parâmetros e da matriz (ainda proposta).
2. Homologar JWT real no Auth Emulator, instâncias concorrentes, reauth Google/password em Android/PWA, email não verificado/contas vinculadas, erro e troca de sessão. Nenhuma senha/token em logs ou observabilidade.
3. Aprovar retenção/expurgo de protocolo, idempotência, quotas e auditoria; IAM mínimo de coleção/serviço, monitoramento e escalonamento humano. Definir quem acompanha pedidos recebidos sem worker.
4. Aprovar limites distribuídos de borda, topologia de IP, orçamento, deduplicação operacional e respostas de rejeição/status futuras. A fase atual não oferece painel/admin nem mudança de estado.
5. Para produção: revisar e substituir explicitamente o gate somente-emuladores, validar regras implantadas, proteger CORS/infra conforme autorização própria, fazer release separada do app/backend e habilitar feature de forma controlada. Nada disso autorizado/executado agora.
6. Exclusão efetiva, barreiras de ingestão, revogação MP, dupla aprovação, receipt/status sem Auth, notificações finais e futura iOS permanecem fora deste código e exigem missão/autorização próprias. Nunca consumir outbox de recebimento como ordem de exclusão.

## Rollback desta fase

Sem deploy ou dado real, rollback é de código/branch. Futuro rollback deve desabilitar UI/intake e preservar pedidos duráveis e consultas/atendimento; não apagar protocolos como limpeza, não apresentar falha de notificação como conclusão nem ativar processamento. Não há rotina destrutiva a reverter. Artefatos Android existentes não foram regenerados.

Conferência final: reautenticação em andamento não aceita segundo clique; troca de UID enquanto a resposta chega descarta protocolo da sessão anterior. Teste opt-in do emulador fica em test-support para não ser executado acidentalmente por descoberta automática da suíte. Logs finais confirmam 88 Flutter, 27 backend e PASS da integração Firestore; o processo Java de teste foi encerrado.
