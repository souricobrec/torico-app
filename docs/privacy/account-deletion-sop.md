# Procedimento operacional de exclusão de conta TORICO

Versão: proposta para aprovação, 15/10/2026 UTC. Base: commit 7cdc41b, [auditoria](account-deletion-audit.md) e [proposta técnica](account-deletion-backend-proposal.md). Este documento não autoriza execução em produção. Não contém comandos destrutivos. Nenhum atendimento, verificação ou exclusão real foi realizado nesta missão.

## 1. Escopo e bloqueio atual

Fluxo futuro: **Solicitação → Protocolo → Verificação → Bloqueio seguro → Exclusão → Conferência → Confirmação**.

O app atual apenas prepara e-mail; não transmite pedido nem fornece prova de recebimento. Abrir compositor, sair, limpar dispositivo ou desconectar Mercado Pago NÃO equivale a solicitar ou concluir exclusão de conta.

Hoje não existe proteção completa contra recriação de dados, processo administrativo homologado, política de retenção aprovada nem consulta de andamento independente da conta excluída. Recebimento/triagem de futura demanda devem ser tratados com transparência; processamento destrutivo fica bloqueado até os controles abaixo. Não substituir as proteções ausentes por cliques manuais no Console, scripts avulsos ou apagamento do documento pai.

## 2. Responsáveis e autorização

| Papel | Responsabilidade proposta |
|---|---|
| Atendimento | Receber, atribuir protocolo, comunicar sem confirmar existência de conta a terceiros. |
| Verificador | Associar identidade verificada a um único UID por evidência confiável, sem confiar em UID enviado pelo solicitante. |
| Executor administrativo | Aplicar somente escopo aprovado, em ferramenta futura com privilégios mínimos, validação de ambiente/UID e modo de simulação homologado. |
| Revisor | Conferir escopo, barreiras, resultado e exceções, independentemente do executor. |
| Responsável pelo TORICO | Elton Cruz: designar pessoas/papéis, aprovar operação e obter revisão de retenção/privacidade. |

Preferir duas pessoas no ponto irreversível. Se o titular acumular papéis, exigir exceção documentada e revisão independente antes da primeira operação real; não apresentar conferência pela mesma pessoa como dupla aprovação. A delegação de privilégios e o sistema de registro ainda precisam de aprovação; nada é criado aqui.

## 3. Etapas e critérios de passagem

| Etapa / estado | Ação futura | Evidência mínima / saída |
|---|---|---|
| Solicitação / `received` | Atendimento confirma chegada real ao canal; remove anexos desnecessários segundo política aprovada, sem retransmiti-los. Não tratar clique mailto como chegada. | Canal, data UTC e referência restrita da mensagem; sem cópia integral. |
| Protocolo / `awaiting_verification` | Gerar identificador público opaco, aleatório e não sequencial; ligar a um identificador interno em registro restrito. Unificar pedidos duplicados do mesmo titular após verificação. | Protocolo só após gravação durável. Protocolo não é senha nem autorização para consultar dados. |
| Verificação / `verified` | Confirmar controle e intenção por um dos métodos da seção 4. Confirmar o escopo: conta e dados, não apenas desconexão. | Método, resultado, instante e referência da evidência; UID resolvido no mapeamento privado, não no e-mail. |
| Preparação / `blocked` ou `approved` | Enumerar dados/coleções, grants/índices/filas, retenções e ambiente. Obter dupla conferência do alvo. Se qualquer gate falhar, não avançar. | Plano de execução somente com contagens, versionado e aprovado. `blocked` inclui responsável e próxima revisão, sem sugerir que houve exclusão. |
| Bloqueio seguro / `quarantined` | Somente após autorização e homologação: estabelecer barreira persistente contra todas as escritas, impedir reconexão, revogar sessões/desabilitar acesso. Preservar acompanhamento fora da sessão. | Testes de barreira aprovados, confirmação de isolamento do UID, horário de corte e versão/epoch. Não basta integração desconectada. |
| Exclusão / `processing` | Executor segue plano aprovado: revogação segura do grant, remoção de tokens e vínculos, recursão de dados e derivados, Auth e perfil, tratamento de cópias/retenções. Ordem e retries na proposta técnica. | Checkpoint por etapa, contagens, retornos resumidos e falhas; nenhuma cópia de credencial ou payload de vendas. |
| Conferência / `verifying_result` | Revisor verifica ausência de conta operacional/tokens/dados indevidos e resistência a evento tardio/restauração. Retenções são enumeradas individualmente. | Atestado operacional mínimo, assinado por executor/revisor; exceções com base, prazo e responsável. |
| Confirmação / `completed` ou `completed_with_retention` | Informar exatamente o que foi concluído e exceções aprovadas. Notificar por canal já verificado, sem exigir novo cadastro. | Data de conclusão técnica e data/resultado da comunicação separados. Falha de entrega não invalida nem comprova exclusão. |

