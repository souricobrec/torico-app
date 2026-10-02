# TORICO — migração da API oficial

Endpoint de produção pretendido: `https://api.meutorico.com.br`.
Backend existente a preservar: `https://torico-backend-16783123127.us-central1.run.app`.

## Situação verificada em 01/10/2026

- Repositório `souricobrec/torico-app` obtido via fetch/checkout, preservando este documento. Branch `feature/api-meutorico-domain` criada a partir de `origin/visual-pre-lojas`; a branch de origem não foi alterada.
- Consulta DNS local retornou NS `d.sec.dns.br` e `f.sec.dns.br` para `meutorico.com.br`: a delegação pública consultada está no Registro.br. Isso não comprova se existe uma zona cadastrada, mas inativa, no Cloudflare.
- Consulta do subdomínio `api.meutorico.com.br` retornou nome inexistente.
- Health check público oficial padronizado em `/health`; `/healthz` permanece apenas alias opcional e não é requisito da migração.
- Nenhum DNS, serviço, webhook, Scheduler ou fluxo de pagamentos foi alterado.

## Alterações no código, após obter o repositório

### Implementação nesta branch

- `lib/config/api_config.dart` centraliza `APP_ENV`/`API_BASE_URL`; o app valida ao iniciar e o serviço OAuth consome a base única. Build sem defines assume produção e o domínio oficial. Não publicar antes da ativação do domínio.
- Desenvolvimento deve ser explicitado; preview exige uma URL HTTPS. Para preservar o preview atual até a migração, usar o run.app explicitamente como abaixo.
- `backend/server.js` mantém o override `PUBLIC_BACKEND_URL`, com default no domínio oficial. Variáveis já configuradas no Cloud Run continuam prevalecendo. `MERCADO_PAGO_REDIRECT_URI` conserva o fallback run.app deliberadamente: alterar manualmente a variável e o cadastro do provedor juntos após validar o domínio. Revisar `PUBLIC_BACKEND_URL` antes de qualquer deploy; ele também é usado por PagBank.
- `/health` retorna JSON público mínimo em produção. Detalhes exigem autorização interna; consultar public-health-check.md. A raiz anuncia `/health`.
- localhost encontrado no bloqueio de domínio é exceção de testes locais, não destino de API. Documentos antigos mantêm URLs run.app como histórico e operação durante a transição.
- `DomainBlockService` continua bloqueando o app nos hosts públicos na fase pré-lojas. Validar login/painel em preview liberado; liberar o app público é uma decisão separada.
- `.gitignore` passa a ignorar `.env.*`, exceto exemplos sem credenciais.

```powershell
# Desenvolvimento local
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://localhost:3333
# Preview durante a transição, mantendo o backend validado
flutter build web --release --dart-define=APP_ENV=preview --dart-define=API_BASE_URL=https://torico-backend-16783123127.us-central1.run.app
# Teste isolado do contrato de saúde; executar sem backend/.env
cd backend
node --test test/health.test.js
```

Não houve mudança na lógica de processamento Mercado Pago/REDE, no CORS existente ou nas regras Firestore. As validações reais de integrações ficam no checklist manual.

1. Ler `AGENTS.md`, conferir status e criar `feature/api-meutorico-domain` a partir de `visual-pre-lojas`, sem descartar alterações locais.
2. Localizar URLs no app, backend, configurações e CI; classificar referências legítimas (docs, testes, emuladores, audiência OIDC) antes de substituir.
3. Preservar configuração existente. Se ausente, usar configuração única via `--dart-define` com `APP_ENV` e `API_BASE_URL`, consumida por todos os clientes HTTP.
4. Produção: base `https://api.meutorico.com.br`, HTTPS obrigatório. Desenvolvimento: localhost apenas explicitamente nesse ambiente. Preview: URL HTTPS explícita, sem fallback silencioso para produção. Ambiente desconhecido ou configuração inválida deve falhar em execução, inclusive release, sem depender de assertions.
5. Rejeitar credenciais embutidas, query/fragment e URLs inválidas na base. Não alterar caminhos das rotas nem lógica Mercado Pago/REDE. Verificar CORS para as origens reais da PWA, inclusive preflight e cabeçalhos de autenticação.
6. `--dart-define` e assets da PWA são públicos: usar somente valores públicos. Segredos permanecem no backend/Secret Manager. Não versionar `.env` com credenciais nem gravar tokens em Firestore público. Preservar autenticação, autorização por usuário/loja e verificação de assinatura dos webhooks.
7. Revisar ou implementar `GET /health` no framework existente: HTTP 200, JSON abaixo, sem dados internos ou segredos. É liveness do serviço, não certificação de saúde dos adquirentes. Não chamar APIs de pagamento nessa rota.

