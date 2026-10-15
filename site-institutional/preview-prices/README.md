# Preços oficiais — revisão em preview

- Básico: R$ 24,90/mês.
- Plus: R$ 39,90/mês, Em breve, sem contratação.
- Cobrança não ativada; plano atribuído não comprova assinatura paga.

## Escopo e publicação pendente

Flutter compartilhado por Android/PWA: preços centralizados em `lib/core/plan_prices.dart`; tela Plano e Termos atualizados. A tela Plano usa a leitura de plano existente, sem criar/alterar plano de usuário.

SAGA: estes arquivos são cópias revisáveis do preview, não um site independente completo. `index.html`, `termos.html` e `default.conf` correspondem respectivamente a `/opt/torico-site/public/index.html`, `/opt/torico-site/public/termos.html` e `/opt/torico-site/nginx/default.conf`.

`/planos` era inexistente no preview. Agora retorna 302 para `/#planos`, preservando a seção e o design aprovados. Os dois CTAs continuam informativos (`/contato`), sem checkout.

Backup: `/opt/torico-site/backups/prices-20261014/` (index.html, termos.html, default.conf).
Rollback do preview: restaurar estes três arquivos nos caminhos originais, executar `docker exec torico-site-preview nginx -t` e, somente após sucesso, `docker exec torico-site-preview nginx -s reload`.

Nenhuma alteração na cópia `/opt/torico-site-production`, Firebase Hosting, app publicado, backend, banco, integrações ou cobrança. Publicações futuras, mediante aprovação: build/deploy PWA; novo APK/AAB Android; replicação do site institucional na produção isolada e eventual publicação institucional. Não executar cutover/DNS nesta revisão.

## Evidências

Preview: https://torico-preview.163.176.182.47.sslip.io/planos
Capturas em `evidence/`: 1440, 768, 390 e 320 px. Sem overflow horizontal; preços corretos; Plus Em breve; links de contato preservados. nginx -t aprovado; reload aprovado; HTTP 301 para HTTPS; healthz HTTPS 200.

Varredura adicional: a produção isolada ainda contém os textos antigos em `public/index.html` e `public/termos.html`; permanece intencionalmente inalterada até aprovação. Os materiais gráficos editoriais antigos em `store-assets/google-play` não são capturas do build nem foram regenerados nesta revisão; precisam de atualização antes da submissão, sem reutilizar a observação histórica “sem preço novo definido”. A distribuição gratuita/paga na Play Console é decisão separada dos preços comerciais do serviço.

Validação final Flutter: `flutter analyze --no-pub` sem problemas; `flutter test` com 60 testes aprovados, incluindo três cenários novos de preços/Plus em 320, 390 e 768 px. Os testes usam stream de plano em memória, sem Firebase/Firestore real. Os testes novos detectaram estouros de texto em chips e no botão Plus; corrigidos com texto flexível e quebra da linha de preço, sem mudar recursos.