Estados auxiliares: `retrying` (falha retomável), `action_required` (impedimento humano), `withdrawn` (desistência antes do ponto irreversível), `closed_unverified` (não verificado). Estes três últimos não significam conta excluída. Falta de resposta não autoriza exclusão ou retenção indefinida. Prazos de resposta/revisão/escalonamento serão aprovados antes de ativação; nunca inventar data ao cliente ou encerrar silenciosamente uma demanda.

## 4. Verificação proporcional de identidade

1. **Preferencial:** ação explícita na conta TORICO autenticada, com reautenticação real recente, confirmada server-side. O protótipo mailto não fornece essa evidência. Renovar ID Token não prova reautenticação. Não pedir o ID Token, senha ou código Firebase por e-mail/suporte.
2. **Alternativa manual futura:** desafio de posse enviado pelo processo controlado ao e-mail já verificado na conta canônica, com uso único e validade aprovada. O responsável localiza o endereço em leitura administrativa autorizada; não usa automaticamente From/Reply-To da mensagem recebida. Uma resposta ou confirmação comprova somente posse no instante, não substitui análise de conta comprometida. Armazenar resultado/referência, não código, link secreto, cabeçalhos completos ou imagem do Console.
3. Solicitação recebida do mesmo endereço não é prova suficiente por si só. Não confiar em nome, UID informado, print do app, ID Mercado Pago ou nome comercial como autorização. Reautenticação Google deve manter o mesmo usuário TORICO; e-mail da conta Mercado Pago pode ser diferente e não autoriza excluir a conta TORICO.
4. Se e-mail não for verificado, houver suspeita de comprometimento, vários alvos ou perda de acesso: parar a etapa destrutiva e encaminhar à recuperação oficial/avaliação proporcional. Não trocar e-mail, criar usuário ou pedir RG/CPF/selfie como atalho. Exceção realmente necessária exige avaliação de necessidade, canal seguro e prazo de expurgo próprios, aprovados antes de coleta.
5. Antes da aprovação, pedir confirmação clara da intenção e explicar perda de conta/histórico TORICO e retenções específicas. Não pedir exportação, conexão Mercado Pago, pagamento ou instalação do app como condição para aceitar pedido externo.
6. Desistência: aceitar antes do ponto irreversível mediante nova confirmação de identidade. Depois de começar a remoção, informar a limitação e não prometer restauração; não reconectar automaticamente integrações. Não usar janela de espera artificial para dificultar exclusão.

## 5. Gates administrativos (sem instruções executáveis)

- Ambiente/projeto torico-ca479 e UID canônico confirmados por dois controles independentes; cada ação deve mostrar escopo exclusivo. Sem seletores por e-mail livre ou conta MP global.
- Inventário de todos os dados da [matriz](account-deletion-retention-matrix.md), subcoleções e terceiros/cópias. Simulação em staging primeiro, com UIDs fictícios e conta vizinha preservada.
- Barreira server-only e proteção de todas as escritas comprovadas antes da primeira remoção. Detalhamento na seção 6.
- IAM mínimo, registro restrito, revogação de sessões e acompanhamento independente disponíveis; nenhum relaxamento emergencial de Rules.
- Escopo de revogação Mercado Pago homologado: grant pode afetar outro UID. Disconnect atual não revoga no provedor. Não alterar OAuth/webhook ou apagar segredo compartilhado para satisfazer pedido.
- Retenções aprovadas por categoria/campo: base/motivo, início da contagem, prazo/data final, acesso e responsável. Sem justificativa aprovada não existe autorização genérica para conservar histórico comercial. Lacuna suspende a decisão correspondente, é escalonada e não vira retenção automática.
- Falhas parciais mantêm barreira e checkpoints; não restaurar tokens como recuperação. Comunicação de progresso sem afirmar conclusão.
- Conferência final não deve depender só do retorno de uma API ou de Auth disabled: verificar subcoleções, resumos, tokens e recriação. Não reaproveitar backups de produção para teste de exclusão.

## 6. Impedir recriação e restauração indevida

