# Plano de conta demo para revisão das lojas

Proposta de 12/10/2026, **não implementada**. Nenhum usuário foi criado e nenhum
dado foi gravado em Firebase/Firestore. Não há login ou senha real neste arquivo.

## Experiência proposta

Conta TORICO dedicada ao reviewer, separada dos pilotos/comerciantes existentes,
com login por e-mail/senha temporária e e-mail verificado. Revisão não deve
depender da conta Google pessoal do reviewer, de OAuth financeiro real, câmera,
SMS, dispositivo adicional ou período de vendas de um comerciante real.

Essa conta deve ter acesso explícito no controle de acesso final das lojas.
No PWA atual isso exigiria UID/e-mail na allowlist; o gate nativo ainda é uma
pendência. Não reutilizar UID dos proprietários e não liberar outros usuários.

Propor um conjunto de vendas **fictícias e identificado como demonstração**,
com dados do dia e dias anteriores, 11 ou mais registros para comprovar o limite
de 10 no Básico. Também mostrar painel vazio quando não há venda hoje. Manter
separação rigorosa dos dados reais e dos webhooks de produção.

Hoje o fluxo normal espera integração conectada antes de entrar no painel;
apenas criar usuário não resolve a revisão. Antes de submeter, implementar em
missão autorizada uma experiência demo isolada e transparente, sem gravar tokens
falsos em integrations e sem fingir conta Mercado Pago real conectada.
Reusar o mesmo modelo de UI/recursos do produto, sem esconder funções da loja.

Mercado Pago real pode ser opcional na revisão **se** a demo permitir conferir
todos os recursos essenciais e houver explicação clara para App Review/Play.
Não há garantia de dispensa pela loja. Para casos em que OAuth seja exigido,
preparar alternativa de teste oficial segura em missão separada, nunca entregar
senhas de contas financeiras pessoais ou forçar verificação facial do reviewer.

## Dados privados a fornecer somente no console da loja

| Campo | Preenchimento futuro |
|---|---|
| Login demo | E-mail dedicado, a criar depois de autorização |
| Senha temporária | Gerar fora do Git e fornecer no campo privado de App access/App Review |
| Validade | Manter a conta estável e funcional durante toda a revisão |
| Idioma | Português do Brasil |
| Plano | Básico; acesso adicional a Plus somente se implementado e revisável |
| Contato do reviewer | Nome, e-mail e telefone do responsável, em canal privado |
| Dados | Fictícios; sem informações de clientes reais |
| MFA/códigos | Reviewer não deve precisar solicitar códigos a uma pessoa para entrar |

Não gerar segredo aqui. Não colocar credenciais em README, prints, GitHub,
dart-define, Firestore público ou descrição pública da loja.

## Roteiro proposto para o reviewer

1. Abrir TORICO e entrar com as credenciais privadas fornecidas.
2. Entrar na demonstração identificada; consultar Painel e Histórico Básico.
3. Verificar limite de 10 registros e a distinção entre hoje e dias anteriores.
4. Em Conta, conferir fontes: MP é a única disponível; REDE Pausada; futuras em preparação.
5. Ativar som com toque explícito; não esperar notificações quando app está fechado.
6. Conferir os textos distintos de logout, limpeza local e desconexão.
7. Executar logout/limpeza e entrar novamente; dados demo na nuvem continuam.
8. Para desconexão/reconexão demonstrativa, usar somente o fluxo isolado a
   implementar, sem chamar conta Mercado Pago real. Descrever limitações ao reviewer.
9. Acessar política e fluxo de exclusão da conta, que precisam existir no binário final.

Se um passo ainda não funcionar, bloquear submissão e corrigir primeiro.
Após revisão, revogar/rotacionar credenciais demo e limpar apenas dados fictícios
com autorização específica. Não executar limpeza nesta missão.

Fontes: [acesso para App Review](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/),
[Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
