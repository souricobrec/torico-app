# TORICO — confiança e antirrollback da certificação MP

Branch `codex/certification-trust-anchor-fix`, base `e8d48be`. Implementação local e contrato de infraestrutura futura. **Nenhum adaptador de produção foi implementado ou conectado.**

## Estado de ativação

O runtime não tem fallback de âncora em Firestore, env, arquivo ou memória. Sem composição explicitamente confiada, retorna `certification_anchor_unconfigured`. Nesta fase, `configureCertificationRuntime` também recusa qualquer projeto que não seja `demo-*`, com `certification_production_anchor_not_approved`.

Portanto, não basta criar documentos, restaurar marker, definir env vars ou assinar certificado para ativar produção. Nem um adaptador fornecido programaticamente habilita um projeto real nesta versão. Remover esse bloqueio, escolher/conectar infraestrutura e instalar âncoras/chaves requerem autorização e revisão posteriores.

`memory-certification-anchor.mjs` é somente fixture: aceita projeto demo, não persiste dados, não é distribuído e perde estado ao reiniciar. Ele nunca é importado pelo caminho de produção. Não constitui prova de durabilidade ou de separação IAM.

## Correção da fronteira de confiança

O documento `mp_ownership_index/active` tem schema fechado: version, state, epoch, certificateId, sourceRevision, writerProtocol e generation. `env`, `now`, projectId ou qualquer outro campo adicional são rejeitados. O verificador recebe apenas bindings explicitamente selecionados do documento, separados do contexto confiável.

Contexto confiável é configurado pelo código de composição do servidor, fora de documentos/requests: identidade do projeto, duas chaves públicas Ed25519 distintas já analisadas e relógio. Projeto configurado deve coincidir com o cliente de banco. Dados persistidos não podem substituir esse contexto. Não há nova leitura automática de credenciais nem interpretação de código vindo de configuração.

O relógio padrão é `Date.now` do servidor. Tolera-se emissão até 30 segundos à frente, para pequeno skew entre signatários/servidor; **expiração tem zero grace** (`expiresAtMs <= now` rejeita). Lease máxima de captura/expiração continua 24 h, proposta conservadora ainda sem SLA de renovação real aprovado. Clock inválido, certificado adulterado ou projeto divergente falham seguros.

São duas chaves criptograficamente distintas. Independência das pessoas, custódia, processos e proteção das chaves privadas ainda exigem aprovação operacional; teste com duas chaves efêmeras não comprova isso. Backend deve receber somente chaves públicas, nunca privadas dos signatários.

## Geração assinada e âncora independente

Formato novo usa `writerProtocol = certified-index-v2`. Certificado e marcador incluem `generation`, inteiro seguro positivo assinado no payload. A âncora independente contém:

```text
projectId | generation | certificateId | state(active/revoked)
```

Projeto, geração e certificado devem coincidir exatamente entre certificado assinado, marcador e snapshot da âncora. Uma geração antiga é rejeitada mesmo que sua assinatura e prazo ainda sejam válidos. Trocar só o contador/ID do marcador não altera a âncora.

Modelo sintético exige CAS de `g` para **exatamente `g+1`**; concorrentes partindo de g têm um vencedor. Revogação também avança a geração e torna o estado inativo. Recuperar exige geração maior e certificado novo corretamente assinado — nunca decrementar ou restaurar uma geração antiga.

## Contrato exigido do adaptador futuro

Não é suficiente uma chamada `get()` a outro documento reversível. O adaptador precisa de:

1. Estado autoritativo persistente, linearizável e protegido contra reset/restauração. Checkpoint de maior geração não pode voltar com restore do banco de aplicação.
2. Domínio de autoridade separado do marker/owners. Quem pode escrever Firestore de aplicação não pode reduzir, restaurar ou administrar a âncora.
3. Leitura com lease compartilhada (`withCurrent(project, callback)`) mantida até a transação Firestore terminar, incluindo commit e retries. Renovação/revogação usa exclusão mútua e CAS monotônico; não pode ultrapassar operação com lease antiga ainda em commit.
4. Recuperação durável após crash, fencing de clientes com lease perdida, limites/timeout e prova de que nenhum commit com geração antiga ocorre após a conclusão autoritativa da revogação. Isso precisa de implementação distribuída real e auditoria própria; o modelo local não prova esse requisito.
5. Sem cache stale, fail-open ou fallback em indisponibilidade. A falha antes do processamento retorna 503 sem iniciar a transação. Falha em andamento requer tratamento de resultado incerto e investigação, não repetir código OAuth ou afirmar ausência de gravação.

