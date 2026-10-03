# OAuth Mercado Pago no navegador externo

O botão **Abrir Mercado Pago** mantém a URL `/integrations/mercado-pago/connect?userId=<UID Firebase>` e chama `launchUrl` diretamente no clique, com `LaunchMode.externalApplication` e alvo web `_blank`. A consulta assíncrona `canLaunchUrl` foi removida para preservar a ativação do usuário no navegador.

Antes de abrir, a tela explica que a autorização e eventual verificação por câmera acontecem no navegador externo. Ao retornar, a integração continua pendente até **Verificar conexão** confirmar o status persistido pelo callback. Abrir a URL não significa que a conta está conectada.

No web, `_blank` solicita outra aba/janela, sem modal ou webview do TORICO. A escolha final de aba/janela e as permissões de câmera dependem do navegador. Um navegador embutido de outro aplicativo pode continuar limitando a câmera; nesse caso, abrir o próprio TORICO em Chrome/Safari e repetir o botão. No aplicativo nativo, solicita-se o navegador externo ao sistema operacional.

## Validação

- `flutter analyze`
- `flutter test` (inclui abertura imediata, URL/UID, modo externo, alvo `_blank`, falha de abertura e aviso na tela)
- `flutter build web --release` com os defines oficiais atuais
- Teste manual pendente no dispositivo: autorizar em Chrome/Safari com câmera, voltar ao TORICO e verificar conexão. Não houve login ou OAuth real nesta alteração.

Backend, callback, client OAuth, webhook, allowlist e dados permanecem sem alterações. Pendências de segurança anteriores (Firebase ID token no início OAuth, vínculo único da conta Mercado Pago e consumo único do state) continuam registradas; esta mudança não as resolve. Sem deploy.
