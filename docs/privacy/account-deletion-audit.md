# Exclusão de conta TORICO — auditoria e protótipo

Status: preparação para revisão. Nenhum endpoint de exclusão implementado/ativado, pedido registrado, e-mail enviado ou dado real consultado/excluído. Sem APK/AAB, deploy ou mudanças de configuração. Auditoria do código, não inventário do banco de produção. Coleções adicionais, órfãos, exports e cópias operacionais devem ser levantados em staging e leitura autorizada antes de ativar.

## Inventário associado ao UID

| Local / evidência de código | Dados | Tratamento futuro |
|---|---|---|
| Firebase Auth; `lib/services/auth_service.dart` | UID, provedores Google/password, e-mail, nome/foto, verificação, sessões | Reautenticar antes da aceitação; revogar sessões e desabilitar durante processamento; excluir usuário apenas pelo Admin no worker. Não excluir conta Google do titular. |
| `users/{uid}`; `user_plan_service.dart:52`, `firestore.rules:31` | Perfil permitido pelas Rules (displayName, email, photoURL, businessName, phone, onboarding), plano/nome/data | Enumerar campos efetivamente existentes; eliminar perfil/plano sem criar conta substituta. |
| `users/{uid}/integrations/mercado_pago`; `backend/server.js:1933` | mercadoPagoUserId, scope, publicKey, tokenType, liveMode, expiração/datas, accessTokenEncrypted e refreshTokenEncrypted | Bloquear imediatamente o uso; revogar autorização no provedor somente com desenho aprovado; remover tokens e vínculo. AES-256-GCM em server.js:367; segredo de criptografia compartilhado não deve ser removido/rotacionado para apagar uma conta. |
| `users/{uid}/integration_status/mercado_pago`; server.js:1963 | Status público sem tokens | Marcar indisponível durante processamento; remover ao excluir. |
| `users/{uid}/integrations/*`, `integration_status/*` | Outras integrações eventualmente existentes: PagBank/REDE e futuras | Enumerar sem ativar plataformas/Scheduler. Não presumir ausência por estarem pausadas. |
| `users/{uid}/sales/*`; server.js:1591, 1611, 1788 | Valor, plataforma, status, IDs, data, rawPayload com UID, IDs MP, payer_id, webhook query/body e merchant_order/external_reference | Exclusão de documentos e payloads, incluindo referências de terceiros. Não limitar ao histórico básico de 10 vendas. |
| `users/{uid}/daily_totals/*`; server.js:1612, 1667-1712 | Total/count por plataforma/dia, datas e last10Sales (cópias de vendas) | Excluir inclusive resumos e arrays; retirar somente sales não basta. |
| `users/{uid}/integration_requests/*`; Rules:60; `rede_connect_screen.dart:34` | Pedidos de conexão legados | Excluir todos os pedidos deste UID, sem ativar REDE. |
| Subcoleções desconhecidas sob users; Rules:66 | Possíveis estruturas futuras/legadas | Descoberta recursiva paginada. Apagar documento pai NÃO apaga subcoleções. |
| `oauth_states/*`; server.js:1996 | State PagBank com userId, platformId, used, validade | Localizar pelo UID e invalidar/remover. State MP atual é HMAC com UID/nonce/tempo (279/306), não documento consumível: rejeitar retorno tardio pelo tombstone. |
| Cloud Run/Cloud Logging; server.js:1753, 1824, 3293, 3400, 3442 | UID/toricoUserId, IDs de pagamento/vendedor, valor/status, query, mensagens de erro | Levantar sinks/buckets/retenções sem assumir prazo. Minimizar logs futuros; não copiar payloads/tokens no log da exclusão. Definir tratamento para registros técnicos legalmente necessários. |
| Exports/backups, PITR, suporte/e-mail, CI/artefatos | Existência e prazos não verificados nesta missão | Inventário e política obrigatórios. Expurgo/expiração controlados; restauração deve reaplicar tombstones antes de permitir escrita. E-mails de suporte também são dados pessoais. |
| Dispositivo; `local_storage_service.dart`, `audio_service.dart`, `pilot_access_service.dart` | connected_platform(s), total_sold/data, som, flag piloto; cache Firebase/Auth/Firestore | Não limpar ao apenas preparar pedido. Após processamento/autenticação revogada, encerrar sessão e limpar caches locais com segurança; outros dispositivos/offline exigem estratégia própria. Não remover allowlist nesta entrega. |