O código protege o ciclo da transação por `withCurrent`; o mecanismo distribuído que deverá cumprir esse contrato **não existe nesta entrega**. Essa dependência mantém produção bloqueada. Não escolher um fornecedor, criar recurso ou inventar permissões IAM concretas sem aprovação.

## Renovação proposta (não executável em produção nesta fase)

1. Ler estado autoritativo g com identidade administrativa aprovada. Reconciliar inventário/deltas, produzir certificado candidato g+1, obter as duas revisões/assinaturas e conferir validade/chaves/projeto.
2. Preparar certificado e fragmentos imutáveis inativos no banco, em missão de escrita separadamente autorizada. Não alterar owner/UID/credenciais durante renovação de evidência.
3. Planejar janela de indisponibilidade segura: marcador candidato antes do avanço da âncora pode causar 503 por mismatch. Não prometer troca atômica entre duas infraestruturas sem protocolo demonstrado.
4. Publicar marcador candidato e executar CAS autoritativo de g para g+1/certificateId, drenando leases antigas. Validar estado autoritativo e marcador antes de considerar renovação concluída.
5. Se houver concorrente vencedor, não tentar sobrescrevê-lo ou diminuir geração. Conferir identidade do vencedor e reparar somente o ponteiro para evidência aprovada da geração vigente, sob procedimento autorizado.
6. Após conclusão, marcador antigo ou backup antigo não reativa g. Histórico de certificados pode permanecer para auditoria conforme retenção, mas não ganha autoridade por existir.

O fluxo acima é proposta para homologação futura. Não há writer/endpoint administrativo implementado. Em falha parcial, consultar a autoridade independente: erro de rede não prova que CAS não ocorreu. Se CAS foi aplicado, nunca restaurar g; se resultado permanece desconhecido, manter falha segura e escalonar.

## Revogação e recuperação

Revogação autoritativa avança para g+1/revoked, após drenar operações antigas. Marcadores antigos/novos não a contornam. Falta de âncora ou falha de leitura bloqueia uso, sem desconectar Mercado Pago nem apagar tokens/histórico.

Recuperação exige identificar estado autoritativo, causa da falha e reservas novas. Reestabelecer disponibilidade da âncora com prova de não regressão; emitir certificado novo de geração superior se necessário. Não restaurar memória local, backup de geração antiga, certificado expirado ou alterar relógio para liberar tráfego.

## IAM e monitoramento — dependências, não alterações realizadas

Capacidades lógicas a converter em IAM só após escolha aprovada de infraestrutura:

- Backend: identidade/autenticidade da autoridade e leitura/lease da geração vigente; sem avançar/revogar/resetar/restaurar checkpoint.
- Autoridade: conta própria mínima para ledger persistente/fencing; aplicações não recebem suas credenciais de escrita/administração.
- Renovador/revogador: avanço CAS em projeto específico sob dupla aprovação e trilha de auditoria; sem downgrade/restore unilateral.
- Auditores: leitura sanitizada. Administradores de backup/restore não podem reverter o checkpoint de maior geração sem mecanismo independente de detecção e recuperação.

Esses nomes são **capacidades de contrato**, não permissões GCP implementadas. Nenhum IAM, segredo, recurso ou policy real foi lido/criado/modificado.

Antes de ativar, definir alertas para indisponibilidade/latência de lease, falhas CAS, geração/certificateId divergentes, revogação, prazo de renovação e clock skew. Logs só códigos e identificadores técnicos necessários, sem tokens/UIDs ou inventários completos. Definir SLO e testes de crash/rede/restore multi-instância, rotação de chaves e contingência. Não criar dashboards/alertas automaticamente nesta missão.

## Compatibilidade

Certificados v1 sem geração ou apenas ready não são aceitos. O fluxo OAuth/autenticação/criptografia e a estrutura privada das integrações permanecem. Não há migração, publicação de cliente ou deploy. Integrações atuais de produção não foram tocadas; **este código não pode ser implantado antes de implementar e aprovar uma âncora real e sua operação**.
