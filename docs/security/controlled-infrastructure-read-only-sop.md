# TORICO — roteiro de inspeção real somente leitura

**PREPARADO, NÃO EXECUTADO.** Cada etapa sobre infraestrutura real exige autorização específica futura. Este documento não concede acesso, não solicita criação de papel IAM e não inclui migração, certificação, assinatura, configuração ou deploy.

## Autorização e recursos exatos

Autorizar previamente operador, identidade de leitura já aprovada, data/janela, readTime, limite de documentos/páginas/duração/custo, local privado de evidências e campos permitidos. Se faltar qualquer item, parar. Não usar automaticamente a sessão CLI/ADC atual nem credencial de produção durante os testes locais.

Recursos alvo propostos, a confirmar pela autorização:

| Recurso | Identificação / escopo |
| --- | --- |
| Projeto | `torico-ca479` (não alterar aliases nem projeto ativo global) |
| Banco Firestore | `projects/torico-ca479/databases/(default)`; verificar tipo/localização em metadados, sem presumir região pelo Cloud Run |
| Integrações | Collection group `integrations`; selecionar só platformId, mercadoPagoUserId e status; caminho fornece UID e ID da plataforma |
| Titularidade | Coleção raiz `mp_account_owners`; selecionar userId, merchantId, indexVersion, indexEpoch, state; ID do documento fornece alias |
| Estado do índice | `mp_ownership_index/active`; apenas version/state/epoch/certificateId/sourceRevision/writerProtocol/generation |
| Certificação/evidência | `mp_index_certificates/{id}` / `mp_index_evidence/{id}_{prefixo}` somente se existirem e sua leitura for incluída na autorização; não criar caso 404 |
| Índices físicos | `projects/torico-ca479/databases/(default)/collectionGroups/-/indexes` e field configurations pertinentes a `integrations` |
| IAM projeto | Política de `projects/torico-ca479`; identidades/papéis/condições, sanitizados |
| Backend (opcional) | `projects/torico-ca479/locations/us-central1/services/torico-backend`: apenas identidade de execução/revisão e política de acesso se autorizado; não exportar spec/env completo |

Fora do escopo: documentos de vendas/totais, perfis completos, usuários Firebase Auth, Hosting, Scheduler, secrets, tokens OAuth (inclusive criptografados), logs com payloads, chaves privadas e buckets/backups. Não fazer testes de escrita para provar que a credencial é somente leitura: conferir permissões e identidade documentalmente.

Atualização do modelo de certificação: [âncora independente e antirrollback](certification-anchor-trust-model.md). Nenhuma âncora real/adaptador está implementado ou aprovado; não procurar, provisionar ou acessar serviços presumidos. Uma futura inspeção desse recurso exigirá identificação exata do serviço/domínio de autoridade, credencial e orçamento em autorização própria, sem ampliar silenciosamente esta lista. O backend desta fase recusa configurar certificação fora de `demo-*`.

## Permissões mínimas propostas — não concedidas

| Operação de leitura | Permissões a verificar previamente |
| --- | --- |
| GET/batchGet dos campos autorizados | `datastore.entities.get` |
| runQuery/paginação | `datastore.entities.get`, `datastore.entities.list` |
| Metadados do banco | `datastore.databases.getMetadata` |
| Listar/ver schemas e índices | `datastore.schemas.list`, `datastore.schemas.get` (aliases históricos `datastore.indexes.*`) |
| IAM do projeto | `resourcemanager.projects.getIamPolicy`; `resourcemanager.projects.get` somente se houver descoberta de metadados do projeto autorizada |
| Inspecionar definição de papel nomeado | `iam.roles.get`, se aprovado e necessário |
| Cloud Run opcional | `run.services.get`, e `run.services.getIamPolicy` só se política do serviço for autorizada |

Não pedir Owner/Editor/Datastore User/Index Admin nem permissões create/update/delete/setIamPolicy/import/export. Não usar impersonação como fallback: ela exige aprovação própria. Políticas herdadas, grupos, deny policies e condições podem alterar acesso efetivo; política local não basta. Se analisar ancestrais exigir permissão/recurso fora do escopo, interromper e solicitar expansão, sem conceder nada.

