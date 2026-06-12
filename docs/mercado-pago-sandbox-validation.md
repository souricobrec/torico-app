# Validação da integração Mercado Pago Sandbox — TORICO

## Resumo

Este documento registra a validação da integração do TORICO com o Mercado Pago em ambiente sandbox.

A integração foi validada com sucesso usando o fluxo:

```txt
TORICO PWA
→ Backend Cloud Run
→ Mercado Pago Checkout Pro Sandbox
→ Webhook Mercado Pago
→ Cloud Run
→ Firestore
→ Painel TORICO
```

O teste aprovado foi realizado usando **saldo em conta** do **Buyer Test User**.

O teste com **cartão de crédito sandbox** ainda ficará como validação pendente.

---

## Ambiente

### App TORICO

```txt
Firebase Hosting:
https://torico-ca479.web.app
```

### Backend Cloud Run

```txt
Serviço:
torico-backend

Região:
us-central1

URL:
https://torico-backend-16783123127.us-central1.run.app
```

### Projeto Firebase

```txt
Project ID:
torico-ca479

Número do projeto:
16783123127
```

---

## Rotas principais utilizadas

```txt
GET  /health
POST /mercado-pago/create-test-preference
POST /webhooks/mercado-pago
```

---

## Variáveis importantes do backend

As variáveis reais ficam somente no `.env` local e no Cloud Run.

Não enviar valores reais para o GitHub.

```env
FIREBASE_PROJECT_ID=torico-ca479

TORICO_DEV_KEY=
TOKEN_ENCRYPTION_KEY=

MERCADO_PAGO_CLIENT_ID=
MERCADO_PAGO_CLIENT_SECRET=
MERCADO_PAGO_REDIRECT_URI=
MERCADO_PAGO_WEBHOOK_SECRET=

MERCADO_PAGO_ACCESS_TOKEN=
MERCADO_PAGO_DEFAULT_USER_ID=

PUBLIC_BACKEND_URL=https://torico-backend-16783123127.us-central1.run.app
PUBLIC_APP_URL=https://torico-ca479.web.app
```

---

## Estado validado do /health

O endpoint `/health` retornou corretamente:

```json
{
  "ok": true,
  "app": "TORICO Backend",
  "mode": "simulado",
  "environment": "production",
  "projectId": "torico-ca479",
  "protectedSimulation": true,
  "mercadoPago": {
    "oauthConfigured": true,
    "webhookSignatureConfigured": true,
    "tokenEncryptionConfigured": true,
    "accessTokenConfigured": true,
    "defaultUserIdConfigured": true,
    "mvpConfigured": true
  }
}
```

---

## Contas de teste Mercado Pago

A documentação atual do Mercado Pago orienta usar contas de teste separadas para vendedor e comprador.

### Seller Test User

Usado como vendedor, ou seja, a conta que cria/recebe a cobrança.

```txt
Tipo:
Vendedor

Função:
Criar/receber cobrança
```

### Buyer Test User

Usado como comprador, ou seja, a conta usada para pagar no checkout sandbox.

```txt
Tipo:
Comprador

Função:
Pagar a cobrança no sandbox
```

---

## Regra validada

```txt
Seller Test User = vendedor
Buyer Test User  = comprador
```

Não usar:

```txt
Conta real Mercado Pago
Conta principal do Mercado Pago Developers
Seller Test User para pagar
Buyer Test User como vendedor
```

---

## Criação de preferência

A preferência foi criada pelo backend Cloud Run usando a rota protegida:

```txt
POST /mercado-pago/create-test-preference
```

A rota usa o header:

```txt
x-torico-dev-key
```

Exemplo de comando PowerShell:

```powershell
cd C:\vendaon

$headers = @{
  "Content-Type" = "application/json"
  "x-torico-dev-key" = "SUA_TORICO_DEV_KEY"
}

$body = @{
  title = "Venda teste TORICO"
  amount = 10
  quantity = 1
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "https://torico-backend-16783123127.us-central1.run.app/mercado-pago/create-test-preference" `
  -Method POST `
  -Headers $headers `
  -Body $body

