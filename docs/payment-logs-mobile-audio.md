# Logs de pagamentos ignorados e áudio no dispositivo

O webhook mantém o retorno antecipado para pagamentos diferentes de `approved`.
O novo log contém somente a mensagem, paymentId, status e amount quando disponível;
não registra tokens nem payload completo. OAuth e URLs permanecem iguais.

No Painel, “Ativar som de vendas” toca o asset curto `cash.mp3` e salva
`sales_sound_enabled` localmente. Nenhum áudio automático é autorizado por toques
genéricos. O navegador pode exigir novo toque ao reabrir o app; a preferência
persistida não substitui essa autorização. Falhas de áudio não afetam vendas.

Os alertas usam registros approved do Mercado Pago, ignoram o primeiro snapshot
e deduplicam por externalId/id durante a sessão. REDE não gera alertas.
O painel deve estar aberto; não há promessa de áudio em segundo plano ou com
o celular bloqueado. O stream de vendas do dia existente mantém seu limite de
10 registros; não é uma fila de notificações nem recupera avisos perdidos offline.

Validação: `flutter analyze`, `flutter test`,
`node --test backend/test/ignored-payment.test.js`, `flutter build web --release`.
Sem deploy, alteração de infraestrutura ou exclusão de vendas.