IAM com Admin SDK não aplica Rules de usuário e não deve ser presumido limitado a estes campos. Projeção e código revisado minimizam exposição, mas não são uma barreira IAM por campo. Confirmar escopo da identidade de leitura e operar com supervisão/restrição de saída aprovadas.

## Métodos previstos — sem execução nesta missão

Allowlist conceitual: Firestore `get`, `batchGet`, `runQuery`, listagem de índices/metadados; Resource Manager `getIamPolicy`; leitura opcional Cloud Run explicitamente projetada. POST de `runQuery` é consulta, não gravação. Proibir write/commit/patch/create/delete/import/export/restore e comandos de mudança de IAM, contexto, configuração ou serviços.

Exemplos de endpoints a serem usados somente pelo coletor revisado e após autorização (sem tokens ou comandos de autenticação neste documento):

- `GET https://firestore.googleapis.com/v1/projects/torico-ca479/databases/(default)`
- `POST https://firestore.googleapis.com/v1/projects/torico-ca479/databases/(default)/documents:runQuery`
- `GET https://firestore.googleapis.com/v1/projects/torico-ca479/databases/(default)/collectionGroups/-/indexes`
- `POST https://cloudresourcemanager.googleapis.com/v1/projects/torico-ca479:getIamPolicy`

Corpo de consulta projetada, modelo não executável sem readTime aprovado:

```json
{
  "readTime": "<READ_TIME_APROVADO>",
  "structuredQuery": {
    "select": {"fields": [{"fieldPath":"platformId"},{"fieldPath":"mercadoPagoUserId"},{"fieldPath":"status"}]},
    "from": [{"collectionId":"integrations","allDescendants":true}],
    "orderBy": [{"field":{"fieldPath":"__name__"},"direction":"ASCENDING"}],
    "limit": 200
  }
}
```

`limit:200` limita página, **não o inventário completo**. Paginar por cursor do último `__name__` com `before:false`, no mesmo readTime, sem offsets; nomes completos permanecem em memória protegida. Continuar até comprovar esgotamento (página cheia exige próxima consulta). Registrar páginas/contagens/repetições/terminação e hashes, não concluir por teto de orçamento.

Para owners: coleção raiz `mp_account_owners`, `allDescendants:false`, projeção dos campos listados na tabela, mesma ordenação/cursor/readTime. GETs devem usar field masks; nunca buscar documento privado inteiro por conveniência.

## Captura consistente e inventário

1. Validar identidade, escopo e projeto por configuração explícita revisada. Não iniciar Auth login/OAuth nem criar recursos. Preparar pipeline de sanitização antes da primeira resposta.
2. Escolher um readTime compatível com a API e orçamento/janela autorizados; todas as páginas de integrações e owners devem usar esse mesmo ponto. A API admite readTime recente com condições próprias; não presumir PITR habilitado nem alterar PITR. Se o readTime expirar ou for recusado, descartar a conclusão de completude e reiniciar somente com autorização compatível.
3. Fazer consultas projetadas, filtrando MP **localmente** pelo ID de documento/caminho e platformId para não perder legados sem platformId. A coleta pode ler metadados mínimos de outras plataformas no collection group; obter consentimento explícito para isso. Não chamá-la de coleta exclusivamente MP no servidor se usar esse grupo.
4. Derivar UID do caminho `users/{UID}/integrations/mercado_pago`; caminhos inesperados com platformId MP vão para análise, não são ignorados. Owners/aliases vêm de seus paths e userId. Conferir números inteiros seguros e strings canônicas; nunca arredondar.
5. Agrupar ID canônico e todos os UIDs, incluindo desconectados/aliases. Duplicata de representação com mesmo UID é alias; UIDs distintos são conflito. ID inválido/precisão perdida não recebe titular por aproximação. Inventário incompleto não pode provar ausência.
6. Separar relatório de leitura (diagnóstico) de candidato a certificação. Uma inspeção em readTime fixo não bloqueia escritores atuais e não aprova a migração. Para certificação futura será necessária janela/delta de escritores comprovadamente reconciliado, sob autorização distinta.
7. IAM/índices: guardar apenas papéis, condições e pseudônimos de identidades relevantes; confirmar lacunas de herança. Registrar configuração de índice em estado de erro/ausente como pendência. Não criar índice, mudar policy ou corrigir registros.

