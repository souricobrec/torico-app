# Desconexão de plataforma

Branch: `feature/disconnect-platform`. Sem deploy automático.

## Três ações diferentes em Conta

- **Sair da conta:** encerra apenas a sessão Firebase. Não chama a API de
  desconexão, não remove autorização Mercado Pago e não apaga histórico.
- **Limpar dados deste dispositivo:** remove os caches TORICO de plataformas,
  total do dia e preferência de áudio deste navegador, e encerra a sessão.
  Não remove integrações na nuvem. Não limpa dados de outros sites ou todo o
  armazenamento do navegador. A flag de acesso técnico piloto é preservada.
- **Desconectar Mercado Pago:** disponível na integração ativa, com confirmação.
  Mantém a sessão TORICO e o histórico; retorna à escolha de plataforma.

## Endpoint

`POST /integrations/mercado_pago/disconnect`

Header obrigatório: `Authorization: Bearer <Firebase ID Token>`.
O backend valida o token com `verifyIdToken(token, true)`, incluindo revogação.
UID é extraído exclusivamente do token; body/query não selecionam usuários.
Outros IDs de plataforma são rejeitados nesta entrega.

Uma transação Firestore marca o documento privado
`users/{UID}/integrations/mercado_pago` como `disconnected`, remove
`accessTokenEncrypted` e `refreshTokenEncrypted` e atualiza timestamps.
O documento `users/{UID}/integration_status/mercado_pago` recebe status
`disconnected` sem dados privados. Sales e daily_totals não são modificados.
A operação pode ser repetida com segurança.

Não há chamada à API Mercado Pago para revogar OAuth: a autorização externa
pode existir para outros vínculos e continua gerenciável pelo titular no Mercado
Pago. A desconexão remove os tokens deste UID no TORICO. O vínculo conserva
metadados privados de auditoria, sem os tokens.

Webhooks consultam somente integrações conectadas. A transação de gravação de
vendas reconsulta o status privado para impedir gravações após a desconexão,
incluindo eventos em trânsito e o fallback legado. Uma venda cuja transação já
foi concluída antes da desconexão permanece no histórico. Uma nova autorização
OAuth restabelece status conectado e tokens criptografados pelo fluxo existente.
Os status públicos são consultados no servidor, evitando uma leitura conectada
antiga do cache Firestore após desconectar.

## Validação e publicação futura

`flutter analyze --no-pub`

`flutter test --no-pub`

`node --test backend/test/*.test.js`

Testes não realizam OAuth, login ou desconexão reais. Para testar ponta a ponta,
usar uma conta controlada, confirmar desconexão, verificar tokens removidos,
status público desconectado e histórico intacto, então reconectar por OAuth.

Backend deve ser publicado antes do frontend quando houver missão de deploy.
Sem o endpoint publicado, o app apresenta erro e mantém a integração conectada.

Não houve mudanças em OAuth client, webhook URL, secrets, Firestore Rules,
Firebase Auth, DNS, REDE ou Scheduler. Permanecem pendências anteriores do
início OAuth sem ID Token, duplicidade de conta Mercado Pago entre UIDs e nonce
sem consumo único. Este endpoint não resolve essas outras rotas.
