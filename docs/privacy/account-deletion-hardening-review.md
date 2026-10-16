# Correções da auditoria de recebimento de solicitações

Base: `5bdb24f`. Branch: `codex/account-deletion-hardening`.
Escopo: homologação local. Não autoriza ativação, exclusão efetiva ou expurgo.

## Cinco achados

1. **Rate limiting e proxies.** A origem considerada é exclusivamente o endereço do socket TCP. `req.ip`, `X-Forwarded-For`, `Forwarded` e configurações globais de confiança em proxy não são usados para decidir essa origem. Atrás de ingress, esse endereço pode representar o proxy, não o usuário: não o apresentar como identificação individual. Permanecem 120 tentativas/minuto por peer/processo; acrescentou-se uma quota global fixa de 600 tentativas/minuto em transação Firestore, compartilhada entre instâncias antes da verificação do token. As quotas por UID continuam em 5 registros e 30 consultas/minuto. Somente estas rotas usam as novas quotas.
   - O bucket global tem identificador fixo; não cria documentos a partir de IPs enviados pelo cliente. Falha do banco impede continuidade. A quota contabiliza tentativas, inclusive sem autenticação.
   - Não é um WAF nem proteção DDoS: requisições ainda chegam ao processo/banco. O bucket global pode sofrer contenção e um atacante pode consumir disponibilidade compartilhada. Homologar carga, orçamento e limites antes de qualquer ativação. Controle distribuído na borda e eventual identificação de IP do usuário exigem desenho de ingress confiável, prevenção de acesso direto e autorização de infraestrutura. **Essa parte permanece pendente; nenhum proxy, IAM ou recurso externo foi alterado.**
2. **JSON.** O dispatcher de exclusão foi montado antes do parser global. O módulo verifica bloqueio e quota e depois usa parser próprio de 2.048 bytes, sem descompressão. Excesso retorna 413 antes da verificação do token; JSON inválido retorna 400. O parser global de 1 MB permanece para as APIs existentes. O módulo desligado retorna 404 sem interpretar o corpo.
3. **Idempotência.** Índice por UID e protocolo continuam transacionais. Há no máximo 16 documentos de alias criados para uma solicitação nova. Depois disso, novas chaves retornam o mesmo protocolo sem criar alias; versões de consentimento divergentes são recusadas. Índices antigos sem contador não recebem aliases adicionais. Nenhum registro existente foi excluído ou migrado. Solicitações antigas que já tenham mais de 16 aliases exigem inventário e decisão futura; o código não as reduz automaticamente.
4. **Observabilidade.** Eventos JSON com campos fixos `component`, `event`, `stage`, `status`: falha de autenticação, limite excedido, falha de operação de armazenamento/transação, indisponibilidade, rejeição, recebimento e duplicidade. Não incluem UID, IP, e-mail, protocolo, token, senha, cabeçalhos, corpo ou mensagens do SDK. Falha do observador não muda o resultado HTTP. Em produção ainda faltam métricas/alertas, controle de volume de logs e definição de acesso/retenção; nenhum coletor foi instalado.
5. **Limpeza local.** `clearDeviceData()` remove todas as chaves com prefixo `torico_deletion_intake_key_`, inclusive de contas usadas anteriormente no navegador. Não chama o backend. Após nova autenticação, `GET requests/current` recupera o protocolo durável sem depender da chave local; um novo POST também encontra o índice do titular, sujeito à autenticação recente. Não altera a limpeza dos demais dados nem remove preferências não relacionadas.

## Bloqueio de produção

O helper `intakeEnabled` exige flag exatamente `true`, projeto `demo-*`, dois hosts de emulador em loopback com portas válidas, ausência de `K_SERVICE`, ausência de caminhos de credenciais e aliases de projeto consistentes. A matriz é exercitada por testes executáveis; o teste HTTP do servidor continua forçando a flag fora desse conjunto e verificando 404.

Não há mecanismo HTTP para trocar a configuração. O gate é defesa contra configuração acidental, não contra quem possa editar código ou ambiente do processo. Seu eventual substituto para produção precisará de revisão separada. O dart-define continua desativado por padrão. Não há endpoints administrativos/destrutivos, worker de exclusão ou consumo destrutivo da outbox.

## Homologação e reprodução

