# Exclusão de conta — etapas, testes e rollback (proposta)

Nenhuma implementação, rota, coleção, teste destrutivo ou deploy é ativado. Complemento ao [desenho técnico](account-deletion-technical-design.md), [SOP](account-deletion-sop.md), [matriz pendente](account-deletion-retention-matrix.md) e [checklist](account-deletion-review-checklist.md). Casos abaixo são especificações para automatizar em missão futura; não são resultados executados nesta entrega documental.

## 1. Etapas e gates de implementação

| Etapa futura | Entrega e limites | Gate para avançar |
|---|---|---|
| D0 — revisão deste desenho | Decidir estados, retenção, papéis, identidade, receipt/recuperação por plataforma, grants, migração e prazos. | Aceite técnico/privacidade/operacional e nova autorização para implementar. Não há aceite implícito nesta branch. |
| D1 — núcleo puro offline | Schema fechado, máquina de estados, validação de token por adapter fake, scope/idempotência, projeções, approvals/planHash, erros sem PII. Sem importar server.js/abrir porta. | Testes unitários/invariantes e revisão independente. Sem rede ou credencial real. |
| D2 — emuladores e controles | Fixture Firestore/Auth isolada, Rules propostas só em diretório de teste (não arquivo de produção), transações/outbox, acesso negado e duas contas fictícias. | Testes de isolamento/retries/coleções desconhecidas e infraestrutura de testes com fail-safe que recusa projeto real. |
| D3 — ingestão/barreira | Gateway comum a todos writers, callback/state/epoch, remoção de fallback permissivo, plano de bootstrap/backfill. Alterações serão PR separado, sem ativar exclusão. | Cobertura inventariada de TODOS writers; sem bypass Admin/cliente; migração revisada e ensaiada. Não tocar REDE/Scheduler de produção. |
| D4 — administração/worker em staging | Roles/step-up, duas pessoas, planos, job leases/fencing, dry-run com contagens, adapters de provedor simulados primeiro. | Testes de falha/crash/restore, verificações de conta vizinha e grant compartilhado. Sem tokens reais ou solicitações de clientes. |
| D5 — clientes por plataforma | Android/PWA e futuro iOS: reauth, confirmação, receipt protegido/ack, status e retomada. Protótipo mailto não é transporte autenticado de registro. | Testes de UX, perda de rede/dispositivo e acessibilidade, status nunca inventado. iOS exige ambiente/homologação futura, não é assumido pronto. |
| D6 — prontidão produtiva | Play/Apple, página/privacidade, operação, retenções, auditoria, IAM e restore aprovados. | Nova autorização explícita para implantar controles e só depois para habilitar intake/start. Nenhum APK/AAB ou deploy nesta missão. |
| D7 — ativação controlada futura | Flags separadas intake/review/start/worker, padrões OFF. Execução restrita somente após liberação e casos de staging aprovados. | Aprovação individual de cada operação real, monitoramento e suporte; nunca iniciar com conta real como teste. |

Separar flags ajuda conter erro, mas não autoriza publicar endpoints sem revisão. Nenhuma flag/secret é criado agora. REDE e Scheduler REDE ficam fora do rollout. Nova infraestrutura/credencial, mudanças de OAuth/Rules/Cloud Run ou consulta de banco real exigem autorização própria.

## 2. Plano de testes automatizados

Fixtures: UID fictícios `fixture-owner-a` e `fixture-owner-b`, tenants fictícios, tokens de emulador/fakes, grants artificiais e relógio controlado. Não usar e-mails/UIDs/IDs MP reais. Test runner futuro recusa URLs/credenciais/projetos de produção; resets limitados ao workspace/emulador designado, sem exemplos de comando destrutivo nesta documentação. API não ativa em ambiente público. Assertions conferem estado persistido e side effects dos adapters, não só HTTP.

