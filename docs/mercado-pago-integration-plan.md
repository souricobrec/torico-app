# TORICO — Plano técnico da integração Mercado Pago

## 1. Objetivo da integração

A integração Mercado Pago do TORICO tem como objetivo permitir que o comerciante acompanhe, dentro do TORICO, as vendas realizadas em sua conta Mercado Pago.

O TORICO não será gateway de pagamento, maquininha, checkout ou intermediador financeiro. O TORICO será um painel de acompanhamento de vendas.

Fluxo desejado:

```text
Comerciante vende pelo Mercado Pago
→ Mercado Pago envia notificação oficial
→ Backend TORICO recebe o evento
→ Backend TORICO valida a venda na API oficial
→ Backend TORICO grava a venda no Firestore
→ App TORICO exibe no Painel e Histórico
```

---

## 2. Regra de segurança obrigatória

O app Flutter/PWA do TORICO nunca deve acessar, salvar ou expor credenciais sensíveis de plataformas externas.

O TORICO nunca deve pedir ou salvar:

```text
login do Mercado Pago
senha do Mercado Pago
código 2FA
credenciais pessoais do comerciante
dados de cartão
tokens dentro do Flutter/PWA
tokens no localStorage
tokens no GitHub
tokens em documentos acessíveis pelo app do usuário
```

Toda integração real deve usar:

```text
autorização oficial/OAuth
API oficial
webhooks oficiais
consentimento claro do comerciante
backend seguro
armazenamento protegido de tokens
```

---

## 3. Arquitetura recomendada

```text
App TORICO Flutter/PWA
        ↓
Backend TORICO
        ↓
Mercado Pago OAuth/API/Webhook
        ↓
Firestore
        ↓
App TORICO lê vendas em tempo real
```

O Flutter/PWA deve apenas:

```text
exibir status da integração
abrir o fluxo de conexão
disparar solicitação de desconexão
ler vendas autorizadas no Firestore
mostrar Painel e Histórico
```

O backend deve:

```text
iniciar OAuth
receber callback OAuth
salvar tokens de forma segura
receber webhooks
validar eventos
consultar API oficial
identificar o usuário TORICO dono da integração
evitar duplicidade
gravar venda real no Firestore
```

---

## 4. Fluxo de conexão OAuth

### 4.1. Tela do app

Na área de Conta/Integrações, o app deverá exibir:

```text
Mercado Pago
Status: Não conectado
Botão: Conectar Mercado Pago
```

Ao clicar, o app chama o backend:

```text
GET /integrations/mercado-pago/connect
```

O backend gera a URL oficial de autorização e redireciona o comerciante para o Mercado Pago.

### 4.2. Autorização

O comerciante autoriza o TORICO na página oficial do Mercado Pago.

Depois da autorização, o Mercado Pago redireciona para o backend:

```text
GET /integrations/mercado-pago/callback?code=...&state=...
```

O backend usa o `code` para obter tokens pela API oficial.

### 4.3. Proteção contra conexão indevida

O parâmetro `state` deve ser usado para associar a tentativa de conexão ao usuário TORICO correto e reduzir risco de CSRF.

Exemplo de estado temporário:

```text
oauth_states/{stateId}
  userId
  platform: mercado_pago
  createdAt
  expiresAt
  used: false
```

Após o callback, o backend valida o `state`, marca como usado e continua o fluxo.

---

## 5. Estrutura segura para integração

Os tokens não devem ficar em `users/{uid}` se esse caminho puder ser lido pelo app.

Sugestão de coleção protegida, acessada apenas pelo backend/Admin SDK:

```text
private_integrations/{integrationId}
  userId: uid_do_torico
  platform: mercado_pago
  platformUserId: id_da_conta_mp
  accessTokenEncrypted: ...
  refreshTokenEncrypted: ...
  expiresAt: ...
  scopes: [...]
  status: connected
  createdAt: ...
  updatedAt: ...
```

Documento público, sem dados sensíveis, para o app exibir status:

```text
users/{uid}/integrations/mercado_pago
  platform: Mercado Pago
  platformId: mercado_pago
  status: connected
  connectedAt: ...
  lastSyncAt: ...
```

---

## 6. Fluxo de webhook

Endpoint público do backend:

```text
POST /webhooks/mercado-pago
```

Fluxo esperado:

```text
Mercado Pago envia evento
→ Backend recebe webhook
→ Backend valida assinatura/origem quando aplicável
→ Backend identifica o tipo de evento
→ Backend busca o pagamento na API oficial
→ Backend valida status, valor, data e conta vendedora
→ Backend identifica o usuário TORICO
→ Backend grava venda no Firestore
```

