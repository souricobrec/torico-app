# Revisão de status e validação por data

- Mercado Pago conectado é a única fonte monitorada; status do painel:
  “Monitorando 1 fonte de venda: Mercado Pago”. Sem conexão, nenhuma fonte ativa.
- REDE: “Pausada”, mesmo se houver conexão antiga no cache; não monitorada.
- Stone, PagBank, Cielo, Getnet, Pagar.me, Asaas e InfinitePay: “Em preparação”.
- Logout fica em Conta, sem rodapé global no app. Sessão não autorizada tem
  “Trocar conta” junto à mensagem; login técnico mantém “Sair do modo piloto”.
- Histórico agora seleciona dia, com calendário/dia anterior/próximo dia.
  A consulta usa a mesma coleção do usuário, filtros e limite anteriores;
  somente a data de leitura muda. Não há escrita, migração ou exclusão de vendas.

## Checklist após futura publicação autorizada

1. Login Google no host oficial mantém a identidade Firebase e o acesso autorizado.
2. Painel mostra somente Mercado Pago; conta mostra 1 fonte monitorada.
3. REDE aparece pausada em Conta, seleção de integração e filtros do Histórico.
4. Outras plataformas aparecem em preparação e não contam como conectadas.
5. Painel, Histórico e Plano não têm logout solto no rodapé; Conta mantém logout.
6. Painel usa o dia atual: R$ 0,00 sem vendas de hoje é esperado. Reabrir/atualizar
   o app se ficou aberto durante a virada do dia.
7. No Histórico, selecionar a data da venda real de R$ 1,00 (02/10/2026), depois
   Mercado Pago. A venda deve continuar acessível; não exigir R$ 1,00 em hoje.
8. Host técnico sem piloto continua pré-lançamento em navegador sem preferência
   persistida; `?pilot=1` mantém o fluxo técnico e a allowlist.

Testes usam dados simulados, sem acessar ou alterar Firestore/produção.
Validar `flutter analyze`, `flutter test` e `flutter build web --release`.
Sem deploy automático, mudanças de configuração Firebase/Hosting, backend,
OAuth/webhooks Mercado Pago, DNS ou REDE/Scheduler.
