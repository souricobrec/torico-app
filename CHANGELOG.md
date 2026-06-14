# CHANGELOG

Todas as mudanças relevantes do TORICO devem ser registradas neste arquivo.

## MVP Mercado Pago validado - 2026-06-14

Versão de validação do MVP com integração real do Mercado Pago funcionando ponta a ponta.

### Marcos principais

- App/PWA Flutter funcionando para acompanhamento de vendas em tempo real.
- Painel principal exibindo total vendido no dia.
- Histórico exibindo vendas recebidas no dia.
- Tela Conta organizada com status de integrações e links legais.
- Tela Plano atualizada para o posicionamento do TORICO Básico e TORICO Plus futuro.
- Sobre o TORICO, Política de Privacidade e Termos de Uso adicionados ao app.
- Mercado Pago validado como primeira integração real do TORICO.

### Integração Mercado Pago

- Fluxo OAuth Mercado Pago validado.
- Webhook Mercado Pago validado.
- Vendas reais/controladas recebidas pelo backend e gravadas no Cloud Firestore.
- Painel e Histórico atualizando a partir dos dados gravados no Firestore.
- Status público da integração exposto para o app por `users/{uid}/integration_status/mercado_pago`.
- Documento privado de integração mantido separado em `users/{uid}/integrations/mercado_pago`.

### Segurança

- O app não lê tokens OAuth nem documentos privados de integração.
- O app usa apenas o documento público de status para identificar se o Mercado Pago está conectado.
- Tokens OAuth ficam restritos ao backend.
- Tokens armazenados com criptografia AES-256-GCM.
- Escrita direta em `sales` pelo app bloqueada pelas regras do Firestore.
- Vendas reais são gravadas pelo backend usando Firebase Admin SDK.
- Secrets, tokens, chaves privadas e variáveis sensíveis não devem ser documentados, commitados ou enviados para logs.

### Backend e deploy

- Backend Node.js/Express publicado no Google Cloud Run.
- App/PWA publicado via Firebase Hosting.
- Health check público disponível no backend.
- Backend responsável por receber webhooks, validar eventos e gravar vendas no Firestore.
- Deploy do app validado com build web release.

### Validações realizadas

- OAuth Mercado Pago validado.
- Webhook Mercado Pago validado.
- Recebimento de venda validado.
- Escrita de venda no Firestore validada.
- Atualização do Painel validada.
- Atualização do Histórico validada.
- Separação entre documento privado de integração e documento público de status validada.
- `flutter analyze` executado sem issues.
- `flutter build web --release` executado com sucesso.

### Limitações conhecidas

- App Check/reCAPTCHA foi testado, mas não deve ser inicializado no Flutter por enquanto devido a problemas de compatibilidade em navegadores.
- Enforcement de App Check não deve ser ativado nesta fase.
- Stone e PagBank permanecem como integrações futuras.
- TORICO Plus ainda é uma experiência futura; recursos avançados continuam bloqueados ou informativos.
- Fluxos de cobrança do plano ainda não estão habilitados no app.
- Qualquer mudança em Mercado Pago, backend, Cloud Run, secrets, env vars ou Firestore Rules deve ser feita com confirmação explícita e validação cuidadosa.

### Comandos de validação recomendados

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
