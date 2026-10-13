# TORICO — materiais Google Play

Preparados em 13/10/2026, sem publicação/deploy. Marca navy/dourado preservada.

## Assets

- `icon-512.png`: 512×512, PNG RGBA, 488.462 bytes; derivado por redução Lanczos
  do asset oficial `assets/images/app_icon.png`, sem alterar o ícone do aplicativo.
  Dimensão e tamanho atendem ao formato Play; revisão editorial do titular pendente.
- `feature-graphic-1024x500.png`: 1024×500, PNG RGB sem alpha, 82.248 bytes.
  Arte tipográfica com TORICO e slogan oficial, sem logos de futuras integrações,
  preços ou promessas adicionais. Aprovação editorial pendente.
- `provisional-web/01-login.png`, `02-painel.png`, `03-historico-basico.png`,
  `04-plano.png`, `05-conta-integracoes.png`: cinco prévias 1080×1920 PNG RGB.
  Dimensões, canais e tamanhos exatos estão em `manifest.json`.

## Importante: origem dos screenshots provisórios

São **reconstruções editoriais HTML/CSS locais baseadas no layout/código do
Flutter/PWA**, não capturas do PWA publicado nem screenshots de execução Android.
O selo “DEMONSTRAÇÃO · PRÉVIA WEB” permanece visível nas cinco imagens.
Não enviar como screenshots nativos finais na Console. Substituir por capturas
reais do Android homologado, usando dados de demonstração isolados.

Referências de layout: `lib/widgets/official_login_layout.dart`,
`lib/screens/painel_screen.dart`, `lib/widgets/basic_sales_history.dart`,
`lib/screens/plan_screen.dart`, `lib/screens/settings_screen.dart`.
O enquadramento editorial foi simplificado para apresentar os conceitos;
não é garantia de correspondência pixel a pixel com o binário.

Não houve login, OAuth, consulta ao Firestore/API ou coleta de clientes reais.
Renderização offline em Chrome headless, com requisições de rede bloqueadas.
E-mail e senha aparecem somente como campos vazios. Mercado Pago conectado é
um estado demonstrativo. Vendas fictícias: R$ 78,00, R$ 49,50 e R$ 29,00;
total R$ 156,50. Nenhum UID, e-mail pessoal, token ou valor real aparece nas imagens.
REDE permanece Pausada; outras integrações em preparação. Plano não define preço.

## Reproduzir localmente

`tools/render.cjs` utiliza Playwright e Sharp, disponíveis no runtime local.
Definir `NODE_PATH` para a instalação que contém esses módulos; opcionalmente
`CHROME_PATH` para o Chrome oficial local. Executar da raiz do repositório:

```powershell
node store-assets/google-play/tools/render.cjs
```

O script escreve somente os materiais desta pasta. Não altera app, Firebase,
assinatura, backend ou integrações. HTMLs em `provisional-web/` são fontes locais
com imagens oficiais embutidas; não publicá-los como parte do aplicativo.
Não foi usado gerador de imagens IA: marca preservada e composição determinística.

## Validações e pendências

- Dimensões/canais PNG conferidos automaticamente; ícone abaixo de 1.024 KB.
- Feature graphic sem transparência; textos e enquadramento revisados visualmente.
- Cinco prévias revisadas, sem scroll horizontal no viewport de captura.
- Pendentes: aprovação dos assets, screenshots Android reais e teste físico;
  login Google/gate piloto/retorno OAuth nativos e demais bloqueios do pacote Play.
- Páginas legais já públicas; retenção, revisão jurídica e processo de exclusão
  ainda exigem revisão humana. Nenhum material enviado à Google Play.

Referência: [assets Google Play](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).
