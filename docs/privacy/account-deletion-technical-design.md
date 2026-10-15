# Exclusão de conta — desenho técnico v1 (proposta)

**SOMENTE ESPECIFICAÇÃO. Não implementado, não aprovado, não ativar.** Base: 8ed110a; [SOP](account-deletion-sop.md), [matriz](account-deletion-retention-matrix.md), [auditoria](account-deletion-audit.md) e [proposta histórica](account-deletion-backend-proposal.md). A matriz ainda NÃO está aprovada; a expressão "matriz aprovada" é um requisito de liberação, não fato atual. Nenhum arquivo de Rules, rota, secret, banco ou app é alterado por este desenho.

## 1. Invariantes e fronteiras

- UID de pedido self-service vem exclusivamente de Firebase ID Token verificado, nunca de query/corpo/e-mail/ID MP. Cada pedido é de um único UID; conta MP não define titularidade TORICO.
- Receber não significa aprovar, bloquear ou excluir. Nenhuma mensagem de conclusão antes da conferência independente.
- Processamento só começa com revisão válida, versão do plano imutável aprovada por pessoas distintas e barreira persistida atomicamente. Worker não decide seu próprio alvo nem amplia o escopo.
- Falha fechada: depois do início, toda escrita ao UID alvo precisa ser negada, inclusive com token antigo, Admin SDK, callback ou integração ausente. Outra conta continua funcionando.
- Exclusão efetiva inclui Auth e dados associados; desativação é só uma etapa. Exceções de retenção são específicas, aprovadas, com prazo e comunicação; não "reter tudo por ser financeiro".
- Serviços de conta Google/MP do titular não são excluídos. Nenhum grant compartilhado pode ser revogado sem esclarecer impacto.

## 2. Modelo lógico Firestore (coleções futuras, nenhuma criada)

Datas: timestamp server-side UTC. IDs de protocolo/pedido: aleatórios opacos (mínimo proposto 128 bits), sem UID/e-mail codificados. `schemaVersion`, `revision` e validação de schema em todas as escritas administrativas. Campos abaixo são conceituais; não fornecer documentos prontos de produção.

| Caminho proposto | Campos mínimos / finalidade | Restrição e ciclo de vida |
|---|---|---|
| account_deletion_requests/{requestId} | protocol, subjectRef, receivedAt, status, phase, revision, planVersion/hash, verificationRef, createdChannel, publicReasonCode, completedAt (nulo até conclusão), retentionSummaryRef, nextReviewAt | Sem UID/e-mail/token/payload de vendas no documento comum de acompanhamento. API só devolve projeção permitida, nunca documento inteiro. |
| account_deletion_subjects/{subjectRef} | uid, tenantId se aplicável, activeRequestId, verificationAt/methodRef, contactRef opcional | Mapeamento canônico sensível e temporário, separado do protocolo. Só API de ingresso/worker autorizado e verificação com escopo mínimo. Remover conforme matriz, sem quebrar supressão segura. |
| account_deletion_uid_index/{uid} | subjectRef, activeRequestId, revision | Índice privado para impedir pedidos ativos duplicados, leitura por UID derivado. Não é campo editável de users. Prazo aprovado separado de trilha. |
| account_lifecycle/{uid} | state:active/deletion_blocked/deleted, epoch, requestId, blockedAt, policyVersion | Barreira fora da árvore users. Ausência NÃO prova conta ativa. Writers exigem existência canônica/epoch válido e, quando aplicável, integração connected. Provisionamento confiável cria active; cliente não cria. Política de migração prévia obrigatória. |
| account_deletion_requests/{id}/events/{eventId} | eventType, from/to, actorRef/type, at, revision, operationId, reasonCode, evidenceRef | Append-only por serviço; sem corpo arbitrário ou credencial. Correção gera novo evento. Referência pessoal não é anonimização. |
| account_deletion_requests/{id}/approvals/{actorRef} | decision, planHash, requestRevision, approvedAt, roleVersion | IDs distintos para verificador/aprovador; nenhuma autoaprovação/mesmo principal disfarçado. Troca do plano invalida aprovações. |
| account_deletion_jobs/{requestId} | stage, expectedEpoch, planHash, checkpoint/cursor opaco, leaseOwner, leaseUntil, fencingToken, attempts, retryAt, lastErrorCode | Sem cópia de token ou dados de vendas. Coordenação de entrega pelo menos uma vez, não promessa de exactly-once. |
| account_deletion_outbox/{operationId} | requestId, eventType, schemaVersion, status, attempts, retryAt | Criação junto com mudança de estado; worker/dispatcher privado. Corpo mínimo sem destinatário/token; resolve contato autorizado na hora. |
| account_deletion_receipts/{digest} | requestId, expiresAt, revokedAt, scope:status_read, generation, acknowledgedAt | Hash de segredo opaco, nunca segredo bruto persistido. Sem listagem pública ou vínculo com dados comerciais. Expiração e recuperação precisam de aprovação. |
| account_deletion_idempotency/{scopedDigest} | subjectRef, keyDigest, bodyDigest, requestId, createdAt, expiresAt | Namespace por UID/tenant e operação; comparar corpo normalizado. Chave não funciona como autenticação. Limites/TTL aprovados antes da ativação. |
| account_deletion_evidence/{id} | etapas/contagens, versões, assinatura lógica dos revisores, retentionRefs, verifiedAt | Sem screenshots do banco, IDs de pagamento, valores, rawPayload, tokens ou export completo da conta. |

