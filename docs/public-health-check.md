# Health check público TORICO

O endpoint público oficial é `/health`. `/healthz` permanece no código apenas
como alias opcional; sua disponibilidade não é requisito operacional.

`GET /health` sem autorização interna retorna HTTP 200 em produção,
`Cache-Control: no-store` e somente:

```json
{"ok":true,"service":"torico-backend","status":"healthy"}
```

`GET /health` permanece HTTP 200. Em produção, ambiente não definido ou Cloud Run
(`K_SERVICE` presente), retorna o mesmo JSON mínimo. O contrato detalhado anterior
fica disponível com o header `x-health-key` correspondente a `HEALTH_DETAILS_KEY`
no backend. Sem chave configurada, detalhes permanecem bloqueados. Nunca enviar
essa chave no app, query string, Firestore público, logs ou repositório. Para habilitar
diagnóstico interno, criar segredo no Secret Manager e referenciá-lo na variável
de ambiente em uma mudança operacional separada. Não reutilizar chaves dos adquirentes.

Somente ambiente local explicitamente `NODE_ENV=development` ou `test`, sem
`K_SERVICE`, permite detalhes sem chave. `/healthz` é sempre mínimo, inclusive
com chave. A rota `/` mantém sua resposta e aponta para `/health`.
Liveness não consulta Firestore ou adquirentes e não certifica saúde das integrações.

## Validação local

Executar sem `backend/.env`, evitando carregar configurações reais:

```powershell
cd backend
node --check server.js
node --test test/healthz.test.js
```

## Validação após deploy manual

```powershell
curl.exe --fail-with-body --silent --show-error https://torico-backend-16783123127.us-central1.run.app/
curl.exe --fail-with-body --silent --show-error https://torico-backend-16783123127.us-central1.run.app/health
```

Confirmar `"health":"/health"` na raiz e JSON exato em `/health` público.
Para os detalhes, usar o header interno por canal seguro.
Não alterar DNS, OAuth, webhooks, Scheduler ou lógica de vendas para corrigir isso.
