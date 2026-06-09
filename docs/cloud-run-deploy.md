# TORICO — Deploy do Backend no Google Cloud Run

Este documento registra o deploy do backend real/simulado do TORICO no Google Cloud Run.

## 1. Objetivo

Publicar o backend Node/Express do TORICO em uma URL pública HTTPS para preparar o projeto para integrações reais com plataformas externas, começando pelo Mercado Pago.

O backend publicado no Cloud Run será responsável por:

- receber chamadas externas e futuros webhooks;
- validar dados no backend;
- gravar vendas no Firestore usando Firebase Admin SDK;
- manter credenciais sensíveis fora do Flutter/PWA;
- servir como base para a integração real com Mercado Pago.

## 2. Arquitetura atual

```text
Flutter/PWA TORICO na Vercel
        ↓
Backend Node/Express no Google Cloud Run
        ↓
Firebase Admin SDK
        ↓
Cloud Firestore
        ↓
App TORICO lê vendas em tempo real
```

Fluxo validado em teste:

```text
/test-client no Cloud Run
→ POST /simulate-sale
→ Firestore users/{uid}/sales
→ App TORICO atualiza Painel e Histórico
```

## 3. Projeto Google Cloud

```text
Nome do projeto: TORICO
Project ID: torico-ca479
Número do projeto: 16783123127
```

## 4. Serviço Cloud Run

```text
Nome do serviço: torico-backend
Região: us-central1
URL pública: https://torico-backend-16783123127.us-central1.run.app
```

## 5. Rotas atuais do backend

```text
GET  /health
GET  /test-client
POST /simulate-sale
POST /webhooks/mercado-pago
```

### `/health`

Usada para verificar se o backend está online.

URL de teste:

```text
https://torico-backend-16783123127.us-central1.run.app/health
```

Resposta esperada:

```json
{
  "ok": true,
  "app": "TORICO Backend",
  "mode": "simulado"
}
```

### `/test-client`

Tela temporária de desenvolvimento para simular vendas pela nuvem.

URL:

```text
https://torico-backend-16783123127.us-central1.run.app/test-client
```

Esta tela permite informar:

- UID do usuário Firebase;
- valor da venda;
- plataforma: Mercado Pago, Stone ou PagBank.

Ela chama `/simulate-sale` e grava a venda no Firestore.

### `/simulate-sale`

Endpoint usado apenas para simulação técnica do fluxo futuro de webhook.

Exemplo de payload:

```json
{
  "userId": "UID_DO_USUARIO_FIREBASE",
  "amount": 49.9,
  "platform": "Mercado Pago"
}
```

Grava em:

```text
users/{uid}/sales/{externalId}
```

Com campos como:

```text
amount
platform
platformId
status
source
externalId
rawPayload
dateKey
createdAtClient
createdAtServer
```

### `/webhooks/mercado-pago`

Endpoint estrutural para futura integração real com Mercado Pago.

No futuro, este endpoint deverá:

1. Receber notificação oficial do Mercado Pago.
2. Validar assinatura/origem conforme documentação oficial.
3. Buscar o pagamento na API oficial do Mercado Pago.
4. Identificar qual usuário TORICO autorizou aquela conta.
5. Evitar duplicidade usando o ID externo do pagamento.
6. Gravar a venda real no Firestore.

## 6. Deploy realizado

O deploy foi feito via Google Cloud Shell, sem Docker instalado localmente no Windows.

Comandos usados:

```bash
gcloud config set project torico-ca479

git clone https://github.com/souricobrec/torico-app.git

cd torico-app/backend

gcloud run deploy torico-backend \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --min-instances 0 \
  --max-instances 3 \
  --memory 512Mi \
  --cpu 1
```

Durante o primeiro deploy, o Google Cloud solicitou a criação de um repositório no Artifact Registry chamado:

```text
cloud-run-source-deploy
```

Essa criação foi autorizada.

## 7. Configuração de escala e custo

Configuração inicial:

```text
Mínimo de instâncias: 0
Máximo de instâncias: 3
Memória: 512Mi
CPU: 1
Faturamento: baseado em solicitações
Entrada: pública
```

Motivo:

- `min-instances 0` reduz custo quando não há uso.
- `max-instances 3` evita escala excessiva em caso de chamadas inesperadas.
- acesso público é necessário para `/health`, `/test-client` e futuros webhooks oficiais.

## 8. Orçamento e alertas

Foi criado um orçamento inicial no Google Cloud:

```text
Nome: TORICO - Alerta inicial
Valor: R$ 20,00
Alertas: 50%, 80% e 100%
```

Alertas equivalentes:

```text
50% → R$ 10
80% → R$ 16
100% → R$ 20
```

Esse orçamento não bloqueia automaticamente o consumo, mas envia alertas por e-mail para evitar surpresas.

## 9. Segurança

Em produção no Cloud Run, o backend não usa `firebase-service-account.json` dentro do container.

A regra é:

```text
Ambiente local:
usa FIREBASE_SERVICE_ACCOUNT_PATH apontando para firebase-service-account.json

Ambiente Cloud Run:
usa credenciais padrão do ambiente Google Cloud / Service Account do Cloud Run
```

Arquivos que nunca devem ir para o GitHub:

```text
backend/.env
backend/firebase-service-account.json
backend/node_modules/
```

Esses arquivos estão protegidos pelo `.gitignore`.

## 10. Regras de integração real

O TORICO nunca deve:

- pedir login ou senha do Mercado Pago, Stone ou PagBank;
- pedir código 2FA;
- armazenar dados de cartão;
- expor tokens OAuth no Flutter/PWA;
- salvar tokens no localStorage;
- salvar tokens em coleção acessível diretamente pelo app;
- publicar tokens ou chaves no GitHub.

Integrações reais devem usar:

```text
OAuth oficial
APIs oficiais
Webhooks oficiais
Consentimento explícito do comerciante
Tokens protegidos apenas no backend
```

## 11. Status atual

Validado com sucesso:

```text
Cloud Run público
→ Backend TORICO
→ Firebase Admin SDK
→ Firestore
→ App Flutter/PWA
→ Painel e Histórico atualizados
```

O backend publicado já está pronto para servir como base técnica do webhook real do Mercado Pago.

## 12. Próximas etapas

1. Criar tela/fluxo real de integração Mercado Pago no app.
2. Criar endpoints OAuth no backend:

```text
GET  /integrations/mercado-pago/connect
GET  /integrations/mercado-pago/callback
POST /integrations/mercado-pago/disconnect
```

3. Criar armazenamento seguro da integração no backend.
4. Implementar validação real de webhook Mercado Pago.
5. Gravar vendas reais com `source: webhook`.
6. Remover ou proteger a tela `/test-client` antes de produção pública com clientes reais.