- `flutter analyze --no-pub`
- `flutter test --no-pub --reporter compact`
- `node --test backend/test/*.test.js`
- Integração opt-in: `node backend/test-support/run-deletion-emulators.cjs <caminho-local/firebase-tools/lib/emulator/auth/index.js> <caminho-local/cloud-firestore-emulator-v1.21.0.jar>`

O runner usa ferramentas oficiais já instaladas, ambiente filho sanitizado e diretório de configuração isolado. Não inicia Firebase CLI, não herda credenciais/ADC, não importa/exporta dados. Recusa portas ocupadas; cria e encerra somente os emuladores locais nas portas 19099/18891, projeto `demo-torico-intake`. O teste cria contas fictícias apenas no Auth Emulator e revoga token de uma dessas fixtures para verificar rejeição. Isso não revoga credenciais Mercado Pago nem modifica usuários reais. Firestore é acessado explicitamente em loopback, com as Rules locais.

Os casos cobrem token emitido pelo emulador, inválido e revogado, janela de autenticação recente, consultas entre UIDs, concorrência, Rules privadas, recuperação após falha, aliases limitados, proxy headers falsificados, quota compartilhada, 413 e manutenção do parser das demais APIs. Flutter simula SDK/transporte e reautenticação Google/senha nos caminhos web e nativo; não substitui teste em aparelho ou navegador real. O emulador aceita tokens não assinados: essa homologação não comprova validação criptográfica de JWT de produção, delegada ao SDK Firebase Admin.

## Retenção e expurgo — proposta, sem ativação

| Registro | Limite/controle atual | Decisão necessária antes de expurgo |
|---|---|---|
| Pedido, subject, índice e evento | Um pedido corrente por UID nesta fase | Prazo aprovado, fundamento, encerramento, recuperação e evidência mínima |
| Aliases de idempotência | Até 16 novos por pedido | Janela de retry; nunca remover o índice antes de garantir deduplicação |
| Quotas | Um documento por UID/operação; um global | Prazo de inatividade e tratamento de disputas com pedidos em voo |
| Outbox não executável | Um sinal por pedido | Atendimento concluído e prova de que nenhum consumidor depende dele |
| Logs e backups | Nenhuma política nova aplicada | Acesso mínimo, prazo aprovado, restauração e reaplicação de exclusões futuras |

`resetAt` continua sendo fronteira de quota, **não TTL de exclusão**. Não se definiu prazo legal, habilitou TTL, criou job ou escreveu ferramenta de limpeza. A proposta de expurgo deve prever simulação, aprovação, inventário, concorrência e auditoria antes de implementação. A matriz de retenção anterior continua sujeita à aprovação humana.

## Parecer e pendências

Apto para próxima homologação **isolada** após revisão do diff e dos resultados. Não apto para ativação em produção: permanecem decisões de retenção, proteção de borda/carga, IAM/Rules implantadas (não consultadas), monitoramento e responsável pelo atendimento. Reautenticação Google/senha e troca de sessão ainda precisam de homologação em Android/PWA reais. Exclusão efetiva e proteção contra eventos tardios continuam fora desta fase.

Rollback de desenvolvimento: reverter apenas o commit desta branch. Sem deploy ou migração, não há rollback de produção a executar. Em uma futura implantação, desligar o recebimento não deverá apagar protocolos nem impedir o atendimento dos pedidos já recebidos.

## Resultados desta revisão — 15/10/2026

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --reporter compact`: 91 testes aprovados.
- `node --test backend/test/*.test.js`: 33 testes aprovados.
- Auth + Firestore Emulator: PASS para tokens válidos/inválidos/revogados, autenticação recente, isolamento, concorrência e Rules privadas. Processos iniciados pelo runner encerrados sem exportação.
- Teste final de regressão com `trust proxy` ligado no aplicativo de teste: passou; cabeçalhos falsificados não alteram a origem usada pelo limitador.
- `git diff --check` nos arquivos da entrega: sem erros.
- Nenhum deploy, expurgo, APK/AAB ou alteração de credenciais, serviço, Rules implantadas, IAM ou dados reais. Alterações locais anteriores fora do escopo não são incluídas no commit.

Na preparação houve bloqueio de loopback/cache pelo sandbox; as execuções finais autorizadas passaram. O adaptador de teste Firestore foi ajustado para acesso explícito ao emulador, pois o Admin SDK não aceita a credencial fictícia personalizada para Firestore. O teste de janela recente usa token realmente emitido pelo Auth Emulator e desloca somente o relógio injetado do router. Não utiliza token forjado para representar sucesso de autenticação.
