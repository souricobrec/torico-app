# UX de login e plano básico

Login Google mostra “Conectando com Google...” e “Aguarde a conclusão do login.”,
com progresso acessível, campos somente leitura e botões sem perder suas cores.
Mensagens amigáveis já existentes continuam sendo usadas para cancelamento/erro.
O callback e a vinculação de contas Google não mudaram.

Básico: Painel, Plano e Conta. Histórico aparece somente com `plan == plus` do
documento existente do usuário. Navegação usa uma leitura do plano sem criar ou
alterar documentos. Plano ausente, desconhecido, pendente ou com erro não libera
Histórico. A própria tela valida Plus antes de iniciar as consultas de vendas,
inclusive por rota antiga. Uma mudança de Plus para básico fecha essa tela.
Esse bloqueio é de UX; não altera regras Firestore ou autorização do backend.

Histórico existente permanece disponível para Plus, com filtro de data. O básico
acompanha o total de hoje; não inclui consulta histórica. Textos de Plano foram
ajustados sem mudar preços, assinatura ou concessão de Plus.

“Limpar conexões deste dispositivo” pede confirmação e executa limpeza das
conexões/totais locais seguida de logout. O gate oficial/técnico retorna ao login;
o fluxo local legado também retorna ao login. Não apaga vendas, dados do usuário
ou integrações na nuvem e não desconecta Mercado Pago no servidor. No próximo
login, o app pode recuperar a conexão existente do mesmo usuário.

Logout permanece somente em Conta dentro do app. REDE continua pausada; Mercado
Pago é a única fonte ativa. Host oficial, authDomain, piloto técnico e allowlists
não mudaram. Nenhum console, DNS, Hosting, backend, webhook ou Scheduler alterado.

Validar `flutter analyze`, `flutter test` e `flutter build web --release`.
Os testes usam planos, sessões e vendas simulados; sem deploy ou acesso a dados
reais. Na futura publicação autorizada, conservar os quatro defines de produção.
