# TORICO

**Seu negócio vendendo. Onde você estiver.**

TORICO é um app/PWA para pequenos e médios comerciantes acompanharem vendas em tempo real, mesmo quando estão longe do ponto de venda.

O objetivo é dar ao dono do negócio uma visão simples e rápida do movimento do dia: total vendido, histórico de vendas e fonte das vendas recebidas.

## Status atual

- App/PWA Flutter funcionando.
- Autenticação com Firebase Authentication.
- Dados do app no Cloud Firestore.
- Hospedagem no Firebase Hosting.
- Backend Node.js/Express publicado no Google Cloud Run.
- Integração real com Mercado Pago validada via OAuth e webhook.
- Vendas recebidas pelo webhook são gravadas no Firestore pelo backend.
- Painel e Histórico atualizam os valores em tempo real.
- Tela Conta, Sobre o TORICO, Plano, Política de Privacidade e Termos de Uso fazem parte da experiência atual.

## Integração Mercado Pago

A integração com Mercado Pago usa autorização oficial por OAuth.

O app não solicita senha do Mercado Pago e não acessa tokens de integração. Tokens e dados privados de integração ficam restritos ao backend.

No Firestore, o app deve ler apenas o status público da integração:

```text
users/{uid}/integration_status/mercado_pago
```

O documento privado da integração fica separado em:

```text
users/{uid}/integrations/mercado_pago
```

Esse documento privado não deve ser lido pelo app.

## Stack

- Flutter/Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting
- Node.js/Express
- Google Cloud Run
- Mercado Pago OAuth/Webhook

## Estrutura principal

```text
lib/        App Flutter
backend/    Backend Node.js/Express
docs/       Documentação técnica do projeto
assets/     Imagens e sons do app
web/        Arquivos do PWA
```

## Comandos úteis

Antes de alterar o app Flutter:

```bash
flutter analyze
```

Depois de alterações no app:

```bash
flutter build web --release
```

Para validar o backend sem publicar:

```bash
cd backend
node --check server.js
```

Para publicar o app no Firebase Hosting:

```bash
npx --yes firebase-tools deploy --only hosting
```

## Segurança

Não colocar no código, README, documentação pública ou logs:

- secrets
- arquivos `.env`
- access tokens
- refresh tokens
- `TOKEN_ENCRYPTION_KEY`
- `MERCADO_PAGO_CLIENT_SECRET`
- credenciais privadas de Firebase, Mercado Pago ou Google Cloud

O app não deve gravar vendas diretamente no Firestore. Vendas reais devem ser gravadas pelo backend com Firebase Admin SDK.

## App Check

App Check/reCAPTCHA foi testado, mas causou problemas de compatibilidade em navegadores.

Por enquanto, o app Flutter não deve inicializar App Check e o enforcement não deve ser ativado.
