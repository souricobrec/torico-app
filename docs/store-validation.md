# Validação da preparação para lojas

Data: 12/10/2026. Ambiente: Windows, sem macOS/Xcode.

Registro histórico da branch `feature/store-readiness` (`a379638`). A migração
Android posterior e o resultado do AAB estão em [android-release-build.md](android-release-build.md).
Não interpretar a assinatura debug desta tabela como configuração atual da branch Android.

| Verificação | Resultado |
|---|---|
| flutter analyze --no-pub | Sem problemas |
| flutter test --no-pub | 47 testes aprovados |
| flutter build web --release --no-pub | Aprovado; 85,8 segundos |
| flutter build apk --release --no-pub | Não concluído: download Gradle 9.1.0-all parou; tentativa alternativa sofreu timeout |
| Build iOS | Não executado: macOS/Xcode indisponíveis |
| Nome nativo | TORICO em Android/iOS |
| Assets | Ícone fonte 1254×1254 RGB; iOS marketing 1024×1024 RGB; Android xxxhdpi 192×192 |
| Splash iOS | LaunchImage 1×1; personalização pendente |
| Manifest release | Adicionada somente INTERNET; não adicionadas permissões sensíveis |
| Assinatura de loja | Não configurada; Android release ainda usa debug |
| Deployment target iOS | Projeto 13.0 versus mínimo 15.0 nos podspecs Firebase instalados; alinhar antes de build |
| Textos da loja | Nome 6, subtítulo 21, descrição curta 77, keywords 59, longa 1784 caracteres |

## Comandos de build de verificação

Executados com a configuração piloto atual, sem publicar:

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub --dart-define=PILOT_ALLOWED_UIDS=4EGxLrjY5gPNVEFhibfG6dSBCnF3 --dart-define=PILOT_ALLOWED_EMAILS=sourico.br.ec@gmail.com,comercial.artcodex@gmail.com --dart-define=OFFICIAL_APP_HOSTS=app.meutorico.com.br --dart-define=FIREBASE_AUTH_DOMAIN=app.meutorico.com.br
flutter build apk --release --no-pub --dart-define=PILOT_ALLOWED_UIDS=4EGxLrjY5gPNVEFhibfG6dSBCnF3 --dart-define=PILOT_ALLOWED_EMAILS=sourico.br.ec@gmail.com,comercial.artcodex@gmail.com --dart-define=OFFICIAL_APP_HOSTS=app.meutorico.com.br --dart-define=FIREBASE_AUTH_DOMAIN=app.meutorico.com.br
```

Esses defines são configuração pública, não secrets. A allowlist só é aplicada
no gate web atual; compilar com defines não resolve o controle de acesso nativo.

Não houve upgrade Flutter, alteração de package/bundle ID, cadastro Firebase,
criação de conta demo, exclusão de dados, geração de assinatura de distribuição,
publicação, deploy ou chamada aos endpoints reais de conexão/desconexão.
Build iOS no futuro requer configuração Firebase iOS, toolchain e assinatura.
Os binários de verificação não significam aprovação nem homologação nas lojas.

## Bloqueio Android e diagnóstico

O wrapper iniciou o download oficial Gradle 9.1.0-all, mas o arquivo parcial
parou de avançar em 8.162.322 bytes. A URL oficial respondeu ao teste HTTP;
uma tentativa alternativa com curl expirou após 120 segundos, com apenas
45.720.308 dos 232.491.070 bytes recebidos. Nenhum arquivo completo foi
verificado/instalado a partir dessa tentativa. O processo específico de download
parado foi encerrado; não foi produzido APK nesta execução. Não confundir
esse bloqueio de infraestrutura com falha comprovada de compilação do código.

Ambiente inspecionado: Java Microsoft JDK 21 disponível, plataforma Android
36.1 presente; não foram encontrados diretórios instalados de build-tools,
cmdline-tools ou NDK nesse SDK local. Esses componentes ainda precisam de
preparação/verificação. Não aceitar licenças de SDK automaticamente nesta missão.
O diagnóstico geral flutter doctor foi interrompido por permanecer pendente;
a validação do ambiente Android não foi certificada por ele.

Para repetir manualmente, preparar Android SDK/command-line tools, build-tools,
plataforma compatível com compileSdk 36 e NDK 28.2.13676358, aceitar licenças
pessoalmente quando necessário, concluir download Gradle pela URL oficial e
validar checksum. Então executar novamente o comando APK acima. Depois auditar
manifest mesclado, assinatura e target do artefato. Nenhum APK/AAB está pronto
para envio à loja por esta preparação.

Arquivos locais antigos, documentos pessoais e gerados nativos previamente
modificados devem ficar fora do commit desta branch.