| Vetor | Controle futuro obrigatório | Comprovação antes de ativação |
|---|---|---|
| Webhook tardio / fila antiga | Barreira de ciclo de vida por UID, consultada dentro da transação de cada escrita; eventos descartados/confirmados sem novas vendas nem retry infinito. | Evento aprovado antigo não cria sales/daily_totals ou perfil. |
| Callback/state OAuth pendente | Connect, callback e refresh autenticados/validados; nonce consumível; rejeitar UID em exclusão/ausente e tratar grant recém-retornado sem salvá-lo. | Callback iniciado antes do corte não reconecta. |
| Reconexão | Não confiar em query userId nem campo de perfil controlado pelo cliente; bloquear UI e, obrigatoriamente, backend. | Cliente adulterado/UID injetado continua bloqueado. |
| Jobs/Admin e fallbacks | Todos os escritores usam barreira/epoch; conta canônica e integração ativa precisam existir. Admin ignora Rules. Não ativar REDE/Scheduler para testar. | Testar fonte alternativa e fallback ambiente; documento ausente nunca equivale a permissão. |
| Restaurar backup/export/PITR | Restauro isolado, sem tráfego; reaplicar lista mínima de supressão vigente antes de qualquer leitura operacional ou ingestão; expurgar alvos e validar; só então liberar. | Ensaio com conta fictícia excluída e vizinha íntegra; evidência sem dump de dados. |
| Tombstone expirado | Escritores continuam negando UID sem identidade/integração canônicas; barreira tem prazo/justificativa e não fica em users a ser apagado. | Após expiração simulada e replay, nada é recriado. |
| Dispositivo offline | Revogação impede sincronização autenticada posterior; futura limpeza local ao receber encerramento. Sem promessa de apagar remotamente cache offline inacessível. | Reabrir/sincronizar após revogação não restaura dados da conta. |

**Bloqueador atual confirmado na auditoria:** saveSale apenas ignora `disconnected` em um caminho MP; integração ausente pode passar e há fallback ambiente. Exclusão manual de documentos antes da correção não é segura. Conta MP vinculada a vários UIDs e state sem consumo único também precisam ser resolvidos. Esta missão não implementa controles.

## 7. Registro mínimo proposto

Armazenar em sistema privado ainda a aprovar, não em Git, issue pública ou planilha compartilhada aberta. Proposta não cria coleção de produção.

| Campo | Conteúdo mínimo |
|---|---|
| protocol | ID opaco público; sem UID/e-mail/data comercial codificados. Não é segredo de acesso. |
| subject_ref | ID interno aleatório; vínculo temporário com UID em área separada e restrita, após verificação. Não duplicar UID/e-mail em cada evento. |
| received_at / channel | Instante UTC de recebimento real; app/web/e-mail e referência restrita, sem mensagem integral. |
| status / updated_at | Estado verdadeiro e timestamp de mudança. |
| verification | Método, resultado, data e referência restrita; sem código/senha/token ou documento anexado. |
| owner / approvals | Identificadores funcionais de responsáveis, aprovações e referência da matriz/plano vigentes. |
| blocked_reason / next_review_at | Código de motivo não sensível e próxima revisão aprovada; sem deixar pedido sem responsável. |
| completed_at | Nulo até conferência concluída; distinto de mensagem enviada. |
| evidence_ref | Referência ao comprovante operacional mínimo: etapas/contagens/versão, resultado e assinaturas. Se houver hash, somente do comprovante sem payload; hash/pseudônimo não é anonimização automática. |
| retention_refs / purge_at | Exceções aprovadas e expurgo da própria trilha/mapeamento/contato; sem campo livre para copiar dados financeiros. |
| notification | Data/canal/resultado de entrega ou falha; sem corpo integral, segredo ou link de acesso. |

Histórico de mudanças append-only com ator/data/estado anterior/novo/motivo; correções por novo evento, nunca apagar inconsistências para esconder erro. A trilha também é dado pessoal: controle de acesso, prazo, expurgo e acesso auditado. Não registrar access/refresh/ID tokens, senha, keystore, código OAuth, recibo secreto, detalhes de vendas, payer_id ou dumps. Protocolo sozinho não permite consulta pública; futura consulta exige mecanismo independente aprovado.

## 8. Modelos de atendimento (rascunhos, NÃO enviados)

Preencher somente após os gates aplicáveis. Não enviar placeholders ao titular. Suporte público atual: sourico.br.ec@gmail.com. Nenhum SLA numérico está aprovado; responsável deve aprovar prazos operacionais e legais aplicáveis antes da ativação, informar data realista de próxima atualização e escalar atraso, sem condicionar o direito ao prazo interno.

### A — solicitação pelo titular

> Assunto: Solicitação de exclusão de conta TORICO
>
> Quero excluir minha conta TORICO e os dados associados.
> E-mail da conta: [preencher].
> Peço confirmação de recebimento, orientação proporcional para verificar minha identidade e informação sobre eventuais dados retidos, motivo e prazo.
> Não envio senha, token, código de autenticação ou documentos nesta mensagem.