Rules locais negam exclusão de users/sales/daily_totals/integrations/status pelo cliente. O protótipo não tenta contornar isso nem grava novos documentos. Rules de produção não foram consultadas/alteradas. Campos de exclusão devem ficar em coleção server-only para não depender de campos client-controlled em users/create.

## Página pública verificada

`https://www.meutorico.com.br/exclusao-de-conta` respondeu HTTPS 200 (URL final com barra). Identifica TORICO/Elton Cruz, contato sourico.br.ec@gmail.com, explica atendimento manual, verificação de identidade, escopo, retenções ainda em revisão e diferença entre sair/limpar/desconectar/excluir. Não exige login. Página e fonte em `site-legal/public/exclusao-de-conta/index.html` foram somente lidas; permanecem intactas.

Pendências da página: definir categorias/prazos de retenção e backups; prazo operacional/forma de confirmação; atualizar texto sobre fluxo interno depois de aprovação e publicação do app. Ela ainda informa corretamente que o app publicado não tem fluxo completo. Não publicar texto que prometa processamento automático inexistente.

## Protótipo no app (Android e PWA, sem condicionais por plataforma)

Conta → **Excluir minha conta** → explicação → confirmação explícita → **Preparar solicitação por e-mail**. Abre somente compositor externo, com destinatário/assunto fixos e texto genérico. Não preenche UID, token ou perfil automaticamente; titular informa o e-mail da conta. O envio depende da ação do titular no cliente de e-mail.

Estados reais: pronto; abrindo; compositor aberto/envio não confirmado; falha com fallback; e-mail copiado. Nenhum desses estados equivale a solicitado/recebido/em processamento/concluído. Sem persistência local de falso protocolo. Voltar não faz logout, disconnect, limpeza ou chamada HTTP. Página pública abre em navegador externo, e suporte pode ser copiado se não houver cliente e-mail.

Acompanhar hoje: aguardar confirmação de recebimento e responder à mesma conversa. Nenhum protocolo, SLA, retenção fixa ou exclusão é inventado. Os serviços de autenticação, integrações e armazenamento não são importados pela nova tela/serviço de contato.

## Requisitos de loja — limites, não declaração de conformidade

Fontes oficiais consultadas em 15/10/2026 UTC:

- Google: https://support.google.com/googleplay/android-developer/answer/13327111?hl=en — caminho dentro do app e recurso externo para pedir exclusão de conta/dados; concluir Data safety conforme implementação real.
- Apple: https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion — permitir iniciar exclusão no app, incluindo dados associados; em geral não exigir e-mail/suporte para apps fora de setores altamente regulados. Processamento manual pode existir, com prazo e confirmação transparentes.

O TORICO não deve presumir exceção de setor altamente regulado só por integrar Mercado Pago. Este contato manual é protótipo e NÃO resolve sozinho a preparação para Apple. Não declarar conta excluída nem marcar conformidade final na Google Play antes de validar processo operacional, retenção e atendimento. Backend seguro com registro e confirmação é a recomendação para ambas.

## Resultado da validação desta entrega

- `flutter analyze --no-pub`: sem problemas (após corrigir dois avisos de chaves no protótipo).
- `flutter test --reporter compact`: **77 testes aprovados** (69 anteriores + 8 novos).
- Testes novos: link e template mínimos; navegação Conta/voltar sem logout/desconexão; confirmação e estado verdadeiro em 320/390/768 px; falhas de abertura/exception com alternativa; página externa sem confirmação; bloqueio de duplo clique em andamento.
- Revisão de segurança: tela sem dependência de Auth/Firestore/HTTP, sem UID/token nos URIs, sem `delete`, sem persistência de falso protocolo; nova rota backend não existe. Somente launch externo e cópia de suporte após clique.
- Backend, Rules, página legal pública, Android, autenticação, allowlist e preços sem alterações nesta branch. Nenhum APK/AAB ou deploy gerado.
- Manuais pendentes após revisão: verificar mailto em Android sem cliente instalado, navegador externo, leitor de tela, fonte ampliada; revisar prazo/retencões com responsável e processo operacional; implementar/testar backend em staging e atualizar página pública/aplicativo apenas sob nova autorização.