```json
{"ok":true,"service":"torico-backend","status":"healthy"}
```

## Procedimento manual de infraestrutura

### Inventário e DNS

- Confirmar projeto Google Cloud, serviço, região, revisão ativa, autenticação/ingress e jobs atuais. Não inferir o ID de projeto pelo número na URL.
- Acessar Cloudflare e verificar se a zona existe e está ativa. Se migrar a delegação, inventariar e copiar antes todos os registros atuais, incluindo MX, TXT, SPF, DKIM e DMARC. Planejar DNSSEC/DS com o registrador para evitar SERVFAIL. Não mudar nameservers somente para criar este subdomínio.
- Se permanecer no Registro.br, criar os registros na autoridade DNS atual. Cloudflare é opcional para o domínio da API.

### Roteamento até o Cloud Run

Para produção, a opção recomendada pelo Google é um **global external Application Load Balancer**, com serverless NEG apontando para o serviço Cloud Run existente em `us-central1`. Configurar IP estático, frontend HTTPS, certificado para `api.meutorico.com.br` e URL map preservando todos os caminhos até o backend. Há custos de infraestrutura a avaliar antes de provisionar.

Criar registro `A` de `api` para o IP do balanceador. Começar com DNS only se usar Cloudflare, e seguir o método de validação do certificado escolhido, incluindo registros de autorização DNS quando aplicáveis. Esperar certificado ativo e validar HTTPS antes de encaminhar clientes.

Alternativa: Cloud Run Domain Mapping está disponível em `us-central1`, mas a documentação do Google o classifica como Preview e não recomendado para produção. Se escolhido conscientemente, verificar propriedade do domínio, criar mapping para o serviço existente e copiar **exatamente** os registros retornados pelo Google para o DNS autoritativo. A emissão do certificado pode levar até 24 horas.

**Um CNAME diretamente para a URL run.app, sozinho, não configura domínio, certificado e roteamento HTTP.** Usar o destino fornecido pelo mecanismo escolhido. Não remover o serviço, não desabilitar run.app e não restringir ingress nesta migração, pois consumidores antigos ainda dependem dele.

Se habilitar proxy Cloudflare após validação, usar TLS Full (strict), certificado válido na origem e conferir host/SNI. Não usar Flexible. Configurar bypass de cache para API, autenticação, webhooks e sync. Evitar desafios de navegador para chamadas de app, Mercado Pago e Scheduler. Não exigir Cloudflare Access nessas rotas sem integração específica.

### SSL, aplicação e integrações

1. Validar `/health` no domínio antigo e novo: 200, JSON esperado, certificado válido e ausência de redirecionamento para login. Nenhum bypass TLS deve ser usado para declarar sucesso.
2. Validar CORS e autenticação no domínio novo usando preview do app antes de publicar produção. Revisar URLs públicas geradas no backend, callback OAuth e allowlists do Mercado Pago, se existentes.
3. Atualizar manualmente a URL do webhook Mercado Pago, mantendo caminho, assinatura, segredo e idempotência existentes. Verificar também `notification_url` gerada pelo backend, se usada. Registrar configuração anterior em local privado e testar entrega sem provocar cobrança real.
4. Atualizar manualmente o alvo HTTP do Cloud Scheduler REDE, mantendo caminho, método, body, cron, timezone, retries e mecanismo de autenticação. Evitar jobs duplicados.
5. Se Scheduler usa OIDC validado pelo IAM do Cloud Run, manter audiência no valor oficial retornado em `status.url` do serviço, salvo custom audience configurada e validada. Não trocar automaticamente `aud` para o domínio novo. Preservar conta de serviço e `roles/run.invoker`. Se a autenticação for implementada pelo app, preservar o mecanismo atual e validar no novo domínio.
6. Publicar build Flutter/PWA com configuração de produção somente após domínio e integrações validados. Conferir cache/service worker e cliente atualizado. Manter build anterior para rollback.