### B — recebimento (somente após registrar protocolo)

> Recebemos seu pedido relacionado ao TORICO em [data]. Protocolo: [protocolo].
> Recebimento não significa que a conta foi excluída. Antes de qualquer ação irreversível, precisamos confirmar a identidade e a intenção pelo procedimento informado a seguir.
> Nossa próxima atualização está prevista para [data operacional aprovada]. Você pode acompanhar por [canal aprovado], informando o protocolo. Não envie senhas ou códigos de login.

Não confirmar que determinado e-mail possui conta antes de verificação; resposta genérica a terceiro não deve revelar nome, UID, vendas ou integração.

### C — verificação proporcional

> Para proteger sua conta TORICO, confirme a intenção de exclusão por [ação autenticada com reautenticação / mecanismo de posse aprovado enviado ao contato já verificado].
> Não pediremos sua senha, código Firebase/Google ou senha Mercado Pago por suporte. Se perdeu acesso, informe essa condição para avaliarmos uma alternativa segura.
> Esta etapa ainda não exclui sua conta. Após verificar a identidade, explicaremos o escopo e eventuais retenções aplicáveis antes do processamento.

Não inventar link ou desafio com aparência de Firebase. Nenhuma mensagem deve conter UID ou tokens. Confirmação na sessão deve ser ligada server-side ao pedido; não aceitar print ou relato "já autentiquei".

### D — processamento bloqueado/pendente

> O protocolo [protocolo] permanece [aguardando verificação / em análise / em processamento]. A exclusão ainda não foi concluída.
> A pendência é [motivo compreensível, sem detalhes de segurança sensíveis]. [Responsável/canal] acompanhará o caso; a próxima atualização será [data aprovada].
> Não é necessário conectar Mercado Pago ou enviar senha/documentos para resolver essa etapa.

### E — conclusão sem retenções remanescentes

> A exclusão da conta TORICO do protocolo [protocolo] foi concluída e conferida em [data]. Foram removidos [categorias efetivamente conferidas]. A conta não pode mais acessar o TORICO, e os vínculos de integração no TORICO foram encerrados conforme o procedimento aprovado.
> [Usar esta frase somente se todas as cópias abrangidas tiverem sido eliminadas: Não há dados associados remanescentes no escopo conferido.]
> Sua conta e os registros mantidos pelo Mercado Pago não são apagados por esta ação. Para dúvidas, use [canal aprovado].

Não usar E se tokens, cópias de backup, trilha identificável ou obrigações de retenção ainda existirem sem explicação. Comprovante não inclui IDs/valores de vendas. Não prometer que nenhum dado existe em qualquer sistema do mundo.

### F — conclusão com retenção residual aprovada

> A conta operacional TORICO do protocolo [protocolo] foi excluída e conferida em [data]. Foram eliminados [categorias verificadas].
> Permanecem exclusivamente [categorias/campos], para [motivo/base aprovada], com acesso restrito e sem uso para reativar a conta. A contagem começa em [marco], e a eliminação está prevista para [data ou evento objetivo aprovado, com revisão].
> [Se aplicável] Cópias de segurança isoladas expiram em [data]; qualquer restauração exige reaplicar a exclusão antes de uso. Isso é retenção residual, não apagamento imediato de todas as cópias.
> Você pode acompanhar por [canal]. Sua conta e registros próprios no Mercado Pago permanecem sob controle do provedor.

F não serve para declarar conclusão se a remoção operacional falhou, a autorização continua utilizável ou o plano de retenção não foi aprovado. Anotar confirmação de expurgo residual posterior e comunicá-la quando cabível. Não alegar "exclusão total" quando há retenção.

## 9. Decisões antes da operação real

Aprovar [matriz](account-deletion-retention-matrix.md) e [checklist de liberação](account-deletion-review-checklist.md): responsáveis/sistema, verificação alternativa, prazos e mensagens; barreiras/reauth/revogação segura; retenções de backups/logs/trilha/tombstone; acompanhamento após Auth removido; testes em staging e plano de incidente. Não implementar nem ativar com base apenas neste SOP.

## Situação após implementar somente intake local (sem ativação)

[Recebimento autenticado/status](account-deletion-intake-implementation.md) está implementado para revisão e testes locais, desativado por padrão e bloqueado no Cloud Run. O protótipo publicado não mudou. Protocolo real só pode ser mostrado após confirmação persistida do servidor; nenhum receipt, e-mail automático, operador/admin, bloqueio ou exclusão efetiva foi ativado. Este SOP permanece sem liberação operacional; próximos gates exigem autorização própria.
