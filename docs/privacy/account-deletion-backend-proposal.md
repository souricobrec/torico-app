# Proposta backend — exclusão de conta (NÃO IMPLEMENTADA / NÃO ATIVAR)

Nenhuma rota foi adicionada ao backend. Esta especificação exige autorização separada, testes em staging e revisão de segurança/privacidade. Não usar scripts manuais contra UIDs reais para validar.

## Contrato proposto

`POST /v1/account-deletion/requests`

- TLS; Authorization Bearer Firebase ID Token; `verifyIdToken(token, true)`, validar uid, aud/iss/tenant esperado e token não revogado. UID exclusivamente do token; rejeitar userId/uid, email ou plataforma arbitrários no corpo/query.
- Exigir reautenticação real recente: `auth_time` no máximo 5 minutos e não futuro (janela proposta para aprovação), não apenas `iat` ou `getIdToken(forceRefresh:true)`. Google: credencial recente e reauthenticateWithCredential; senha: reauthenticate com senha, sem transmitir/salvar senha no backend. Apple futura: fluxo apropriado ao provedor; não presumir integração existente.
- Corpo limitado `{confirmation: "delete_account"}`; `Idempotency-Key` opaco. Confirmação inequívoca, sem campo de UID. Rate limiting por identidade e origem, App Check como defesa adicional se validado, logs mínimos sem token/corpo completo. CORS restrito não substitui autenticação nativa.
- Transação: um pedido ativo por UID, idempotência com hash do corpo, tombstone server-only `account_lifecycle/{uid}` em `deletion_pending`, versão/epoch e trabalho persistido. Não gravar status controlável em perfil público. Estados e outbox devem ser recuperáveis se o processo cair antes de enfileirar.
- Retornar 202 `{requestId,status:"requested",requestedAt,...}` apenas APÓS persistência durável. Nunca `deleted:true` no 202. Duplicação retorna o mesmo pedido; chave reutilizada com payload diferente:409. Sem autenticação:401; auth_time antigo:403 com `reauthentication_required`; serviço indisponível:503 sem falso registro. Sem ID de conta MP ou outros dados pessoais na resposta.

Acompanhamento após revogar/desabilitar Firebase precisa funcionar sem a sessão excluída: propor receipt aleatório de 256 bits, somente hash no servidor, segredo no armazenamento seguro do dispositivo, transporte em cabeçalho e nunca URL/query/log. `GET /v1/account-deletion/status`, Authorization `DeletionReceipt <receipt>`, devolve apenas requestId/estado/etapas/retencões comunicáveis. Expiração, recuperação via canal de contato verificado e política de retenção do recibo precisam de aprovação. Alternativa inicial: acompanhamento por e-mail verificado, mas não pode ser única via obrigatória na experiência Apple. Não implementar senha/UID como chave pública de consulta. Não exigir que o usuário excluído faça novo cadastro para consultar.

Estados futuros: requested → verifying/quarantining → revoking_integrations → deleting_data → completed ou completed_with_retention; falha recuperável → retrying/action_required. `completed_with_retention` não significa conta totalmente desidentificada: explicar dados, base/motivo e prazo específicos. Somente resposta server-side após verificação independente pode indicar conclusão. UI atual não usa esses estados.

## Barreira contra novas gravações (BLOQUEADOR)

Antes de apagar qualquer coisa, todos os escritores devem consultar account_lifecycle/epoch dentro da MESMA transação que grava dados:

- `saveSale` para qualquer source/plataforma (webhooks, fallback legado, testes, sincronizações).
- saveMercadoPagoIntegration e demais callbacks/refresh, status e gravações auxiliares. Barrar OAuth iniciado antes do pedido, novos connects e estados antigos. Callback bloqueado deve descartar/revogar com segurança token recém-retornado, sem salvar vínculo.
- Escritas cliente, jobs internos e criação de users precisam de proteção Rules/API aprovada. Admin ignora Rules: proteger também no código. Regra baseada apenas no documento users que será apagado não basta.
- O saveSale atual só ignora integração MP com status `disconnected` em webhook (server.js:1633). Documento AUSENTE passa por esse teste. Apagar tokens/integração sem tombstone pode permitir recriação via fallback ambiente (`resolveMercadoPagoContextFromWebhook`, server.js:1484/1511), writers concorrentes ou callback tardio. Não excluir até fechar essa lacuna.
- Worker mantém tombstone separado do documento users. Exclusão recursiva de users não pode apagar a barreira. Política mínima e com prazo para tombstone/pseudônimo é dado pessoal e requer base/revisão; não reter UID indefinidamente sem justificativa.
- Ao expirar a barreira, escritores exigem identidade/conta ativa canônica e integração connected existente, nunca permitem escrita se o perfil/identidade não existem. UID excluído não pode ser reutilizado por fallback. Restaurar backup reaplica as barreiras antes de liberar ingestão. Backlog de webhook deve ser reconhecido sem recriar vendas ou gerar retries infinitos.

## Worker idempotente e retomável

