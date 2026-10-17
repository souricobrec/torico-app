# TORICO — especificação do índice canônico Mercado Pago

Estado: **proposta; migração e ativação real não autorizadas**. Código preparado em `codex/beta-final-blockers`, sobre `299f7cb`. Este documento não contém comandos de escrita em produção.

## Por que a migração é obrigatória

Uma consulta por igualdade não encontra todas as representações legadas (`123`, `"123"`, `" 000123 "`). Ignorar os legados na ausência de resultado permitiria tomar uma conta já vinculada. A varredura global foi removida do runtime, mas sua substituição só pode provar ausência após um inventário completo certificado.

Portanto, **não publicar esse backend antes de preparar e aprovar o índice**. Sem certificação, a resolução e persistência MP retornam `503 merchant_index_not_ready`, sem fallback para varredura. Esse bloqueio é uma dependência de implantação explícita, não uma migração automática. Nenhum script de certificação real foi implementado.

## Modelo privado

`mp_ownership_index/active`:

```json
{"version":1,"state":"ready","epoch":"IDENTIFICADOR_DA_REVISAO_APROVADA"}
```

`state` diferente de `ready`, versão desconhecida, epoch ausente/inválida ou documento ausente bloqueiam o caminho novo. O epoch identifica um inventário certificado; não é segredo nem simples flag de liberação comercial.

`mp_account_owners/{merchantIdCanonico}`:

```json
{"indexVersion":1,"indexEpoch":"MESMO_EPOCH","state":"owned","userId":"UID_VERIFICADO"}
```

Para conflito conhecido: `state: "conflict"`, mesma versão/epoch. Pode-se preservar o `userId` legado para auditoria; ele não é usado enquanto houver conflito. Estado/schema desconhecido ou epoch divergente bloqueia **somente esse merchant**. Não armazenar tokens, e-mails, nomes ou payload OAuth no índice.

Ausência do documento só significa conta ainda não reservada quando o marcador global certifica completude. Callback autenticado pode então criar o owner canônico e gravar tokens/status na mesma transação, conferindo geração OAuth. Uma corrida pelo mesmo documento canônico tem um único titular. Desconexão não libera titularidade para outro UID.

Resolver um vínculo usa transação com leituras do marcador, owner canônico e `users/{UID}/integrations/mercado_pago`. O ID privado é canonicalizado novamente. Integração de outro ID não fornece credenciais para o merchant antigo: retorna ausência, preservando a reserva antiga. Registro privado inválido causa diagnóstico apenas para o merchant consultado.

## Controle de acesso

Rules existentes negam acesso de clientes a `mp_account_owners` e, pelo deny-all, a `mp_ownership_index`. Emulador testa negação autenticada. Admin SDK continua dependendo de IAM: só backend operacional e ferramenta administrativa aprovada devem escrever. Não conceder escrita a Flutter/usuário comum. Nenhum endpoint permite certificar ou alterar o epoch.

Não é necessário índice composto Firestore para as leituras diretas por caminho. **Índice lógico não significa configuração de índice composto.** Eventual ferramenta de inventário pode precisar de consultas/índices próprios; definir antes de implementá-la. IAM/Rules implantados não foram consultados nem alterados.

## Migração aditiva proposta — requer nova autorização

1. Autorizar inventário somente leitura e registrar snapshot/revisão de origem, contagens e hashes dos insumos, em repositório administrativo privado. Não copiar tokens para relatório.
2. Identificar todos os escritores (backend atual, revisões antigas, ferramentas manuais, imports, jobs). Planejar uma janela sem novos vínculos/desconexões ou um protocolo equivalente que prove delta completo. Sem controle de escritores, **não certificar**.
3. Inventariar integrações MP, inclusive sem `platformId` legado quando o caminho identificar MP, owners e aliases. Outras plataformas não entram no mapa. Não modificar integrações privadas, tokens, vendas, totais ou usuários.
4. Canonicalizar números inteiros positivos seguros e strings decimais. Agrupar aliases/integrações por ID canônico e UID. Um mesmo ID/same UID é um vínculo; UIDs distintos viram conflito, inclusive registros desconectados. Nunca escolher o primeiro nem transferir credenciais.
5. Classificar inválidos por hash de referência, motivo e ação proposta em relatório administrativo. Formatos sem identidade atribuível ficam em quarentena administrativa, preservados na origem. Números com precisão perdida, caminhos inesperados e ambiguidades potencialmente relacionadas a IDs válidos exigem revisão humana: **não certificar ausência enquanto puderem ocultar titularidade**. Não deduzir o ID original de um número arredondado.
6. Gerar dry-run determinístico, comparar integrações + aliases + owners; revisar conflitos e as reservas necessárias. Registrar dupla conferência lógica e precondições contra alterações concorrentes. Não criar `ready` apenas por ter chegado ao fim de uma página.
7. Em missão autorizada separada, adicionar campos versionados aos owners canônicos sem apagar aliases ou sobrescrever titular divergente. Preservar campos anteriores para rollback/auditoria; conflito recebe estado bloqueado. Escritas administrativas devem ser idempotentes e usar precondições/revisão esperada.
8. Reconciliar contagens, amostras e todos os grupos conflitantes; garantir que todo possível titular esteja representado ou bloqueado de forma segura. Se houver falha parcial, manter marcador ausente/`building`. Nunca tratar backfill parcial como completo.
9. Somente após aprovação, publicar marcador `ready`/epoch e ativar revisão compatível durante janela coordenada. Não manter escritores antigos que gravem owner sem versão/epoch; não balancear versões OAuth incompatíveis.
10. Testar contas já conectadas sem reautorizar ou desconectar, eventos válidos, conflitos, novas conexões e desconexão. Monitorar erros sanitizados e recebimento de eventos. Não inferir estado real a partir das fixtures.

As fixtures em `backend/test-support/ownership-index-fixtures.mjs` só aceitam `demo-*`, sem inventário real. São dados explicitamente conhecidos para testes; **não certificam uma migração nem demonstram completude de produção**.

## Retenção e rollback

Aliases e integrações legadas não são excluídos. Índice é uma reserva de titularidade, inclusive depois de desconectar; transferência e exclusão futura exigem política específica. Controles/slots antigos também não são expurgados. Aprovar retenção e tratamento na futura exclusão de conta antes de automação.

Backup administrativo deve preservar os documentos originais e precondições. Após criação de novos vínculos, não restaurar mapa antigo por cima deles: reconciliar deltas e manter reservas. Em incidente, suspender novos vínculos pelo procedimento autorizado, preservar tokens/histórico e usar revisão que entenda o índice/geração. Não voltar para GET inseguro, reabrir states consumidos ou remover owners.

Um rollback de backend para `299f7cb` reintroduz varredura e seus bloqueadores; ele **não é rollback operacional aprovado**. Preparar revisão de contingência compatível antes do rollout. Nenhum rollback real foi executado nesta missão.
