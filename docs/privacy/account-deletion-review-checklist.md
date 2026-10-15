# Checklist de revisão e liberação — exclusão de conta TORICO

Proposta vinculada ao [SOP](account-deletion-sop.md), [matriz](account-deletion-retention-matrix.md), [auditoria](account-deletion-audit.md) e [backend](account-deletion-backend-proposal.md). **Situação atual: NÃO LIBERADO para exclusão real.** Marcar uma caixa exige evidência, aprovador e data; a lista em si não concede autorização. Nenhum teste destrutivo, implantação ou mudança de produção foi executado nesta entrega.

## A. Atendimento e identidade

- [ ] Designar atendimento, verificador, executor e revisor; resolver acúmulo de papéis e dupla aprovação.
- [ ] Aprovar sistema privado de protocolo/registro, acesso, trilha de alterações e expurgo; não usar Git/issues públicos para pedidos reais.
- [ ] Protocolo gerado após recebimento/registro reais; não usar mailto aberto, screenshot ou alegação do usuário como prova.
- [ ] Verificação por sessão com reautenticação ou mecanismo proporcional ao contato canônico já verificado, sem confiar em From/Reply-To/UID fornecido.
- [ ] Processo de perda de acesso, endereço não verificado, suspeita de fraude e representante validado sem documentos desnecessários; escalar antes de coleta excepcional.
- [ ] Distinguir e-mail TORICO de e-mail Mercado Pago; resolver UID do titular, sem exigir igualdade entre contas.
- [ ] Modelos do SOP aprovados; prazos reais de resposta, próxima atualização e escalonamento definidos sem inventar obrigação legal.
- [ ] Contato/status acessível depois de desabilitar/remover Auth, sem recriar conta e sem consulta pública por protocolo simples.

## B. Segurança técnica — bloqueadores antes de qualquer exclusão

- [ ] Conta canônica, ambiente e escopo comprovados; simulação com dados fictícios e preservação de UID vizinho homologadas.
- [ ] Tombstone/epoch server-only cobre todas as escritas na mesma transação; documento ausente nunca autoriza criar dados.
- [ ] MP connect não confia só em userId query; autenticação validada, state consumível, callbacks/refresh/retornos antigos bloqueados.
- [ ] Risco de mesma conta/grant MP associado a vários UIDs resolvido; revogação não afeta terceiros. Nenhum endpoint de revogação foi presumido nesta documentação.
- [ ] Webhooks tardios, fallback ambiente, jobs/Admin, retries/dead-letter e fontes futuras não recriam perfil, integração, sales ou daily_totals.
- [ ] Regras/API/IAM e escrituras cliente protegem estado de exclusão; Admin é verificado no código, sem relaxar Rules reais.
- [ ] Sessões e credenciais TORICO revogadas, mas barreira não depende apenas de Auth disabled/revogação de refresh.
- [ ] Falhas preservam bloqueio, registram checkpoint e não restauram tokens; status não apresenta sucesso antes da conferência.
- [ ] Tokens, estados/recibos secretos e dumps não entram em protocolo/log/backup extra; IAM mínimo e segredos existentes preservados.

## C. Dados e retenção

- [ ] Inventário autorizado cobre Auth, users, todas as subcoleções/órfãos, sales/rawPayload, daily_totals/last10Sales, integrações/status/requests e oauth_states.
- [ ] Inventariar logs/sinks, fornecedores, exports, PITR/backups, suporte e caches sem presumir ausência ou período configurado.
- [ ] Cada retenção aprovada com categoria/campos, necessidade/base validada, responsável, marco, prazo/data, revisão, acesso e comunicação.
- [ ] Nenhuma regra genérica "reter todas as vendas"; TORICO não é presumido processador de pagamentos ou arquivo fiscal.
- [ ] Tombstone/subject_ref/protocolo/contato têm política própria; pseudonimização não é chamada de anonimização.
- [ ] Revogação/limpeza de credenciais por provedor homologadas; não apagar chave compartilhada de criptografia ou conta externa do comerciante.
- [ ] Plano de restore isolado reaplica exclusões antes de liberar tráfego; expurgo de cópias residuais definido e verificável.
- [ ] Limites de cache offline comunicados e sync impede retorno dos dados ao servidor.

## D. Conferência operacional por caso futuro

- [ ] Intenção/identidade e escopo aprovados; retenções/expectativa explicadas; autorização vinculada ao único alvo.
- [ ] Gates B/C completos; nenhuma exclusão improvisada por Console; ferramenta futura impede alvo arbitrário, exibe ambiente/escopo e tem simulação.
- [ ] Comprovante registra etapas/contagens/versões/atores, sem conteúdo sensível ou credenciais.
- [ ] Conta Auth realmente ausente ao concluir; desativar somente não basta.
- [ ] Tokens/grants operacionais tratados; integração ausente e retorno tardio não a repõem.
- [ ] Perfil/subcoleções/derivados eliminados conforme escopo e exceções documentadas; não conferir apenas últimas 10 vendas.
- [ ] Revisor independente confirma ausência de recriação e nenhum impacto em outra conta.
- [ ] Data técnica da conclusão separada de envio/entrega da comunicação; falha de e-mail não vira conclusão falsa.
- [ ] Mensagem final diferencia eliminação completa de conclusão operacional com retenção residual; expurgos futuros e acompanhamento definidos.
- [ ] Falhas/desistência/pedido não verificado encerrados com estado verdadeiro; sem prometer restauração após ação irreversível.