Um armazenamento temporário privado de retry de revogação pode ser necessário, mas só será especificado/implantado após revisão do provedor. Reutilizar a chave existente não autoriza novo uso; não criar secret, guardar token em jobs/outbox nem copiar todo documento de integração como backup.

### Acesso a dados

- **Cliente Android/PWA/iOS:** nenhuma leitura/escrita/list/query direta nas coleções acima, mesmo autenticado, admin claim ou proprietário. Consulta via API com projeção própria e checagem de sujeito.
- **Administrador humano:** sem acesso direto pelo SDK Web ao Firestore e sem credencial Admin no app. Painel administrativo futuro fala com API privada de administração.
- **API self-service:** valida identidade, cria pedido/índices/evento/outbox em transação; não tem operação pública de execução. GET proprietário carrega subjectRef e compara UID/tenant a cada requisição.
- **API administrativa:** identidade corporativa/IAM + autorização por papel em fonte server-side com revogação, step-up recente, escopo por caso. Conta piloto/Firebase comum ou custom claim isolada não confere acesso. Proibição de impersonation/arbitrary UID.
- **Worker:** identidade de serviço própria; apenas job aprovado e alvo resolvido internamente, allowlist de coleções de domínio, trilha protegida. IAM Firestore frequentemente não limita caminho de documento: não prometer isolamento por coleção só com IAM; combinar serviço/DB segregado quando viável, gateway de dados e verificações de código. Uma conta de serviço com acesso amplo é risco residual a aprovar.
- **Regras futuras:** negar integralmente as coleções privadas e adicionar controle de lifecycle às escritas/leitura de domínio conforme política, sem ampliar permissões existentes. Desenho de regra é a intenção "deny all" para controle; não alterar firestore.rules nesta missão. Verificar permissões sobrepostas: uma regra permissiva não é anulada por outra deny.
- Excluir campos de índice quando desnecessários (contatos/referências/erros), índices só para filas e operação paginada. TTL só para itens cujo expurgo não remova a barreira cedo: TTL é assíncrono e não substitui validação de expiração em requisição.

