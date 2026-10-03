# UI antes do piloto Lelê

Branch `feature/ui-active-sources-slogan`, baseada em `visual-pre-lojas`.

O login oficial mostra TORICO e “Seu negócio vendendo. Onde você estiver.”,
preservando Google, e-mail/senha e allowlists. “Sair da conta” aparece somente
quando há uma identidade autenticada, inclusive sessão fora da allowlist que
precisa ser encerrada. O modo técnico mantém seu botão de limpeza.

`ActiveSalesSources` centraliza a política de exibição desta fase: somente
Mercado Pago, quando presente nas conexões retornadas, é considerado ativo.
REDE é pausada independentemente de conexões antigas no dispositivo/backend.
Conta e painel não a contam como monitorada; no histórico seu filtro fica
esmaecido e sem ação, inclusive na seleção de plataformas. Gerenciar conexões
não oferece solicitação de ativação assistida de REDE nesta fase.

Não removemos conexões armazenadas, registros, histórico, totalizadores ou dados
Firebase. O filtro Todas continua preservando registros históricos de qualquer
fonte; fonte histórica não significa monitoramento ativo. Não alteramos leitura
de vendas ou OAuth do Mercado Pago, UID ou autenticação. Esta política de UI
não consulta o Scheduler; uma retomada futura de REDE exige revisão explícita.

Validação: `flutter analyze --no-pub`, `flutter test --no-pub` e
`flutter build web --release`. Testes de widget cobrem Conta, filtro pausado,
login/slogan e saída; testes existentes cobrem domínio oficial e modo técnico.
Dados reais e a venda de R$1,00 não são acessados pelos testes locais.

Resultado local: análise sem avisos, 16 testes aprovados e build web release
concluído. O build de validação usa as allowlists vazias por padrão; não é um
artefato publicado para pilotos.

Sem deploy, mudança DNS/Hosting, backend, Cloud Run, Mercado Pago, webhook,
Secret Manager ou ativação de REDE/Scheduler.
