# Deploy do TORICO no Firebase Hosting

Este documento registra a decisão de publicar o app Flutter Web/PWA do TORICO no Firebase Hosting.

## Decisão

O Firebase Hosting passa a ser o ambiente principal de publicação do TORICO.

A Vercel permanece temporariamente como ambiente de backup, até decisão futura de remoção ou desativação.

## Motivo da decisão

O TORICO já utiliza serviços do ecossistema Firebase e Google Cloud:

* Firebase Authentication
* Cloud Firestore
* Google Cloud Run
* Firebase Project `torico-ca479`

Por isso, publicar o Flutter Web/PWA no Firebase Hosting simplifica a arquitetura e centraliza a operação em uma mesma plataforma.

## Arquitetura atual

```text
Usuário / Navegador / iPhone
→ Firebase Hosting
→ Flutter Web/PWA TORICO
→ Firebase Authentication
→ Cloud Firestore
→ Google Cloud Run Backend
→ Webhooks oficiais das plataformas
```

## URL principal

```text
https://torico-ca479.web.app
```

## Backend

O backend real permanece publicado no Google Cloud Run:

```text
https://torico-backend-16783123127.us-central1.run.app
```

## Comandos de build e deploy

Para gerar o build web:

Antes de publicar, seguir [migração da API oficial](api-domain-migration.md).
Build sem defines agora usa `https://api.meutorico.com.br`, que precisa estar ativo.
Para preview durante a transição, usar `APP_ENV=preview` e definir explicitamente
`API_BASE_URL=https://torico-backend-16783123127.us-central1.run.app`.

```bash
flutter build web --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.meutorico.com.br
```

Para publicar no Firebase Hosting:

```bash
npx firebase-tools deploy --only hosting
```

## Arquivos principais

```text
firebase.json
.firebaserc
web/index.html
web/manifest.json
build/web
```

## Validação realizada

Após o deploy no Firebase Hosting, foram testados:

* carregamento da tela inicial;
* login;
* Painel;
* ausência do botão Nova venda;
* funcionamento do PWA;
* comunicação com Firebase Authentication;
* leitura de dados do Cloud Firestore;
* integração com backend publicado no Cloud Run.

## Status

Firebase Hosting aprovado como publicação principal do TORICO.

Vercel mantida apenas como backup temporário.
