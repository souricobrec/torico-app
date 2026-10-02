# TORICO Backend Simulado

## Domínio oficial e health check

API de produção preparada para `https://api.meutorico.com.br`, mantendo o Cloud Run.
`GET /healthz` retorna `{"ok":true,"service":"torico-backend","status":"healthy"}`;
`GET /health` continua disponível com HTTP 200 e resposta mínima em produção.
Detalhes exigem chave interna; veja [health check público](../docs/public-health-check.md).
`PUBLIC_BACKEND_URL` preserva a configuração por ambiente. O callback Mercado Pago
atual permanece até migração manual de `MERCADO_PAGO_REDIRECT_URI` e cadastro do provedor.
Consultar [roteiro e checklist](../docs/api-domain-migration.md) antes de publicar.

Backend local para preparar o fluxo futuro de webhooks oficiais.

## O que este backend faz agora

- Sobe um servidor local em `http://localhost:3333`
- Testa saúde em `GET /health`
- Simula venda por backend em `POST /simulate-sale`
- Grava a venda em `users/{userId}/sales/{externalId}` no Firestore
- Mantém o mesmo modelo de venda usado pelo app Flutter

## Instalação

Dentro da pasta `backend`:

```bash
npm install
```

Copie o arquivo `.env.example` para `.env`:

```bash
copy .env.example .env
```

Configure no `.env` o caminho da chave de service account do Firebase.

## Rodar

```bash
npm run dev
```

## Testar saúde

Abra no navegador:

```text
http://localhost:3333/health
```

## Simular uma venda

No PowerShell:

```powershell
Invoke-RestMethod `
  -Uri "http://localhost:3333/simulate-sale" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"userId":"COLE_AQUI_O_UID_DO_FIREBASE","amount":49.90,"platform":"Mercado Pago"}'
```

Depois confira no Firestore:

```text
users/{uid}/sales
```

A venda deve aparecer no Painel e no Histórico do TORICO.