## Checklist pós-mudança

- [ ] DNS resolve para a infraestrutura escolhida e SSL é válido.
- [ ] `GET /health` novo retorna 200 e JSON esperado; run.app continua disponível.
- [ ] Login no app funciona; sessão e CORS/preflight funcionam.
- [ ] Conexão Mercado Pago e callback funcionam com conta de teste.
- [ ] Webhook Mercado Pago chega, valida assinatura e não duplica vendas.
- [ ] Sync manual REDE conclui sem duplicar vendas.
- [ ] Cloud Scheduler REDE conclui com autenticação e audiência corretas.
- [ ] Painel/histórico carregam vendas para a loja correta.
- [ ] Usuário sem autorização não acessa vendas de outra loja.
- [ ] Build de produção não chama localhost nem backend antigo; audiência OIDC e documentação são exceções justificadas.
- [ ] Nenhuma credencial está no diff, build Flutter, logs públicos ou Firestore público.
- [ ] Registrar data, revisão/build, responsável e evidência de cada teste, sem tokens/dados pessoais.

## Comandos de validação

Executar no repositório real. Comandos Flutter pressupõem a configuração proposta; adaptar ao padrão existente após inspeção.

```powershell
git status --short --branch
git switch -c feature/api-meutorico-domain visual-pre-lojas
rg -l --hidden -g '!.git/**' -g '!build/**' -g '!**/.env*' 'torico-backend-16783123127|https?://|localhost|127\.0\.0\.1' .
Resolve-DnsName meutorico.com.br -Type NS
Resolve-DnsName api.meutorico.com.br -Type A
curl.exe --fail-with-body --silent --show-error --max-time 30 -i https://torico-backend-16783123127.us-central1.run.app/health
curl.exe --fail-with-body --silent --show-error --max-time 30 -i https://api.meutorico.com.br/health
$health = Invoke-RestMethod https://api.meutorico.com.br/health -TimeoutSec 30
if ($health.ok -ne $true -or $health.service -ne 'torico-backend' -or $health.status -ne 'healthy') { throw 'Health check inesperado' }
flutter analyze
flutter test
flutter build web --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.meutorico.com.br
git diff --check
git diff --stat
```

A busca usa `-l` para listar arquivos, reduzindo risco de imprimir valores sensíveis. Revisar os arquivos localmente. Executar testes do backend conforme sua stack, incluindo contrato do health check e regressões de autenticação/integração existentes. Confirmar a base nos requests reais da PWA, não apenas no fonte.

## Validação executada nesta branch

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub test/api_config_test.dart`: 3 testes passaram.
- `node --check backend/server.js`: sintaxe válida.
- `node --test test/health.test.js` (em backend): passou; servidor real local, sem credenciais, retornou 200, JSON exato e Cache-Control no-store.
- Build web release com os defines de produção: concluído, sem deploy.
- Revalidar `/` e `/health` após deploy: a raiz deve anunciar `/health` e o endpoint público deve retornar o JSON mínimo.

## Procedimento de rollback

Manter URL run.app, revisão do backend e build anterior disponíveis. Se a migração falhar, republicar o build anterior e restaurar manualmente URLs dos webhooks e Scheduler com suas configurações privadas anteriores. Não executar dois jobs de sync em paralelo. Não introduzir fallback automático entre domínios para requisições financeiras, pois retries podem duplicar operações.

## Referências oficiais

- [Google Cloud: opções de domínio e limitações de Domain Mapping](https://docs.cloud.google.com/run/docs/mapping-custom-domains)
- [Google Cloud: autenticação e audiência OIDC](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)
- [Cloudflare: TLS Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/)

Código preparado nesta branch e health check validado localmente. Infraestrutura e health check remoto continuam pendentes; nenhum deploy foi executado.
