# Segurança das Integrações do TORICO

Este documento registra a regra oficial de segurança para integrações reais do TORICO com plataformas externas, como Mercado Pago, Stone, PagBank e outras futuras integrações.

## Princípio principal

O TORICO deve usar apenas meios oficiais, autorizados e seguros para acessar informações de vendas de plataformas externas.

Fluxo aprovado:

```text
Plataforma externa
→ autorização oficial / OAuth
→ backend TORICO
→ webhook oficial
→ validação via API oficial
→ gravação segura da venda
→ app Flutter/PWA apenas exibe os dados
```

O app Flutter/PWA nunca deve receber, salvar ou expor credenciais sensíveis.

## O que o TORICO nunca deve pedir ou salvar

O TORICO nunca deve pedir, salvar ou manipular diretamente:

```text
login da plataforma externa
senha da plataforma externa
código 2FA
códigos de segurança
cookies de sessão
dados de cartão
tokens dentro do Flutter/PWA
tokens no localStorage
tokens no GitHub
tokens em Firestore acessível pelo usuário
```

O usuário deve autorizar a integração sempre pelo fluxo oficial da própria plataforma.

## Onde ficam os dados sensíveis da integração

Quando uma integração real exigir OAuth ou credenciais técnicas, os dados devem ficar somente no backend do TORICO, protegidos e fora do alcance do app Flutter/PWA.

Exemplos de dados técnicos que podem existir no backend:

```text
access_token criptografado
refresh_token criptografado
platformUserId
expiresAt
scopes
status da conexão
createdAt
updatedAt
```

Esses dados não devem ser expostos ao usuário final nem enviados para o app.

## Papel do Flutter/PWA

O app Flutter/PWA deve ser responsável apenas por:

```text
exibir total vendido hoje
exibir histórico de vendas
exibir status da integração
solicitar início de conexão
solicitar desconexão
exibir mensagens claras ao usuário
```

O Flutter/PWA não deve chamar APIs privadas das plataformas de pagamento usando tokens sensíveis.

## Papel do backend TORICO

O backend TORICO deve ser responsável por:

```text
iniciar o fluxo oficial de autorização
receber callback OAuth
proteger tokens
receber webhooks oficiais
validar eventos recebidos
consultar a API oficial da plataforma
identificar o usuário TORICO dono da venda
evitar duplicidade de vendas
gravar a venda no Firestore
registrar logs técnicos sem expor segredos
```

## Webhooks

Toda venda real deve entrar no TORICO por webhook oficial ou consulta oficial autorizada.

Fluxo esperado:

```text
1. Plataforma envia webhook para o backend TORICO.
2. Backend valida a origem/evento conforme documentação oficial da plataforma.
3. Backend consulta a API oficial usando token seguro.
4. Backend confirma valor, status e identidade da venda.
5. Backend verifica se a venda já foi registrada.
6. Backend grava em users/{uid}/sales.
7. App TORICO lê o Firestore e atualiza o Painel/Histórico.
```

## Estrutura de venda real

As vendas reais devem seguir a mesma estrutura preparada no Firestore:

```text
users/{userId}/sales/{saleId}
```

Campos esperados:

```text
amount
platform
platformId
externalId
status
source
rawPayload
dateKey
createdAtClient
createdAtServer
```

Para vendas reais vindas de webhook, usar:

```text
source: webhook
```

Para vendas geradas pelo backend de teste local, usar:

```text
source: webhook_simulator
```

Para vendas simuladas pelo app Flutter, usar:

```text
source: simulator
```

Observação: o uso de `source: simulator` representa o comportamento antigo de desenvolvimento. A criação manual de vendas pelo app foi removida da interface do usuário final.

## Dados salvos no Firestore

O Firestore pode guardar dados necessários para o funcionamento do produto, como:

```text
vendas
plano do usuário
status público da integração
plataformas conectadas/desconectadas
dados não sensíveis necessários para exibição
```

O Firestore acessível pelo app não deve guardar tokens OAuth, refresh tokens, chaves privadas ou segredos de plataforma.

## Consentimento do comerciante

Antes de conectar uma plataforma real, o TORICO deve deixar claro:

```text
qual plataforma será conectada
quais dados serão acessados
para qual finalidade os dados serão usados
que o usuário pode desconectar a integração
que o TORICO não terá acesso à senha da plataforma
```

## Desconexão

O TORICO deve prever uma forma de desconectar a integração.

Ao desconectar, o backend deve:

```text
marcar a integração como desconectada
parar de processar novos webhooks para aquela conta
revogar tokens quando a plataforma permitir
não apagar automaticamente o histórico de vendas, salvo decisão de produto ou solicitação válida do usuário
```

## Regra para desenvolvimento

Antes de qualquer nova integração real, deve ser validado:

```text
documentação oficial da plataforma
fluxo OAuth ou autorização equivalente
como configurar webhooks
como validar eventos
como consultar pagamento/venda na API
como proteger tokens
como evitar duplicidade
como desconectar a integração
```

## Proteção do endpoint de simulação

O endpoint de simulação de vendas do backend deve ser usado apenas para desenvolvimento e testes técnicos.

Endpoint protegido:

```text
POST /simulate-sale
```

Esse endpoint exige o header:

```text
x-torico-dev-key
```

A chave de desenvolvimento é configurada no backend por meio da variável de ambiente:

```text
TORICO_DEV_KEY
```

Essa chave nunca deve ser exposta no app Flutter/PWA, no GitHub, no Firestore acessível pelo usuário, em prints compartilhados ou em qualquer outro local público.

A chave deve existir apenas em ambientes controlados, como:

```text
arquivo .env local do backend
variáveis de ambiente do Cloud Run
ambientes seguros de desenvolvimento
```

## Rotação da TORICO_DEV_KEY

Após a publicação do backend no Google Cloud Run, o endpoint `/simulate-sale` foi protegido com o header `x-torico-dev-key`.

Como a chave anterior apareceu em imagem durante os testes, foi realizada uma nova rotação da variável:

```text
TORICO_DEV_KEY
```

### Validação realizada

Foram executados os seguintes testes:

```text
tentativa de registrar venda simulada usando a chave antiga
tentativa de registrar venda simulada usando a nova chave
validação do endpoint /health
validação do endpoint /test-client
```

### Resultado

A chave antiga foi negada corretamente pelo backend.

A nova chave foi aceita e autorizou o registro de uma nova venda simulada no Cloud Firestore.

O app TORICO atualizou corretamente o Painel e o Histórico com a venda criada pelo backend publicado no Google Cloud Run.

O endpoint `/health` confirmou que a simulação protegida estava ativa por meio do campo:

```text
protectedSimulation: true
```

### Status

A proteção básica do endpoint `/simulate-sale` foi validada com sucesso.

O endpoint de simulação permanece restrito ao uso de desenvolvimento e testes técnicos.

## Remoção da simulação manual no app

Após a validação do backend publicado no Google Cloud Run, o botão **Nova venda** foi removido da interface principal do app TORICO.

A decisão foi tomada para evitar que o usuário final tenha a impressão de que as vendas devem ser lançadas manualmente dentro do app.

O objetivo do TORICO é acompanhar vendas em tempo real a partir de integrações oficiais com plataformas externas, como Mercado Pago, Stone, PagBank e outras.

## Decisão de produto

A tela **Painel** não deve permitir criação manual de vendas pelo usuário final.

As vendas devem entrar no app por meio de:

```text
integrações oficiais
APIs autorizadas
webhooks oficiais
backend seguro publicado no Google Cloud Run
```

## Simulação de vendas

A simulação de vendas permanece disponível apenas para desenvolvimento e testes técnicos, por meio do backend e do endpoint protegido:

```text
POST /simulate-sale
```

Esse endpoint exige o header:

```text
x-torico-dev-key
```

A chave usada para testes fica na variável de ambiente:

```text
TORICO_DEV_KEY
```

Essa chave nunca deve ser exposta no app Flutter/PWA, no GitHub, no Firestore público ou em prints compartilhados.

## Validação da remoção do botão Nova venda

Após a remoção do botão **Nova venda**, foi realizado teste criando uma venda pelo backend.

Resultado:

```text
o botão não aparece mais no Painel
a venda simulada pelo backend foi registrada no Cloud Firestore
o app atualizou automaticamente o total vendido hoje
a chuva de moedas funcionou
o som de caixa funcionou
o fluxo visual do Painel permaneceu correto
```

## Status da simulação manual

A simulação manual foi removida da interface do usuário final.

O TORICO passa a reforçar o comportamento esperado de um app de acompanhamento automático de vendas em tempo real.

A simulação técnica continua existindo somente no backend, protegida pela `TORICO_DEV_KEY`.

## Regra final

O TORICO deve operar como um SaaS seguro e profissional.

A regra permanente é:

```text
Receber autorização oficial.
Validar no backend.
Guardar segredos somente no backend.
Gravar vendas de forma segura.
Exibir no app apenas o necessário.
Nunca pedir senha, 2FA ou credenciais pessoais das plataformas.
```
---

## Proteção de rotas de teste em produção

O backend do TORICO possui rotas criadas apenas para validação, sandbox e desenvolvimento. Essas rotas não devem ficar disponíveis em produção real.

Para controlar esse comportamento, foi criada a variável de ambiente:

ENABLE_TEST_ENDPOINTS=false

Quando ENABLE_TEST_ENDPOINTS=false, as rotas de teste ficam bloqueadas:

/test-client
/simulate-sale
/mercado-pago/create-test-preference

A rota raiz / também deixa de redirecionar para /test-client e passa a retornar apenas uma resposta segura informando que o backend está ativo.

As rotas que continuam ativas em produção são:

/health
/webhooks/mercado-pago

A rota /health é usada para validação operacional do backend.

A rota /webhooks/mercado-pago precisa continuar pública, pois é o endpoint que recebe os eventos oficiais do Mercado Pago. Mesmo sendo pública, ela não confia diretamente no conteúdo recebido. O backend valida assinatura quando disponível e consulta a API oficial do Mercado Pago antes de gravar qualquer venda no Firestore.

Mesmo quando ENABLE_TEST_ENDPOINTS=true, as rotas sensíveis de teste continuam protegidas por x-torico-dev-key, quando aplicável.

Comportamento esperado:

ENABLE_TEST_ENDPOINTS=false

* /test-client bloqueado
* /simulate-sale bloqueado
* /mercado-pago/create-test-preference bloqueado
* /health liberado
* /webhooks/mercado-pago liberado

ENABLE_TEST_ENDPOINTS=true

* /test-client liberado
* /simulate-sale liberado com x-torico-dev-key
* /mercado-pago/create-test-preference liberado com x-torico-dev-key

Em Cloud Run, a configuração segura para produção é:

ENABLE_TEST_ENDPOINTS=false

Validação realizada:

* /health retornou testEndpointsEnabled=false
* /test-client retornou bloqueado
* /simulate-sale protegido
* /mercado-pago/create-test-preference protegido
* /webhooks/mercado-pago permaneceu ativo

Conclusão:

As rotas de teste do backend TORICO agora ficam desabilitadas por padrão em produção, reduzindo exposição pública e mantendo ativo apenas o necessário para operação real.