O webhook não deve ser considerado a venda final sem validação. Ele deve ser tratado como aviso de evento.

---

## 7. Validação da venda

Antes de gravar no Firestore, o backend deve confirmar:

```text
o pagamento existe
o pagamento pertence à conta Mercado Pago autorizada
o status é relevante para o TORICO, por exemplo approved
o valor está correto
o ID externo ainda não foi gravado para aquele usuário
a data da venda foi calculada corretamente no fuso America/Sao_Paulo
```

---

## 8. Gravação no Firestore

A venda real deve ser gravada no mesmo padrão já preparado pelo TORICO:

```text
users/{uid}/sales/{externalId}
```

Campos recomendados:

```text
amount
platform: Mercado Pago
platformId: mercado_pago
status: approved
source: webhook
externalId: id_do_pagamento_mp
rawPayload
dateKey
createdAtClient
createdAtServer
```

O `externalId` deve ser baseado no ID do pagamento/evento externo para evitar duplicidade.

Exemplo:

```text
users/{uid}/sales/mp_payment_123456789
```

Se o Mercado Pago enviar o mesmo evento mais de uma vez, o backend deve atualizar/ignorar a venda existente, não criar venda duplicada.

---

## 9. App Flutter/PWA

O app não precisa conversar diretamente com a API privada do Mercado Pago.

Ele continua lendo:

```text
users/{uid}/sales
```

O Painel e o Histórico funcionam com vendas de qualquer origem:

```text
source: simulator
source: webhook_simulator
source: webhook
```

A tela Conta/Integrações deve exibir status baseado em:

```text
users/{uid}/integrations/mercado_pago
```

sem expor tokens.

---

## 10. Desconexão Mercado Pago

Endpoint futuro:

```text
POST /integrations/mercado-pago/disconnect
```

O backend deve:

```text
validar usuário autenticado
localizar integração privada
revogar/inutilizar credenciais conforme recurso disponível
marcar status como disconnected
atualizar users/{uid}/integrations/mercado_pago
não apagar histórico de vendas antigas
```

As vendas antigas devem permanecer no histórico do TORICO.

---

## 11. Endpoints futuros

```text
GET  /health
GET  /test-client
POST /simulate-sale
GET  /integrations/mercado-pago/connect
GET  /integrations/mercado-pago/callback
POST /integrations/mercado-pago/disconnect
POST /webhooks/mercado-pago
```

`/test-client` e `/simulate-sale` permanecem úteis para teste local, mas não representam venda real.

---

## 12. Variáveis de ambiente futuras

Exemplo:

```env
PORT=3333
FIREBASE_SERVICE_ACCOUNT_PATH=...
FIREBASE_PROJECT_ID=...
MERCADO_PAGO_CLIENT_ID=...
MERCADO_PAGO_CLIENT_SECRET=...
MERCADO_PAGO_REDIRECT_URI=...
MERCADO_PAGO_WEBHOOK_SECRET=...
TOKEN_ENCRYPTION_KEY=...
APP_BASE_URL=...
BACKEND_BASE_URL=...
```

Nenhuma variável sensível deve ser enviada ao GitHub.

---

## 13. Backend público

Para OAuth e webhooks reais, o backend precisará de URL pública HTTPS.

Opções possíveis:

```text
Firebase Functions
Google Cloud Run
Render
Railway
Vercel Functions
```

A escolha deve considerar:

```text
segurança de variáveis de ambiente
suporte a Node.js
logs
facilidade de deploy
custo
integração com Firebase
URL HTTPS pública
```

---

## 14. Checklist antes de produção

Antes de vender para clientes reais, o TORICO precisa ter:

```text
Termos de Uso
Política de Privacidade
Tela clara de consentimento da integração
Botão de desconectar integração
Backend publicado em HTTPS
Tokens protegidos
Regras Firestore revisadas
Webhook validando assinatura/origem
Logs de erro seguros
Tratamento de duplicidade
Teste com conta Mercado Pago de desenvolvimento
Teste com venda real controlada
```

---

## 15. Referências oficiais para consulta

- Documentação Mercado Pago — OAuth
- Documentação Mercado Pago — Obter Access Token
- Documentação Mercado Pago — Renovar Access Token
- Documentação Mercado Pago — Credenciais
- Documentação Mercado Pago — Webhooks
- Documentação Mercado Pago — Notificações de pagamento
- Documentação Mercado Pago — Boas práticas de segurança de credenciais

---

## 16. Decisão técnica do TORICO

A decisão oficial para o projeto é:

```text
Receber → validar → gravar → exibir
```

E não:

```text
Receber → exibir diretamente
```

Essa arquitetura protege o comerciante, protege o TORICO e prepara o produto para múltiplas plataformas no futuro.


