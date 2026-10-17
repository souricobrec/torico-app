# TORICO — correção da confiança, renovação e antirrollback

Branch: `codex/certification-trust-anchor-fix`. Base: `e8d48be`; auditoria: `certification-independent-audit-e8d48be.md`.

## Entrega e bloqueio de produção

Foram implementadas as correções locais e o contrato testável da âncora independente. **Não existe adaptador real, persistente e aprovado nesta entrega. Nenhum adaptador de produção foi implementado ou conectado.** A configuração também recusa explicitamente projetos não `demo-*`; ausência de binding de confiança/âncora falha com 503. Não há flag ou marker capaz de liberar produção.

A âncora em memória só existe em `backend/test-support/`, aceita apenas projeto demo, não é durável nem distribuída e não é importada pelo caminho do servidor. Ela modela CAS monotônico e leases para os testes; não comprova durabilidade, proteção IAM ou coordenação distribuída real.

## Correções

| Achado | Mudança | Evidência |
| --- | --- | --- |
| marker.env troca âncoras | Schema fechado do marcador; seleção explícita dos bindings; contexto de confiança criado pela composição confiável do servidor, separado dos dados | env/now/projectId extras rejeitados nos unitários e leituras Firestore Emulator; chaves de outro par não passam nem quando selecionadas por âncora sintética |
| marker.now burla expiração | Relógio do contexto confiável, sem defaults oriundos de dados; 30 s apenas para emissão futura, zero grace na expiração | Certificado expirado rejeitado com marcador limpo e com relógio adulterado; testes do limite 30.000/30.001 ms |
| Renovação aceita retorno antigo | Geração assinada e certificateId devem corresponder à âncora independente; formato `certified-index-v2` | Restaurar marcador de certificado anterior ainda válido retorna 503; contador reduzido é recusado; não há fallback para v1 |
| Revogação/concorrência sem contrato | CAS exige g→g+1, revogação também avança; lease abrange transação/commit antes de renovação/revogação concluir | Um vencedor entre renovações concorrentes; renovação aguarda commit em voo; revogação bloqueia marcador antigo; recuperação exige geração nova |

Identidade do projeto e duas chaves públicas distintas são validadas fora do Firestore. Independência organizacional/custódia dos signatários não pode ser comprovada por teste criptográfico; permanece aprovação operacional. Não foram criadas chaves reais nem lidos secrets. Chaves dos testes são efêmeras em memória.

As correções não alteram ID Token/revogação, UID autenticado, nonce/replay, quota, callback/client/webhook Mercado Pago, criptografia ou estrutura privada das integrações. Perfil/plano/preços, REDE/Scheduler, dados reais e exclusão de conta não foram tocados.

## Testes executados

| Validação | Resultado |
| --- | --- |
| `flutter analyze --no-pub` | Sem problemas |
| `flutter test --no-pub --reporter expanded` | 96 aprovados |
| `node --test backend/test/*.test.js` | 65 aprovados, zero falhas |
| Auth/Firestore Emulator | Regressões de autenticação, revogação, Rules/planos, quota, titularidade/concorrência, nonce/replay, callbacks tardios e reconexão aprovadas |
| Adulteração | Env/now/projeto no marcador rejeitados; assinatura/certificado/revisão/evidência inválidos continuam bloqueados |
| Expiração | Certificado expirado rejeitado mesmo quando a âncora sintética aponta para ele; relógio do marker não altera validade |
| Renovação/rollback | Geração monotônica, único vencedor CAS, retorno de marcador antigo bloqueado, redução do contador recusada |
| Revogação/falhas | Estado revoked e falha de leitura retornam 503; sem âncora não inicia processamento DB; recuperação só com geração superior; integração preservada |
| Contexto de produção | Tentativa de configurar projeto real/fake não-demo rejeitada explicitamente; nenhuma conexão real efetuada |
| Regressão PWA | Hashes, nomes especiais, inclusão/exclusão/adulteração, assets e rollback local aprovados na suíte backend |

Evidências locais: `.tmp-certification-anchor-fix/backend.log`, `flutter.log`, `emulators.log`, `anchor-results.json`. Projeto exclusivo `demo-torico-intake`, loopback, ambiente filho sanitizado, sem ADC/CLI/secrets reais. Os testes de âncora não certificam inventário real nem implementam migrador. Contenção distribuída, crash/fencing/restart multi-instância e IAM real não foram testados.

## Modelo, renovação e falhas

Contrato e procedimento detalhados: [certification-anchor-trust-model.md](certification-anchor-trust-model.md).

O contador não reside somente no marcador reversível. A proposta exige autoridade independente, checkpoint durável contra restauração, CAS e lease compartilhada/exclusiva até o commit. Um simples GET de outro documento seguido de commit não satisfaz o contrato. O runtime não finge que esse serviço já existe.

Renovação futura: candidato g+1 assinado/reconciliado, preparação de evidências imutáveis, janela segura para marker/âncora, avanço CAS e confirmação autoritativa. Divergência entre marker e âncora causa indisponibilidade segura. Não restaurar g se CAS de g+1 pode ter sido aplicado. Falha de rede pode deixar resultado incerto; investigar a autoridade, não repetir OAuth/reabrir nonce nem afirmar que nada foi gravado. Revogação avança geração e drena leases; recuperação exige geração maior, reservas preservadas e certificado válido.

## IAM, infraestrutura e autorizações pendentes

- Escolher/desenhar autoridade persistente independente e provar proteção contra reset/restore; não há serviço escolhido, criado ou consultado.
- Aprovar adaptador distribuído, fencing, duração/timeout de lease, idempotência de renovação, journal, recovery de commit incerto e testes de falha entre dois sistemas.
- Definir IAM concreto após escolha do serviço: backend só leitura/lease; renovador/revogador com CAS sob controle separado; sem permissão da aplicação para reduzir/restaurar estado. Administradores do Firestore de aplicação não administram a autoridade independente.
- Definir custódia independente dos dois signatários, rotação, protocolo de aprovação de certificados, retenção e monitoramento de disponibilidade/latência, divergência de geração, falha CAS, expiração e skew.
- Autorizar separadamente inspeção real, inventário, migração, instalação de configuração, remoção do bloqueio não-demo e deploy. Nenhuma dessas ações decorre desta entrega.

SOP de leitura permanece não executado; projeção do marker foi atualizada para incluir generation e explicitar que a autoridade independente não está entre recursos reais já autorizados. Alterações locais antigas não fazem parte do commit.

## Parecer

**Apto para nova auditoria independente do código/contrato e continuidade de homologação isolada. Não apto para ativação real, migração ou deploy.** As vulnerabilidades de injeção pelo marcador e restauração de certificado antigo foram bloqueadas nos testes, dentro do modelo de âncora sintética; a garantia real de antirrollback depende da autoridade persistente e do adaptador ainda não aprovados.

Nenhuma produção foi alterada; não há rollback real a executar. Para futura recuperação, preservar gerações/reservas e usar somente revisão compatível com certificado/âncora válidos. Não usar retorno a v1, marcador antigo ou memória local como contingência.
