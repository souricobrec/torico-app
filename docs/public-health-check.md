# Health check público TORICO

Validação remota em 01/10/2026, antes de deploy deste ajuste: `/` e `/health`
retornaram 200; `/healthz` retornou 404. A rota já existe no fonte da branch
`visual-pre-lojas`, mas ainda não está disponível no serviço consultado.
Testes locais desta correção: 4 cenários aprovados, com sintaxe Node válida.

`GET /healthz` retorna HTTP 200, `Cache-Control: no-store` e somente:

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
com chave. A rota `/` mantém sua resposta e passa a apontar para `/healthz`.
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
curl.exe --fail-with-body --silent --show-error https://torico-backend-yx6k7amjza-uc.a.run.app/healthz
curl.exe --fail-with-body --silent --show-error https://torico-backend-yx6k7amjza-uc.a.run.app/
curl.exe --fail-with-body --silent --show-error https://torico-backend-yx6k7amjza-uc.a.run.app/health
```

Confirmar JSON exato em `/healthz` e `/health` público. Para os detalhes, usar o
header interno por canal seguro. Se `/healthz` continuar 404, verificar se a imagem
e a revisão com este commit foram implantadas, se o tráfego aponta para elas e se
a construção utiliza `backend` como contexto (o Dockerfile executa `server.js`).
Não alterar DNS, OAuth, webhooks, Scheduler ou lógica de vendas para corrigir isso.