| ID / camada | Cenário | Asserção de segurança e funcionalidade |
|---|---|---|
| AUTH-01 contrato | Sem token, assinatura inválida, custom token, issuer/audience/tenant errado, expirado, usuário disabled/deleted, revogado | Negar registro/consulta conforme contrato; zero gravações e zero chamada de revogação/exclusão. |
| AUTH-02 reauth | Token iat novo com auth_time antigo, ausente ou futuro; auth_time na fronteira proposta de 5 min | Apenas reauth real dentro da janela permite registro sensível. Clock fixo; limites sujeitos à aprovação. Erro não vira cancelamento. |
| AUTH-03 sujeito | UID/e-mail em query/body/header alternativo, tenant cruzado, ID MP de outra pessoa | Schema rejeita; UID sempre do verificador do token; conta B intacta. |
| AUTH-04 dependência | Auth/DB fora do ar ou timeout na checagem | 503 sem falso 202/401 genérico de usuário inválido; repetição segura posterior. |
| ACL-01 Rules | Usuário A lê/grava/lista controle próprio ou de B; admin claim em cliente | Negado em todos os casos. Projeção via API é o único canal de status. Rules permissivas sobrepostas detectadas. |
| ACL-02 API | A consulta requestId de B, inexistente ou tenta lista global | Mesmo 404 para alheio/inexistente; sem metadados/UID/contagens de B. Lista não exposta. |
| ACL-03 server | Admin SDK/service account alcança DB, mas papel/atribuição/revisão/epoch estão incorretos | Código nega apesar de bypass das Rules; conta de serviço não amplia escopo por path arbitrário. |
| IDEM-01 intake | Mesma chave/corpo, chaves diferentes para mesmo UID ativo, requests paralelos | Um protocolo ativo, evento/outbox único por transição. 202 não bloqueia conta nem inicia exclusão. |
| IDEM-02 conflito | Mesma chave com corpo/policyVersion distintos; A/B reutilizam string de chave | 409 no sujeito correto; namespace não retorna pedido de outro UID. |
| NET-01 commit | Queda antes do commit; commit confirmado e resposta perdida; app encerra antes do retorno | Primeiro caso sem registro; segundo encontra o mesmo pedido; cliente mostra "envio não confirmado" até resposta persistida. Não inventa pedido nem reenvia com chave nova. |
| RCPT-01 emissão | Recibo aleatório, perda de resposta, nova emissão, rotação e ack perdido | Criar pedido não exige devolver segredo antigo; retry/rotação seguros, hash-only e ack válido antes do start; nenhum segredo em Firestore texto puro/log/URL. |
| RCPT-02 consulta | Recibo inválido/expirado/revogado, replay após rotação, brute force e tentativa de deletar com recibo | 401 genérico/rate limit; receipt só lê status, nunca muta conta ou acessa perfil. Expiração validada mesmo antes do TTL efetuar remoção. |
| RCPT-03 plataformas | Android backup/export, Web XSS/CSRF/cookie ou fechamento de aba; perda do dispositivo e Auth já removido | Transporte/armazenamento aprovados; recuperação proporcional sem cadastro novo, UID em URL ou email obrigatório como única via Apple. Nenhum secret em localStorage/SharedPreferences texto puro. |
| ADM-01 dupla conferência | Mesmo ator, aliases da mesma pessoa, papel revogado, plano alterado depois de aprovação, step-up antigo | Start negado; revision/hash/atores distintos obrigatórios, sem reutilizar aprovação velha. |
| ADM-02 estados | Rejected com justificativa antes do início; tentativa rejeitar após purge parcial ou concluir cedo | Antes: sem exclusão e justificativa segura; depois: processing/action_required, nunca rejected/concluded para esconder falha. |
| ADM-03 início | Duplo clique/duas requisições start, queda entre barreira/job/outbox | Transação atômica produz um corte/job; sem intervalo no qual evento grave após corte antes de existir barreira. |
| EVT-01 webhook | Evento inicia antes do start e tenta commit depois, webhook tardio/duplicado | Retry da transação vê barreira, zero recriação de sales/daily_totals/users; B continua recebendo vendas. |
| EVT-02 callback | State antes do corte, replay/nonce usado, refresh e resposta token após quarentena | Nada persiste; compensação segura por geração sem reabrir integração. Não usa OAuth real. |
| EVT-03 writers | Fonte alternativa, teste/simulador, fallback ambiente, conta sem profile/lifecycle, Admin e cliente legado | Nenhum bypass; inexistência nega gravação; provisionamento é explícito e não nasce do webhook. |
| EVT-04 migração | Usuários legados sem lifecycle, bootstrap simultâneo com start | Sem bloqueio em massa não revisado nem permissão automática; transação e plano de migração preservam conta vizinha. |
| GRANT-01 propriedade | Mesmo vendedor MP, grants distintos ou grant compartilhado por dois UIDs | Revogar somente geração/escopo homologado; caso ambíguo bloqueia execução dessa etapa, não afeta B. |
| GRANT-02 revogação | Timeout com resultado externo incerto, grant já revogado, resposta token sensível, retry sem suporte idempotente | Reconciliar ou escalar; sem duplo efeito cego, refresh novo ou token em log/outbox. Não declarar revogado só porque documento foi removido. |
| WORK-01 leases | Entregas repetidas, worker cai após side effect antes de checkpoint, lease expira e worker antigo continua | Fencing nas escritas, reconciliação de efeito externo, progressão monotônica; não prometer exactly-once. |
| WORK-02 dados | Mais de um lote, subcoleção órfã/desconhecida, resumos/last10Sales, requests/states e índices | Manifesto completo, nenhuma exclusão de B ou da barreira; parent delete não basta; unknown schema impede conclusão automática. |
| WORK-03 Auth | Falha antes/depois de desabilitar/remover Auth; user-not-found em retry | Ausência de Auth só conclui a etapa correspondente; restantes ainda verificadas; canal status continua acessível. |
| RET-01 política | Matriz sem aprovação, hash mudou, prazo inexistente, retenção de vendas genérica | Start/conclusão negados até resolver; nenhuma conservação indefinida ou conclusão falsa. |
| RET-02 cópias | Backup/PITR restaurado em ambiente isolado e replay após expirar tombstone | Supressão reaplicada antes de tráfego; writers negam UID ausente; sem tokens/histórico reintroduzidos. |
| RET-03 cache | App offline/reinstalado, listeners com token antigo, tentativa sincronizar cache | Não recria dados cloud; limitações locais comunicadas. Não afirmar limpeza remota de dispositivo offline. |
| FIN-01 conferência | Executor tenta aprovar resultado; dados residuais não previstos; tokens ainda utilizáveis | Falha na revisão e estado processing, sem completedAt. |
| FIN-02 retenções | Conclusão operacional válida com cópias residuais aprovadas vs eliminação completa | completionScope e texto corretos, categorias/motivos/prazos; expurgo posterior auditado. |
| MSG-01 outbox | Conclusão persistida mas e-mail falha, entrega duplicada, processo cai antes de publicar evento | Estado técnico não é revertido/forjado; retry da notificação sem repetir exclusão, destinatário já verificado, sem segredo/PII desnecessária. |
| LOG-01 privacidade | Tokens sentinela, recibos, corpo de venda, UID/e-mail em erros, URLs e traces | Capturas de teste falham se credencial/PII desnecessária aparece; comprovante só referências/contagens; acesso à trilha restrito. |
| UI-01 estados | Android/PWA/iOS: cancelar reauth, falha de rede, recebido/verificando/processing/rejected/completed | Sem troca de UID ou envio automático ao abrir tela; estado server-side, justificativa segura e caminho de recurso; não mostra conta excluída em 202. |

