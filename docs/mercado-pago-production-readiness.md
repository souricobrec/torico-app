# Checklist de Produção — Mercado Pago

## Objetivo

Este documento registra o plano de preparação do TORICO para uso real com Mercado Pago em produção.

A integração já foi validada em ambiente sandbox/MVP, com webhook funcionando, Firestore recebendo vendas e painel TORICO atualizando os valores em tempo real.

Antes de liberar para uso real com comerciantes, é necessário separar claramente o que é teste, o que é MVP controlado e o que será produção multiusuário.

---

## Status atual

Status técnico atual:

* Backend publicado no Cloud Run.
* Firebase Hosting ativo para o app/PWA.
* Firestore recebendo vendas vindas do webhook.
* Webhook Mercado Pago funcional.
* Eventos `merchant_order` validados.
* Eventos `payment` em formato legado/data.id validados.
* Rotas de teste bloqueadas por `ENABLE_TEST_ENDPOINTS=false`.
* Documentação de segurança atualizada.
* Código versionado no GitHub.

---

## Ambiente atual

Backend público:

https://torico-backend-16783123127.us-central1.run.app

App/PWA:

https://torico-ca479.web.app

Projeto Firebase:

torico-ca479

Serviço Cloud Run:

torico-backend

Região:

us-central1

---

## Rotas de produção permitidas

As rotas que devem permanecer disponíveis em produção são:

* `/health`
* `/webhooks/mercado-pago`

A rota `/health` é usada para validar se o backend está ativo.

A rota `/webhooks/mercado-pago` precisa continuar pública, pois é o endpoint que recebe as notificações oficiais do Mercado Pago.

---

## Rotas de teste bloqueadas

Com `ENABLE_TEST_ENDPOINTS=false`, as seguintes rotas ficam bloqueadas:

* `/test-client`
* `/simulate-sale`
* `/mercado-pago/create-test-preference`

Essas rotas são úteis apenas para testes, sandbox e validações internas.

---

## Variáveis principais

Variáveis já usadas no backend:

* `PORT`
* `FIREBASE_PROJECT_ID`
* `FIREBASE_SERVICE_ACCOUNT_PATH`
* `TORICO_DEV_KEY`
* `ENABLE_TEST_ENDPOINTS`
* `TOKEN_ENCRYPTION_KEY`
* `MERCADO_PAGO_CLIENT_ID`
* `MERCADO_PAGO_CLIENT_SECRET`
* `MERCADO_PAGO_REDIRECT_URI`
* `MERCADO_PAGO_WEBHOOK_SECRET`
* `MERCADO_PAGO_ACCESS_TOKEN`
* `MERCADO_PAGO_DEFAULT_USER_ID`
* `PUBLIC_BACKEND_URL`
* `PUBLIC_APP_URL`

---

## Modelo atual — MVP controlado

O modelo atual usa:

* `MERCADO_PAGO_ACCESS_TOKEN`
* `MERCADO_PAGO_DEFAULT_USER_ID`

Esse modelo é aceitável para MVP controlado, testes e validação técnica.

Limitação:

* O token pertence a uma única conta Mercado Pago.
* As vendas são atribuídas a um único usuário TORICO definido em `MERCADO_PAGO_DEFAULT_USER_ID`.
* Não resolve o cenário real de vários comerciantes usando o TORICO ao mesmo tempo.

---

## Modelo recomendado para produção real

Para produção real multi-comerciante, o modelo recomendado é OAuth por comerciante.

Fluxo esperado:

1. Comerciante cria conta no TORICO.
2. Comerciante clica em conectar Mercado Pago.
3. TORICO redireciona para autorização oficial do Mercado Pago.
4. Mercado Pago retorna para o callback do backend.
5. Backend troca o código por tokens.
6. Backend criptografa os tokens.
7. Backend salva a integração no Firestore do usuário.
8. Webhook recebe eventos.
9. Backend identifica a origem da venda.
10. Backend consulta a API oficial do Mercado Pago.
11. Backend grava a venda no Firestore do comerciante correto.
12. Painel TORICO atualiza em tempo real.

---

## Regras de segurança

Regras obrigatórias:

* Nunca salvar Access Token no Flutter/PWA.
* Nunca expor Client Secret no app.
* Nunca colocar tokens reais no GitHub.
* Nunca pedir login/senha do Mercado Pago ao comerciante.
* Usar apenas OAuth, API oficial e webhooks oficiais.
* Criptografar tokens antes de salvar no Firestore.
* Manter `ENABLE_TEST_ENDPOINTS=false` em produção.
* Manter webhook público, mas validado.
* Consultar a API oficial antes de gravar qualquer venda.
* Não confiar diretamente no body do webhook.

---

## Checklist antes de produção real

Antes de liberar produção real, validar:

* [ ] Aplicação Mercado Pago pronta para produção.
* [ ] OAuth Mercado Pago aprovado/liberado para conexão real.
* [ ] Redirect URI de produção configurado.
* [ ] Webhook de produção configurado.
* [ ] Assinatura secreta de produção configurada.
* [ ] Variáveis de produção configuradas no Cloud Run.
* [ ] `ENABLE_TEST_ENDPOINTS=false` no Cloud Run.
* [ ] Tokens sensíveis fora do GitHub.
* [ ] Firestore com regras revisadas.
* [ ] Logs do Cloud Run revisados.
* [ ] Fluxo de conexão do comerciante validado.
* [ ] Fluxo de desconexão do comerciante definido.
* [ ] Renovação de token definida.
* [ ] Tratamento de erro de token expirado definido.
* [ ] Tela do app informando status de conexão.
* [ ] Teste com comerciante real controlado.
* [ ] Checklist financeiro/legal revisado antes de clientes reais.

---

## Próximas etapas técnicas

Próximas etapas sugeridas:

1. Revisar o fluxo OAuth já existente no backend.
2. Ajustar tela do app para conexão real Mercado Pago.
3. Criar estrutura Firestore definitiva para integrações.
4. Implementar busca do token correto por comerciante.
5. Remover dependência de `MERCADO_PAGO_DEFAULT_USER_ID` para produção multiusuário.
6. Criar tela de status da integração.
7. Criar rotina de desconexão.
8. Criar rotina de renovação de token.
9. Preparar primeiro teste com comerciante real controlado.

---

## Decisão atual

Neste momento, o TORICO está tecnicamente validado em sandbox/MVP.

A próxima fase não deve ser apenas trocar credenciais de teste por produção.

A próxima fase correta é preparar o fluxo multiusuário, onde cada comerciante conecta sua própria conta Mercado Pago com autorização oficial.