1. Validar pedido confirmado e barreira; desabilitar usuário e revogar Firebase refresh tokens (tokens já emitidos exigem checagem revogada nos endpoints, mais barreira). Nenhuma exclusão imediata a partir da tela/cliente.
2. Bloquear todas as integrações/status no TORICO. Inventariar vínculos e propriedade dos grants. A implementação atual de disconnect remove tokens, NÃO revoga OAuth no provedor.
3. Revogação MP: validar mecanismo oficial/escopo e efeito em outras autorizações antes de implementar; a mesma conta MP pode estar ligada a múltiplos UIDs. Não revogar um grant compartilhado/global sem resolver risco de afetar terceiros. Não alterar OAuth client/webhook URL. Em caso de falha, manter bloqueio e tarefa privada criptografada de retry com mínimo token necessário, acesso server-only, TTL aprovado; não marcar concluído com credenciais ainda utilizáveis/retidas sem explicação. Nunca copiar segredo global de criptografia ou remover Secret Manager.
4. Após revogação/decisão formal de tratamento, remover access/refresh tokens privados e metadados das integrações; status públicos, requests, oauth_states por UID e todos os aliases/índices derivados. Registrar só contagens/etapas, sem snapshots de token ou rawPayload.
5. Apagar recursivamente sales, daily_totals/last10Sales, integration_requests e quaisquer subcoleções. Paginar, limitar lotes, retry/checkpoints e validar existência de órfãos. Documento pai sozinho é insuficiente. Não tocar em outro UID.
6. Remover perfil/plano e Auth pelo Admin; revogar apenas sessões da conta TORICO. Não excluir conta Google/Mercado Pago do comerciante. Recriação voluntária futura por mesmo e-mail deve resultar em novo UID, sem herdar histórico/tokens do excluído; não mudar o UID de conta existente nesta entrega.
7. Tratar caches, suporte, exports/backups/logs conforme matriz aprovada. Exceções legais: separar conjunto mínimo em armazenamento de acesso restrito, sem uso operacional, com base, responsável e data de expurgo. Falha técnica não deve ser disfarçada de retenção legal. Conta não é uma assinatura cobrada no estado atual: não inventar checkout/cancelamento financeiro.
8. Verificação final independente: Auth ausente, nenhum token/integracão operacional, recursão sem dados indevidos, ingestão tardia recusada, exceções enumeradas. Só então concluir e notificar por canal verificado. Outbox de notificação idempotente; falha de entrega distinta de falha de exclusão.

## Privacidade e revisão operacional

- Matriz legal precisa definir categorias, base, prazos e responsável. Não assumir prazo fiscal genérico para todos os dados: TORICO acompanha vendas, não processa pagamentos.
- Dry-run em staging produz contagens por coleção e riscos, sem cópia de dados sensíveis; autorização humana em staging antes de testes destrutivos. Não armazenar backup indiscriminado do UID "por segurança".
- IAM mínimo, segregação solicitante/worker, logs auditáveis, acesso restrito e prazo para trilha; nada de ID Token/código OAuth/recibo nos logs.
- Exclusão é irreversível. Rollback do código antes de ativação é possível; depois de exclusão real não prometer restauração. Kill switch interrompe novos pedidos/processamento, mas mantém tombstone e confirmações verdadeiras.

## Plano de testes obrigatório ANTES de ativar

- HTTP: token ausente/inválido/revogado, auth_time antigo/futuro, UID injetado, corpo extra, request sem confirmação, replay/idempotência, troca de UID entre pedidos, rate limits, falha antes/depois do commit/outbox.
- Propriedade: duas contas TORICO com mesma conta MP, revogação sem afetar vizinho, venda de outro UID preservada; recibo opaco sem enumeração, expirado e não logado.
- Corridas: webhook e callback simultâneos ao tombstone, fila antiga, fallback ambiente, refresh de token, perfil ausente e retry após exclusão; nenhum documento recriado.
- Worker: subcoleções/órfãos/paginação, daily_totals.last10Sales, oauth_states, erro de revogação, falha parcial, retomada sem restaurar tokens, exceção legal explicitada, notificação falha e restauração de backup.
- Regras e IAM em emuladores: writes cliente e Admin precisam falhar no estado deletion_pending sem relaxar Rules reais.
- App: reautenticação por provedor sem coletar senha MP, 202 solicitado ≠ concluído, status persistido server-side, perda de rede, retomada e confirmação final.

Esses testes backend são uma especificação, não testes já executados. Nesta missão somente testes automatizados do protótipo Flutter são adicionados. Qualquer rota, worker, Rules/IAM, nova infra/secret, revogação de integrações, retenção, comunicação automática e ativação em produção exigem nova aprovação.

### Pendências anteriores que também bloqueiam ativação segura

O início OAuth MP atual recebe userId via query (server.js:3190) e não valida ID Token; state HMAC não tem consumo único; a mesma conta MP pode aparecer em vários UIDs. Autenticar connect/refresh/status protegidos, consumir nonce uma vez e definir propriedade de grant são pré-requisitos antes de ativar exclusão pública. Tombstone não resolve sozinho spoofing de userId. Nenhuma dessas rotas foi alterada nesta missão.