## 3. Critérios de aceite de revisão

Todos os casos obrigatórios aprovados em isolamento, revisão de invariantes/ameaças, testes de duas contas/grants, inventário completo de writers e política aprovada. Métrica não é só percentual de cobertura: comprovar nenhuma escrita depois do corte, nenhuma destruição antes de duas aprovações, nenhum acesso entre usuários e nenhuma conclusão falsa. Logs/evidência sem dados reais; resultados identificam versão do código/schema/plano e simulador, não certificados ou dumps de produção.

Revisão específica do acesso administrativo e recuperação de recibo por plataforma é bloqueadora. Índices, limites de lote, retries, leases, taxas, TTL e orçamentos não são aprovados por esta especificação. Falha intermitente não pode ser resolvida desabilitando autenticação, Rules ou verificação de propriedade.

## 4. Rollback e contenção

| Momento | Ação futura segura | O que NÃO fazer |
|---|---|---|
| Antes de implantar qualquer controle | Reverter documentação/código não ativado após revisão. Nesta missão somente Git muda. | Não mexer em banco/contas para "testar rollback". |
| Após intake, antes de start | Desabilitar intake novo e congelar despacho/start; manter consultas e protocolos persistidos; comunicar pendência com dono. | Não apagar pedidos, receipts ou trilha para esconder falha; não declarar exclusão. |
| Após start, sem purge completo | Kill switch impede próximas etapas irreversíveis; barreiras e reader/writer guards continuam ativos; supervisionar efeitos já em voo, registrar checkpoints e reconciliar. | Não reativar conta automaticamente, restaurar tokens ou fazer rollback para backend antigo que ignora lifecycle. |
| Após purge parcial | Retomar somente plano aprovado corrigido; revisão do impacto e comunicação verdadeira. | Não prometer restauração, reatribuir UID, trocar grant ou voltar para active. |
| Após completed | Manter supressão, consulta permitida e expurgos residuais pelo prazo aprovado; correção de software preserva política de exclusão. | Não restaurar perfil/histórico/backups excluídos nem reutilizar credenciais. |
| Restore de infraestrutura | Snapshot isolado; carregar ledger vigente independente da cópia restaurada; reexpurgar alvos; verificar conta vizinha e barreiras antes de tráfego. | Não reintroduzir estado anterior de grants/aprovações/receipts revogados. |

