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