## E. Lojas — verificação em fontes oficiais

Fontes consultadas em 15/10/2026 UTC, revalidar antes da submissão:

- [Google Play — account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
- [Apple — 5.1.1(v)](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion), também disponível no [endereço de suporte](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

| Item | Exigência/entendimento da fonte | TORICO atual / decisão |
|---|---|---|
| Google: dentro do app | Caminho claro para excluir conta/dados, podendo levar ao recurso web. | Opção em protótipo de código; ainda sem novo APK. Validar experiência publicada e execução efetiva antes de declarar conformidade. |
| Google: fora do app | Recurso funcional, identificado com app/desenvolvedor, permite pedir exclusão; e-mail/formulário são opções. Sem obrigar reinstalar. | Página pública com atendimento manual existe, conforme auditoria anterior. Revalidar URL/conteúdo antes de submissão; esta missão não publica nem altera página. |
| Google: prazo/retenção | Informar expectativa, cumprir em tempo razoável e explicar retenções justificadas; dados da conta no escopo e Data safety coerente. | Falta aprovar prazo operacional/retenções e comprovar atendimento real. Nenhum prazo numérico de loja/lei é inventado. |
| Apple: início e conclusão | Início no app, remoção efetiva de conta/dados; processo manual pode levar tempo com comunicação clara. Desativar não basta. | App atual prepara e-mail; backend e procedimento operacional homologado ainda faltam. |
| Apple: suporte obrigatório | Apps comuns não devem exigir e-mail, telefone ou chat para concluir. Exceção de setor altamente regulado não se presume. | Fluxo obrigatório por e-mail precisa evoluir para mecanismo no app/site direto. Integrar MP não justifica presumir exceção. Backend pode ser manual por trás, mas usuário não deve depender de contato adicional obrigatório. |
| Comunicação e dados retidos | Ser transparente sobre o que é apagado, mantido e quando termina. | Usar estados verdadeiros e modelos E/F do SOP, somente após evidência; resolver matriz antes de ativação. |

Resumo de fonte, não parecer de aprovação: **o TORICO ainda não deve declarar o requisito concluído nas lojas**. Este SOP não altera Data safety nem formulários. Se Sign in with Apple for adotado futuramente, revisar revogação dos tokens Apple e exigências aplicáveis; não criar integração nesta missão.

- [ ] Google: testar URL pública sem login/reinstalação, caminho no app e processamento/retenções declarados.
- [ ] Apple: permitir iniciar sem e-mail obrigatório, confirmar intenção/identidade de modo proporcional e comunicar conclusão efetiva.
- [ ] Revisar textos de privacidade, página de exclusão e formulários somente com autorização de publicação separada, após aprovar a operação real.

## F. Decisões pendentes e critérios de aceite

| Decisão / risco | Quem deve decidir | Bloqueia |
|---|---|---|
| Sistema do protocolo, privacidade da trilha, papéis/dupla aprovação | Titular + segurança/privacidade | Recepção/gestão auditável e operação real. |
| Métodos de identidade/perda de acesso, prazos e canal após Auth removido | Titular + segurança + revisão jurídica/privacidade | Verificação e comunicação seguras. |
| Todas as retenções, logs/backups/fornecedores e expurgos | Responsável pelos dados + revisão jurídica/privacidade | Conclusão verdadeira e declarações de loja. |
| Barreira, writers ausentes, callback/nonce, fallback e replay | Responsável técnico + segurança | Qualquer exclusão real: risco de recriar dados. |
| Propriedade de grant/revogação MP sem afetar vizinho | Técnico + segurança + titular | Revogação segura e exclusão de credenciais. |
| Staging, simulação, restauração, IAM, kill switch e conferência | Técnico + revisor operacional | Liberação do processamento administrativo. |
| Caminho de produto Apple sem suporte obrigatório, depois publicação | Produto + técnico + titular | Futura submissão Apple; requer missão própria. |

Antes de liberar: cada decisão deve ter dono, evidência, data e aceite; nenhum bloqueador em aberto. Aprovação de documentação não autoriza exclusão de conta real, alteração de código/Rules, revogação MP ou deploy. **Solicitar autorização separada para implementar controles, testar em staging e posteriormente ativar produção.**

## Revisão desta entrega documental

- Escopo: somente estes três documentos; auditoria e proposta de backend preservadas como histórico.
- Conferência: links locais, presença de modelos/registro/matriz/gates e fontes oficiais; revisão de linguagem sem promessa de exclusão já realizada.
- Sem flutter analyze/test/build: não há mudança de código executável, nem novo teste de runtime. Testes futuros do backend continuam especificação, não resultados executados.
- Sem comandos de exclusão, UID real nos exemplos, dados pessoais de clientes, credenciais ou campos preenchidos de produção.