$response.preference | Format-List *
```

Resultado esperado:

```txt
id
externalReference
title
amount
quantity
initPoint
sandboxInitPoint
notificationUrl
```

Para teste sandbox, usar somente:

```txt
sandboxInitPoint
```

Não usar:

```txt
initPoint
```

---

## Webhook Mercado Pago

Webhook configurado no Mercado Pago Developers:

```txt
https://torico-backend-16783123127.us-central1.run.app/webhooks/mercado-pago
```

Eventos marcados:

```txt
Pagamentos
Pedidos comerciais
```

A assinatura secreta do webhook em modo teste foi configurada no Cloud Run como:

```env
MERCADO_PAGO_WEBHOOK_SECRET=
```

---

## Problema encontrado

Durante os testes, o Mercado Pago enviou notificações em mais de um formato.

### Formato moderno

```txt
/webhooks/mercado-pago?data.id=123456&type=payment
```

Esse formato valida a assinatura usando:

```txt
x-signature
x-request-id
data.id
```

### Formato merchant_order legado

```txt
/webhooks/mercado-pago?id=41784082888&topic=merchant_order
```

### Formato merchant_order com data.id

```txt
/webhooks/mercado-pago?data.id=41784082888&type=topic_merchant_order_wh
```

Inicialmente, o backend recusava alguns eventos com:

```txt
POST 401
Webhook Mercado Pago com assinatura inválida
```

---

## Correção aplicada no server.js

O backend foi ajustado para tratar eventos `merchant_order` em formatos diferentes.

A regra aplicada foi:

```txt
Se for webhook moderno com assinatura válida:
  processar normalmente.

Se for merchant_order em formato legado ou data.id/topic_merchant_order_wh:
  não confiar no body recebido.
  usar apenas o ID recebido.
  consultar a API oficial do Mercado Pago.
  processar somente se o pagamento consultado estiver approved.
```

Isso permitiu que o Cloud Run retornasse `200` ou `201` para eventos reais de `merchant_order`.

---

## Logs de sucesso

Após a correção, os logs passaram a mostrar:

```txt
Webhook Mercado Pago merchant_order em formato legado/data.id recebido sem assinatura moderna válida.
O backend seguirá consultando a API oficial antes de processar.

Webhook Mercado Pago recebido:
eventType: merchant_order
legacyMerchantOrderNotification: true
```

Também foi observado retorno:

```txt
POST 201 /webhooks/mercado-pago?data.id=...&type=topic_merchant_order_wh
```

---

## Venda gravada no Firestore

A venda foi gravada com sucesso em:

```txt
users/{MERCADO_PAGO_DEFAULT_USER_ID}/sales
```

Documento criado:

```txt
mercado_pago_payment_162904334721
```

Campos principais validados:

```txt
amount: 10
dateKey: "2026-06-11"
externalId: "mercado_pago_payment_162904334721"
platform: "Mercado Pago"
platformId: "mercado_pago"
```

Também foi gravado o payload bruto em:

```txt
rawPayload
```

Incluindo dados de:

```txt
merchantOrder
payment
webhook
```

---

## Painel TORICO

O app TORICO atualizou corretamente o painel com:

```txt
Vendido hoje: R$ 10,00
Fonte: Mercado Pago
```

Isso confirmou o fluxo completo:

```txt
Pagamento sandbox aprovado
→ Webhook recebido
→ Backend processou
→ Firestore gravou
→ App atualizou em tempo real
```

---

## Status da validação

### Validado com sucesso

```txt
Criação de preferência Mercado Pago pelo Cloud Run
Uso do sandboxInitPoint
Login com Buyer Test User
Pagamento via saldo em conta
Recebimento de webhook merchant_order
Consulta do pedido/pagamento na API Mercado Pago
Gravação da venda no Firestore
Atualização do Painel TORICO
```

### Pendente

```txt
Teste específico com cartão de crédito sandbox
Ajuste final para produção real
OAuth multiusuário Mercado Pago
Separação de múltiplos comerciantes reais
Tratamento definitivo para produção
```

---

## Observação sobre cartão de crédito sandbox

O teste com saldo em conta confirmou que a integração principal está funcionando.

O teste com cartão de crédito sandbox ainda deve ser feito separadamente usando:

```txt
Buyer Test User
Cartão manual
Nome: APRO
CPF: 12345678909
```

Cartão de teste sugerido pela documentação Mercado Pago:

```txt
Mastercard
Número: 5031 4332 1540 6351
Validade: 11/30
CVV: 123
Nome: APRO
CPF: 12345678909
```

---

## Conclusão

A integração Mercado Pago sandbox do TORICO foi validada com sucesso para o MVP usando pagamento via saldo em conta.

O fluxo validado é suficiente para confirmar que:

```txt
O backend cria preferências.
O checkout sandbox abre corretamente.
O Mercado Pago envia webhook.
O Cloud Run recebe e processa o merchant_order.
O backend consulta a API oficial do Mercado Pago.
A venda aprovada é gravada no Firestore.
O app TORICO exibe o valor vendido hoje em tempo real.
```

Status final:

```txt
MVP Mercado Pago Sandbox: VALIDADO
Cartão de crédito sandbox: PENDENTE
Produção real: PENDENTE
```
