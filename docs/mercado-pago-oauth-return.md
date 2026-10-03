# Retorno ao TORICO após OAuth Mercado Pago

O callback bem-sucedido continua validando o state, trocando o code, criptografando tokens e gravando `users/{UID}/integrations/mercado_pago`. O mesmo batch publica apenas `platform`, `platformId`, `status` e `updatedAt` em `users/{UID}/integration_status/mercado_pago`, caminho já permitido pelas regras ao próprio usuário. Não publica tokens nem muda regras.

Depois da gravação, mantém o log `Integracao Mercado Pago conectada:` e responde página de sucesso com botão **Voltar ao TORICO** e meta refresh de dois segundos para:

`https://app.meutorico.com.br/?integration=mercado_pago&status=connected`

Erros mantêm seus códigos HTTP e oferecem botão para o mesmo host com `status=error`. O destino é fixo: não aceita return URLs fornecidas pelo solicitante. Respostas do callback têm `Cache-Control: no-store`.

O app captura o retorno e remove somente `integration`/`status` pela History API, preservando outros parâmetros e fragmento. A allowlist e a autenticação continuam obrigatórias. Quando autorizado, abre a verificação Mercado Pago automaticamente; somente o status persistido permite mostrar a tela conectada e **Entrar no Painel**. URL `status=connected` não é prova de integração. Falhas/ausência de status continuam pendentes, com botão manual **Verificar conexão**.

A aba original também verifica ao voltar para o estado resumed após abrir OAuth externamente. A abertura continua em navegador externo/nova aba. Nenhuma comunicação entre janelas transmite credenciais.

## Validação e publicação futura

- `flutter analyze`, `flutter test`, `node --test backend/test/*.test.js` e build web release.
- Os testes usam mocks locais; não executam login, OAuth ou gravações reais.
- Publicar backend e Hosting em missão posterior, preservando configurações/secrets do Cloud Run. Nenhum deploy foi realizado nesta branch.
- Depois, executar OAuth manualmente, confirmar retorno automático, status conectado e entrada no painel.
- Se a sessão não estiver disponível no navegador externo, autenticar no TORICO normalmente; a URL não autoriza usuário.
- **Integrações antigas** gravadas antes desta mudança não ganham `integration_status` retroativamente. Sem esse documento, será necessário novo OAuth após o deploy ou uma migração controlada separada. Não foi feito backfill nem alteração de dados existentes.
- Conferir pré-lançamento do domínio técnico em navegador sem preferência piloto; `?pilot=1` segue disponível aos autorizados.

Callback URL, client OAuth, webhook, criptografia, UID, vendas e REDE/Scheduler preservados. Pendências de segurança anteriores continuam: validar Firebase ID token no início OAuth, impedir vínculo múltiplo da mesma conta Mercado Pago e consumir nonce/state uma única vez antes da divulgação pública.