Depois que contas entrarem em processamento, versões de código anteriores às barreiras não são rollback seguro. Manter "versão piso" compatível e rota de correção progressiva; rollback de interface pode esconder entrada, mas não os mecanismos de proteção/status. Não existe rollback de exclusão real irreversível. Runbooks futuros precisarão de autorização específica; nenhum comando destrutivo é fornecido aqui.

## 5. Decisões formais pendentes

1. Aprovar matriz de retenção e comunicações, incluindo logs/backups, protocolo/recibo e tombstone; atualmente proposta.
2. Aprovar ADR intake separado do start e estados públicos (inclusive desistência), políticas/versões e rejeição com recurso.
3. Designar pessoas/principais independentes, verificação recente/step-up, IAM, ambiente privado e auditoria resistente a alteração; resolver aliases e operação por pessoa física.
4. Homologar grant/revogação MP, duplicidade, nonce, gateway de writers e bootstrap legado. Não alterar OAuth antes da autorização correspondente.
5. Escolher armazenamento/transporte/recuperação de receipt por Android/PWA/iOS; definir ack, duração, rotação, status após excluir Auth e modo sem e-mail obrigatório.
6. Escolher outbox/dispatcher/worker/infra, identidades, limites/custos/TTLs/leases e política de retries, sem reutilizar Scheduler REDE.
7. Aprovar staging, fixtures, teste independente, plano de incidente/restore, observabilidade mínima e gates de ativação individual.
8. Autorizar separadamente implementação, testes de staging, mudanças de configuração/deploy e ativação real. Nenhuma dessas autorizações consta desta missão.

## 6. Sequência proposta (nenhuma chamada ativa)

```mermaid
sequenceDiagram
    participant App as Android/PWA/iOS futuro
    participant API as API proposta
    participant DB as Firestore privado
    participant Admin as Verificador + aprovador
    participant Worker as Worker proposto
    App->>API: ID Token após reauth + confirmação + idempotência
    API->>DB: Transação: pedido received + índice + evento/outbox
    API-->>App: 202 recebido; não excluído
    App->>API: Emitir recibo protegido e confirmar posse (ack)
    Admin->>API: Verificação + plano + duas aprovações independentes
    API->>DB: Start atômico: barreira/epoch + processing + job
    Worker->>DB: Etapas retomáveis e checkpoints
    Note over DB,Worker: Writers negam eventos tardios ao UID bloqueado
    Admin->>API: Conferência independente com evidência
    API->>DB: completed + escopo/retencões + outbox
    App->>API: Consultar status pelo recibo, sem Auth original
    API-->>App: Resultado verdadeiro e exceções aprovadas
```

Verificações documentais desta missão: links locais válidos, 33 cenários de teste com IDs únicos, contratos/estados e gates presentes, sem comandos destrutivos executáveis. Nenhum teste runtime, flutter analyze/test/build, acesso a dados reais ou deploy foi executado, pois somente a especificação mudou.