## Proteção de dados e evidências

Sem stdout/log de respostas brutas, modo debug, stack com payload ou Authorization. Projeção exclui accessTokenEncrypted/refreshTokenEncrypted e qualquer senha. UIDs e merchant IDs são dados vinculáveis: trabalhar em memória controlada; relatório com HMAC usando chave efêmera local sob custódia aprovada, não hash simples de e-mail/UID; publicar apenas contagens/códigos e referências pseudônimas. Não enviar dados ao Git, chat ou serviço externo.

Se for preciso preservar inventário identificável para futura revisão, isso exige autorização própria para armazenamento cifrado, ACL, retenção e destruição segura. Não gravar automaticamente dados crus porque a leitura foi autorizada. Evidência sanitizada: protocolo da missão, readTime, projeto/banco, hash do coletor/código, páginas e contagens, conclusão/limitação, custos em unidades e decisões pendentes. Nenhum token/credencial no protocolo.

## Custos e limites

Somente após conhecer volume: aprovar orçamento `Rmax` leituras, páginas, duração e eventual custo monetário com tarifa/região vigentes. Não há valor financeiro certificado nesta missão. Projeção reduz dados transferidos, não torna as leituras gratuitas. Leitura do collection group custa em função de **todas** as integrações retornadas, não apenas MP. Prever páginas vazias, índices cobrados conforme consulta, retries e revisão independente.

Estimativa de planejamento: `R ≈ I_total + A + D + retries`, onde I_total = integrações do grupo lidas, A = owners/aliases, D = GETs de metadados/índice/documentos autorizados (nem todos têm a mesma forma de faturamento). Segunda passagem pode duplicar parcela de dados. Sem gravações Firestore, exports ou backups nessa inspeção. A ferramenta futura deve interromper antes do orçamento e marcar inventário incompleto, nunca truncar e certificar.

## Condições de interrupção

- Projeto/banco/identidade divergente, permissão insuficiente ou necessidade de ampliação de IAM.
- Resposta contém campo não autorizado, token ou dado sensível inesperado: não reproduzir no log/chat.
- Índice requerido ausente/erro, 403/429, readTime inconsistente/expirado, cursor repetido, paginação sem prova de término, orçamento atingido.
- ID sem precisão, conflito não resolvido, caminho inesperado, diferença entre contagens/manifests ou escritores não inventariados.
- Qualquer necessidade de login de usuário, OAuth, escrita, acesso a secrets, suspensão de serviço ou alteração de configuração.

Parar somente a coleta própria, fechar conexões e reportar resultado parcial sanitizado. Não executar correção automática, retry ilimitado ou troca silenciosa de credencial/projeto. Não há rollback de dados porque nenhuma escrita é permitida; retenção dos relatórios segue aprovação própria.

## Critérios para solicitar certificação futura

Inspeção concluída não significa certificação aprovada. Exigir: coleta consistente/esgotada com hashes e contagens; duplicidades/IDs irrecuperáveis resolvidos ou claims bloqueados de forma segura; inventário de escritores; janela/delta; proposta de migrador idempotente e journal externo; testes de lote parcial e retomada; duas revisões independentes e custódia das chaves; aprovação da validade/renovação de certificados; IAM mínimo e índices conferidos; backup/rollback compatível que preserve novas reservas; autorização **nova** para qualquer escrita, assinatura real, instalação de chave ou ativação.

## Fontes públicas consultadas (nenhuma consulta ao projeto)

- [Firestore IAM e permissões por método](https://firebase.google.com/docs/firestore/security/iam): get/runQuery, metadados e aliases schemas/indexes.
- [Firestore runQuery/readTime](https://docs.cloud.google.com/firestore/docs/reference/rest/v1/projects.databases.documents/runQuery): consistência no tempo e semântica de leitura.
- [Listagem de índices compostos](https://docs.cloud.google.com/firestore/docs/reference/rest/v1/projects.databases.collectionGroups.indexes/list).
- [Resource Manager getIamPolicy](https://docs.cloud.google.com/resource-manager/reference/rest/v1/projects/getIamPolicy).