Admin SDK ignora Security Rules: autorização e barreiras precisam existir também no servidor. [Firebase Rules](https://firebase.google.com/docs/firestore/security/get-started).

## 3. Estados públicos e internos

| Público | Fase interna | Entrada/saída permitida |
|---|---|---|
| received — Recebido | intake | Só após transação durável; não confirma identidade administrativa nem executa bloqueio. Vai para verifying. |
| verifying — Em verificação | identity_review, inventory, policy_review, awaiting_approvals | Reautenticação e intenção conferidas; inventário e matriz vigentes; duas aprovações. Vai para processing ou rejected antes do ponto irreversível. |
| processing — Em processamento | quarantining, sessions_revoked, revoking_grants, deleting_records, verifying_result | Começa com barreira+job atomicamente gravados. Falhas ficam processing com subfase retrying/action_required e próxima revisão. Nunca chamar falha parcial de rejected/concluded. |
| completed — Concluído | verified_complete | Só conferência independente satisfaz invariantes. `completionScope`:full/operational_with_retention; listar exceções e expurgo. Não declarar exclusão total havendo cópias residuais. |
| rejected — Rejeitado | rejected_before_execution | Apenas antes do bloqueio irreversível, com justificativa pública proporcional e canal de reavaliação. Sem afirmar que houve exclusão. |

Razões públicas enumeradas: identity_not_verified, confirmation_missing, scope_unresolved e policy_review_required (avaliar se é impedimento temporário em verifying, não rejeição automática). Motivo interno de fraude permanece restrito; justificativa pública deve permitir corrigir/contestar sem revelar dados de terceiros. Falta de resposta/erro de rede não equivale a autorização nem rejeição imediata. Duplicata volta ao pedido já existente, não vira recusa do direito.

`withdrawn` pode ser fase terminal separada para desistência confirmada antes da execução; decisão de produto pendente. Não mapear para rejected como se houvesse recusa do operador. Revisão de rejected cria novo evento/ciclo ou novo pedido vinculado com evidência, nunca reescreve a justificativa passada. Nenhum terminal completed volta a active automaticamente.

## 4. Contratos de endpoints (apenas nomes/contratos, NÃO rotas instaladas)

Todos TLS, JSON com tamanho limitado, schema fechado, Cache-Control:no-store, sem dados pessoais em logs de URL/corpo. Não aceitar operações por GET. Access-Control-Allow-Origin específico no Web não substitui token no nativo. Rate limits por sujeito/ação e controles de abuso; App Check é defesa adicional, não autorização. Nenhuma lista global de pedidos é pública.

### 4.1 Registro self-service

**POST /v1/account-deletion/requests**

- Authorization: Bearer Firebase ID Token. Admin verifyIdToken com checkRevoked=true; validar aud/iss/projeto/tenant e UID do token, Auth existente/não desabilitado. Não aceitar custom token como ID Token. UID/e-mail/MP ID/client role no corpo/query ou header alternativo:400.
- Reautenticação: `auth_time` no passado e dentro de 5 minutos (proposta a aprovar); timestamp futuro ou ausente é negado. Validade de token/iat recente não substitui auth_time. No erro de autenticação:401 genérico; auth_time antigo:403 reauthentication_required, sem iniciar pedido.
- Corpo fechado: confirmation=delete_account, policyVersion e noticeVersion publicados/aceitos. O servidor não aceita status, plano de exclusão, retention overrides ou canal arbitrário; canal deriva do cliente aprovado, sem efeito de autorização. Sem seleção de UID.
- Idempotency-Key opaco de alta entropia, persistido localmente ANTES de enviar; limites de tamanho. Canonicalizar corpo. Transação cria índice único por UID, pedido received, evento e outbox de revisão; não executa exclusão e NÃO cria barreira neste momento.
- 202: requestId, protocol, status:received, receivedAt, revision e mensagem "Pedido recebido. Sua conta ainda não foi excluída". Não retorna tokens, e-mail, UID ou dados MP. Replay idêntico retorna o mesmo pedido; chave com corpo distinto:409. Novo pedido com outra chave, mas mesmo UID já ativo, retorna o pedido existente ao seu titular; não duplica trabalho.
- Timeout com commit incerto: cliente mantém estado "envio não confirmado" e repete mesma chave/consulta seu pedido, nunca exibe protocolo inventado. 503 ou falha antes do commit não é registro confirmado. Pode haver confirmação posterior do servidor sem novo pedido.

### 4.2 Consulta e acompanhamento independente

**GET /v1/account-deletion/requests/current**: Bearer ID Token válido do próprio titular, resolve índice internamente; responde somente projeção pública. **GET /v1/account-deletion/requests/{id}**: mesma checagem de propriedade/tenant. ID aleatório sozinho não autoriza; pedido alheio/inexistente:404 indistinguível, sem ownerUid na resposta.

**POST /v1/account-deletion/requests/{id}/status-receipts**: requer titular autenticado e reautenticação recente antes da quarentena; emite segredo aleatório de 256 bits, armazena somente hash e escopo status_read. Emissão separada do registro resolve perda da resposta inicial sem precisar recuperar segredo bruto. Se resposta se perder, nova emissão após reautenticação; rotação/revogação anteriores explícitas e atômicas. Sem colocar recibo em redirect/link, analytics ou protocolo; `no-store` em todas as respostas. Não devolver o segredo em replay de criação de pedido.

**GET /v1/account-deletion/status**: Authorization:DeletionReceipt <segredo>, sem Firebase e sem requestId na URL. Lookup por hash com validade, scope e revogação; responde só protocolo, status, mensagem de progresso, motivo público e retenções comunicáveis. Nunca autoriza exclusão, cancelamento, reativação, download de dados ou listagem. Respostas de recibo inválido/expirado:401 genérico; limitar tentativas. TTL/status de consulta não representa duração de retenção de outros dados.

Antes de revogar Auth, confirmar que o canal de acompanhamento foi provisionado/entregue ou alternativa proporcional está disponível. Sem recibo após perda do dispositivo: recuperação futura por mecanismo de identidade seguro e sem novo cadastro; não tratar simples protocolo/e-mail informado como prova. Canal e expirações ainda bloqueiam ativação até aprovação.

### 4.3 Administração privada

| Contrato proposto | Controle e resultado |
|---|---|
| GET /internal/account-deletion/requests (paginado) e /{id} | IAM/identidade admin + papel de atendimento, filtros permitidos; projeção mínima. Detalhes de UID só a verificador com caso atribuído. Sem acesso pelo app do comerciante. |
| POST /internal/account-deletion/requests/{id}/verification | Evidência referenciada/resultado; papel verificador; nenhuma senha/código anexado. Validar revisão esperada. |
| POST /internal/account-deletion/requests/{id}/plans | Produzir manifesto allowlist de coleções/contagens, impacto de grant, policyVersion, hash e epoch esperado; sem dumps. Nova versão invalida aprovações. |
| POST /internal/account-deletion/requests/{id}/approvals | Dois principais humanos distintos com papéis autorizados; step-up, plano/hash/revision vinculados. Idempotente por ator/versão; não autoaprovar. |
| POST /internal/account-deletion/requests/{id}/reject | Só verifying/received e antes do ponto irreversível; motivo público+referência interna, autor/revisor e audit trail; não abrir conta em exclusão. |
| POST /internal/account-deletion/requests/{id}/start | Papel executor, duas aprovações válidas e invariantes. Transação grava lifecycle deletion_blocked/epoch incrementado, job, estado processing, evento/outbox. Job traz só requestId/planHash/epoch; UID resolvido no servidor. |
| POST /internal/account-deletion/requests/{id}/review-result | Revisor independente do executor, evidência de checagem, retenções e plano/hashes; só pode finalizar se etapas comprovadas. Falta de evidência mantém processing. |

Toda mutação exige Idempotency-Key, expectedRevision/If-Match e política de autorização vigente, inclusive em retries. 401 identidade ausente,403 papel insuficiente,404 não atribuído,409 conflito de versão/estado,422 pré-condição funcional ausente. Nenhuma requisição aceita path Firestore livre, filtro de UID livre ou script do operador.

## 5. Identidade recente nas plataformas

Android/PWA: reautenticar na sessão corrente via provedor Firebase correspondente, checar UID antes/depois, obter ID Token após sucesso e transmitir apenas por TLS. Não usar signIn que cria/troca conta como substituto de reauthenticate. Google usa UI oficial por clique explícito; senha enviada só ao SDK Firebase, nunca ao endpoint de exclusão. Cancelamento/erro mantém pedido não enviado. Allowlist não é autorização administrativa.

iOS futuro: mesmo contrato Firebase e estado; adaptar reauth ao provedor existente e chaves seguras da plataforma. Se Sign in with Apple for adotado, incluir revogação aplicável em desenho próprio; não presumir SDK/configuração disponíveis. O fluxo de exclusão não exige suporte/e-mail obrigatório para apps comuns; operador pode trabalhar manualmente nos bastidores.

Android: recibo em armazenamento seguro da plataforma, sem backup exportável; não SharedPreferences texto puro. PWA: não persistir recibo bruto em localStorage. Definir desenho BFF com cookie HttpOnly/Secure/SameSite, CSRF e origem ou alternativa revisada de sessão em memória/recuperação. Isso exige revisão de domínios/infra em missão futura; nenhum cookie/CORS/DNS é alterado aqui. Até decisão segura para Web e recuperação, ativação fica bloqueada.

Revogar refresh tokens não equivale a eliminar instantaneamente todos os ID Tokens em todos os consumidores; usar checagem revogada e barreira de dados. [Firebase tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens), [sessões](https://firebase.google.com/docs/auth/admin/manage-sessions).

## 6. Isolamento da exclusão e eventos tardios

Ponto de linearização: transação start grava barreira/epoch, processing, job e outbox. Antes dela, pedido verifying não muda vendas/integração. Depois dela, writers que leram lifecycle anterior devem conflitar/repetir a transação e negar gravação. Chamadas externas nunca ocorrem dentro de transação Firestore sujeita a retry.

| Entrada | Leitura/validação obrigatória futura | Quando conta está bloqueada/deletada |
|---|---|---|
| Webhook MP → saveSale | Resolver identidade/integração exatas; assinatura/verificação oficial; na transação ler lifecycle, perfil canônico/epoch e integração connected. Checar qualquer source, não só webhook. | Não gravar venda/resumo/perfil; confirmar descarte de forma compatível com provedor para evitar retries infinitos, sem revelar UID na resposta. Se indisponibilidade de DB impedir decidir, não confirmar falsamente: retry controlado, sem escrita. |
| Connect/callback/refresh MP | Connect autenticado, state de uso único vinculado a UID/epoch e propósito; callback valida state e lifecycle novamente dentro da transação de persistência. | Não emitir state novo nem persistir token/status. Token obtido em chamada externa antes do bloqueio vai para compensação/revogação segura, sem reabrir integração. |
| Jobs, Admin, simuladores e fontes futuras | Mesmo gateway/transação, alvo derivado do job/identidade, nunca fallback de UID fixo. | Ignorar alvo bloqueado; não ativar REDE/Scheduler para realizar testes. |
| Escritas/leituras do cliente | Rules futuras: ciclo de vida + usuário correto; negar recriação de users/requests/integrações pelo cliente bloqueado e acesso a dados de domínio durante exclusão. | App exibe acompanhamento, encerra listeners/sessão quando requerido; Admin ainda exige proteção no código. |
| Restore/export/filas antigas | Ambiente isolado, reconciliar ledger de exclusões vigente antes de liberar tráfego; writer exige conta ativa mesmo quando tombstone expira. | Não restaurar dados excluídos, tokens ou aprovações antigas para operação. |

Migração: UID legado sem lifecycle não pode ser simplesmente bloqueado em massa sem validação. Primeiro inventário somente leitura e plano de backfill em staging, então bootstrap server-side aprovado para conta canônica ativa e transação com checagem Auth. Nenhum fallback automático no webhook cria lifecycle para UID ausente; caso não provisionado vira quarentena operacional com revisão, não gravação permissiva. O desenho não aprova backfill de produção.

Fila de eventos de conta bloqueada não deve conservar payloads indefinidamente. Auditar somente contagens/códigos e prazo mínimo aprovado. Tombstone fora de users tem retenção própria, nunca apagado pela recursão de dados. Novo cadastro voluntário do mesmo e-mail gera novo UID: não anexar integrações/histórico antigos automaticamente.

## 7. Credenciais Mercado Pago e trabalhador

A [documentação oficial MP](https://www.mercadopago.com.br/developers/en/docs/security/oauth/management) informa que revogar uma autorização vendedor-aplicação elimina tokens e grants temporários associados. Logo, revogar pode ter efeito maior que remover um documento TORICO. Não foi identificado/homologado aqui um endpoint de revogação para executar; nenhum URL, escopo, OAuth client ou webhook é modificado.

Antes de implementar o adaptador: distinguir vendedor, autorização/grant, versão/token e todos os UIDs que usam o mesmo grant. Duplicidade por vendedor não prova grant distinto nem permite revogar cegamente. Se propriedade/impacto não forem inequívocos, permanecer processing/action_required, credenciais bloqueadas no TORICO e revisão humana; não afetar conta vizinha nem alegar revogação concluída.

Estágios retomáveis do job, todos em escopo único:

1. **Guard:** carregar pedido/plano/approvals/policyVersion, resolver UID server-only, conferir epoch e lease/fencing. Sem aprovações, nenhum efeito externo. Mudar plano invalida start/lease e exige nova conferência.
2. **Sessions:** depois de canal de acompanhamento confirmado, revogar sessões e desabilitar Auth. Registrar resultado mínimo. Barreira protege enquanto chamadas externas estão em andamento.
3. **Grant revocation:** coletar mínimo token criptografado no armazenamento privado aprovado, sem remover a chave global. Revogar só grant homologado. Não armazenar plaintext em disco/logs/outbox; descriptografia somente em memória server-side, sem prometer zeroização garantida em runtime gerenciado. Renovação/refresh após corte é proibida.
4. **Credential purge:** depois de revogação comprovada ou decisão formal específica de tratamento do impedimento, apagar tokens em todas as cópias operacionais/retry; limpar integração/status e states. Credencial ainda utilizável sem destinação segura impede completed. Token de callback tardio também tem etapa de compensação por versão e nunca substitui o vigente.
5. **Domain purge:** executar manifesto aprovado de subcoleções/órfãos, sales, payloads, daily_totals/last10Sales, requests, metadados e perfil; paginar com checkpoint durável, sem incluir controles/evidência no escopo recursivo de users. Apagar pai não comprova apagar filhos. Retenções saem do uso operacional com acesso restrito e prazo, sem copiar tudo "por garantia".
6. **Auth purge:** remover usuário Auth do UID confirmado; ausência já verificada no retry é sucesso idempotente desta etapa, não prova das demais. Não apagar conta Google/MP externa, allowlist ou dados de outro UID.
7. **Residual reconciliation:** confirmar tratamento de backups/logs/caches/fornecedores e retenções aprovadas; estabelecer expurgos posteriores verificáveis. Não assumir que TTL já executou ou que cache offline foi apagado remotamente.
8. **Independent verification:** revisor diferente do executor confere critérios finais em leitura autorizada, evidência e conta vizinha. Só transição protegida pode gravar completedAt, completionScope e outbox de notificação.

Lease com prazo, renovação, cursor e fencingToken monotônico evita que worker antigo sobrescreva checkpoint do novo. Validação antes de cada etapa/lote; side effect externo pode se completar depois da perda do lease: reconciliar estado do provedor, nunca supor exactly-once. Revogação é vinculada à geração do grant, sem revogar eventual nova autorização de outro ciclo. Se provedor não oferecer consulta/idempotência suficiente, bloquear e escalar em vez de repetir comando ambíguo.

Retentativas: exponential backoff com jitter, orçamento/limites propostos para aprovação, erros categorizados sem payload bruto. Falha parcial mantém processing e barreira; lease vencida não libera conta. Supervisor de tarefas órfãs usa outbox persistente; retries não criam protocolos/filas novos por entrega repetida. Kill switch impede novas etapas irreversíveis, não desfaz as já feitas nem abre o UID. Falha de notificação fica em trilha separada.

## 8. Dados residuais e conclusão

Aplicar a [matriz](account-deletion-retention-matrix.md) somente após aprovação de versão/hash vinculada ao plano. Por categoria, definir responsável, necessidade/base validada, marco, prazo/data, local, acesso, comprovação de expurgo e comunicação. Sem aprovação, não inventar meses/anos e não iniciar exclusão real. Logs/backups/trilha/tombstone são dados associados enquanto vinculáveis. Nunca presumir anonimização de UID hash ou retenção fiscal genérica de vendas.

Vendas e totais eliminados integralmente no escopo; limitação de últimas 10 é só UI, não escopo de exclusão. Backups/PITR/exportações têm ciclo/inventário verificado, sem uso operacional até expiração; qualquer restauro reaplica supressão antes de reads/writes. No dispositivo, limpar caches após encerramento conforme estratégia aprovada, sem prometer ação remota em dispositivo offline. Dados em processadores requerem confirmação/retenções específicas; contas/registros independentes do MP não são removidos pelo TORICO.

Critérios cumulativos de completed: conta Auth ausente; nenhum token/grant operacional não tratado; dados ativos eliminados; evento/callback tardio não recria; retenções enumeradas e isoladas com prazo; plano de cópias e notificações auditável; resultado revisado por identidade independente. Falha técnica pendente não é retenção legal nem justifica completed_with_retention.

Notificação final usa outbox com conteúdo mínimo/protocolo e canal verificado; não inclui UID, IDs de venda, token ou link de recibo em claro. completedAt técnico e deliveryAt são separados. Mensagem afirma exclusão da conta operacional e dados efetivamente conferidos; se completionScope=operational_with_retention, especificar categoria/motivo/prazo/expurgo residual e não "tudo apagado". E-mail falhar não reabre conta nem marca entrega como sucesso. Status acessível sem Auth original e atualização posterior de expurgo residual.

## 9. Refinamentos e decisões abertas

- **ADR-01 (proposto):** em relação à proposta inicial, separar intake durável de start destrutivo. Barreira não nasce no POST received; só após verificação/dupla aprovação. Evita desativar conta com pedido ainda não revisado e torna rejected previsível antes da execução. A proteção contra eventos começa atomicamente no start, sem janela entre bloqueio e job.
- **ADR-02 (proposto):** recibo de acompanhamento emitido em chamada separada/reautenticada. Hash-only não permite reconstruir segredo perdido na resposta inicial; não usar criptografia de recibo bruto para fingir idempotência. Replay da criação recupera protocolo, não segredo.
- **ADR-03 (proposto):** todas as coleções de controle server-only; clientes/admin UI via API. Sem Rules permissivas por UID ou custom admin claim em coleção sensível. IAM amplo ainda demanda isolamento de serviço e revisão.
- **ADR-04 (proposto):** rejeição somente pré-execução; falha parcial permanece processing e exige intervenção, sem falso sucesso ou desbloqueio automático.

Decisões que bloqueiam implementação/ativação: matriz/prazos ainda propostos; principais humanos e revisor independentes; IAM/ambiente administrativo; migração de lifecycle para usuários existentes; revogação/grants MP compartilhados e nonce; transporte/recuperação do recibo PWA/iOS/Android; fonte de identidade e step-up admin; infraestrutura outbox/worker; índices/limites/leases/retry/TTL e orçamento; notificações; política de restore/expurgo; revisão deste desenho. Nenhuma decisão é aprovada pelo mero commit.

## 10. Referências e situação de evidência

Fontes primárias consultadas em 15/10/2026 UTC: Firebase verificação de ID Tokens, sessões, Security Rules e [transações](https://firebase.google.com/docs/firestore/manage-data/transactions); MP gestão de Access Token. Contratos/limites de tempo/coleções são propostas TORICO, não exigências numéricas atribuídas aos provedores. Implementação atual e riscos vêm da auditoria de código existente; não houve leitura de dados de clientes nem inspeção do ambiente em produção.

### Complementos de revisão v1

- Confirmação de entrega do acompanhamento: propor `POST /v1/account-deletion/status/ack` autenticado APENAS pelo recibo status_read, registra que o cliente obteve aquele recibo. Não confirma exclusão nem a inicia. Start exige ack válido da geração de recibo vigente ou canal alternativo seguro aprovado; perda de resposta do ack permite retry idempotente. Rotação invalida ack anterior. Não desabilitar Auth contando apenas com o fato de o servidor ter enviado uma resposta.
- Identidades administrativas: actorRef deve resolver a pessoa canônica em diretório/controlador de papéis. Duas contas/aliases da mesma pessoa não contam como dois revisores. Exceção operacional demanda desenho e aprovação próprios, sem reduzir o requisito silenciosamente.
- Dependência de Auth/DB indisponível: responder 503 seguro, sem classificar como credencial inválida/cancelamento ou gravar conclusão. Nenhum sucesso em falha de autorização/autenticação não decidida.


Índice de pedido ativo: ao encerrar/rejeitar, liberar somente o ponteiro cujo requestId ainda corresponde ao caso, em compare-and-swap/transação; evento antigo não pode remover índice de pedido posterior. Essa limpeza não apaga lifecycle nem reativa UID concluído. Eventos/recibos/metadata têm schema versionado e não são alternativa para editar perfil.

Escopo de tenancy v1: projeto TORICO atual em modo single-tenant; tokens com tenant não configurado devem ser rejeitados. O uso de caminhos por UID pressupõe esse escopo único. Habilitar múltiplos tenants exige desenho e migração próprios com chave composta tenant+UID em TODOS os índices, lifecycle, pedidos e caminhos de domínio; não basta incluir tenantId num campo e continuar usando chave UID compartilhada. Nada de multitenancy é habilitado nesta proposta.

## Fase 1 de recebimento — implementação local para revisão

O [relatório de implementação](account-deletion-intake-implementation.md) registra endpoints de intake/status, protocolo/idempotência e testes isolados. Destruição, lifecycle/start, revogação e administração continuam NÃO implementados. Wiring do servidor aceita somente emuladores loopback de projeto demo fora de Cloud Run; flag Flutter é false por padrão. Nenhum deploy ou ativação em produção foi realizado. Este adendo preserva as decisões/propostas acima e não aprova retenções ou futuras fases.
