# Android release TORICO — preparação e resultado

Revisão: 12/10/2026. Branch `feature/android-store-build`, base
`feature/store-readiness` (`a379638`). Sem publicação, contas novas ou deploy.

## Identidade definitiva Android

- `namespace` e `applicationId`: **br.com.meutorico.app**.
- Nome visível: TORICO; INTERNET preservado no manifest principal.
- `MainActivity`: `android/app/src/main/kotlin/br/com/meutorico/app/MainActivity.kt`,
  package `br.com.meutorico.app`. O manifest continua usando `.MainActivity`.
- O arquivo antigo estava em caminho com.example.vendaon, mas declarava
  com.example.torico; ambas as inconsistências foram removidas do código Android.
- Identificador iOS não foi alterado nesta missão Android.

## Firebase — ação manual necessária, não executada

O JSON local anterior registra `com.example.vendaon`; não corresponde ao novo
applicationId. O cadastro Android existente não pode ser simplesmente renomeado.
O arquivo foi **removido do rastreamento Git, mantendo a cópia local**, e passou
a ser ignorado. Isso não remove apps, usuários ou configurações no Firebase.

No Console do projeto **torico-ca479**, somente após autorização/acesso do titular:

1. Configurações do projeto > Seus apps > Adicionar app Android.
2. Informar exatamente `br.com.meutorico.app`, com nome opcional TORICO Android.
   Não excluir o cadastro antigo e não criar outro projeto.
3. Registrar SHA-1/SHA-256 das assinaturas usadas em testes. Depois de configurar
   Play App Signing, registrar também fingerprints da assinatura de distribuição,
   que não é necessariamente a chave de upload.
4. Baixar a configuração oficial `google-services.json` do **novo cadastro**.
5. Validar `project_id=torico-ca479`, client package `br.com.meutorico.app` e o
   Firebase Android app ID emitido pelo Console. Não editar o package no JSON
   antigo para fingir um registro novo.
6. Verificar ausência de chave privada de service account, passwords, tokens
   OAuth/refresh e outros segredos. API keys de configuração Firebase cliente são
   identificadores públicos, mas revisar projeto e restrições antes de distribuir.
7. Substituir localmente `android/app/google-services.json`. Ele permanece ignorado
   por padrão; não versionar automaticamente nem usar `git add -f`.
8. Atualizar **somente** `DefaultFirebaseOptions.android` em
   `lib/firebase_options.dart` com os valores públicos oficialmente emitidos.
   Atualmente essa constante ainda pertence ao cadastro antigo, por falta de
   novo cadastro autorizado. Manter opções web, projeto, Auth e usuários intactos.
9. Se usar FlutterFire CLI, revisar previamente a saída e o diff de
   `firebase.json`/`firebase_options.dart`; não sobrescrever opções web/iOS.

Não alterar provedor Firebase Auth, conta de usuário, OAuth client Mercado Pago,
callback ou webhook para esta migração de identificador. Mesmo projeto preserva
identidade de usuários; o login nativo e associação ao mesmo UID precisam de
homologação separada. Google login atual é web, não está homologado no Android.

## Assinatura de upload — preparar privadamente

Release usa configuração `release` e **não** fallback para chave debug.
Gradle lê `android/key.properties`; build release falha claramente se o arquivo,
uma propriedade obrigatória ou o keystore estiver ausente/for placeholder.
Debug mantém sua assinatura padrão. Senhas não são impressas pelo script.

Nenhum keystore ou senha foi gerado nesta missão. Exemplo com placeholders:
`android/key.properties.example`. Regras `.gitignore` protegem key.properties,
`.jks`, `.keystore` e a configuração Firebase local, inclusive fora de android/.

O titular pode gerar a chave em sessão local interativa, fora do repositório:

```powershell
# Executar manualmente, não inserir -storepass/-keypass no comando.
New-Item -ItemType Directory -Force "$env:USERPROFILE\.torico-signing"
keytool -genkeypair -v -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias torico-upload -keystore "$env:USERPROFILE\.torico-signing\upload.jks"
Copy-Item android/key.properties.example android/key.properties
```

Escolher senha forte privadamente quando o keytool solicitar. Preencher
key.properties em editor local: storeFile, storePassword, keyAlias e keyPassword.
Windows: usar barras `/` ou escapar `\\` no arquivo Properties. Caminho absoluto
recomendado; relativo resolve a partir de `android/`. Não usar nome/path deste
exemplo como credencial real nem enviar arquivo/senha no chat, logs ou Git.
Proteger permissões locais e manter backup privado da chave e recuperação.
Não registrar ou subir fingerprints da chave sem a etapa manual autorizada.

## Gradle e versões

Versão mantida **9.1.0**. Apenas `-all` foi trocado por `-bin`, que contém o
runtime necessário ao build sem documentação/fontes extras. AGP, Kotlin, Flutter,
compileSdk, targetSdk, minSdk e NDK não tiveram versões trocadas.
Checksum oficial do bin foi fixado no wrapper:

`a17ddd85a26b6a7f5ddb71ff8b05fc5104c0202c6e64782429790c933686c806`

`networkTimeout=60000` limita conexões que ficam sem avanço. Para ambientes com
download JVM problemático, um arquivo oficial completo verificado pode alimentar
o cache do wrapper. Não usar arquivo parcial nem ZIP de outra versão como substituto.

Nesta missão o ZIP `bin` oficial foi baixado completamente (134.528.013 bytes),
verificado com esse SHA256 e extraído no cache do wrapper. O bloqueio inicial de
download da distribuição `all` foi superado sem downgrade de versão. O cache
local não é versionado; outros computadores precisam concluir esse bootstrap.

## Sequência solicitada

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Resultados desta missão: clean e pub get concluídos, análise sem problemas,
47 testes aprovados. Houve **uma única tentativa** de appbundle release; falhou
com código 1 após configurar o Gradle, em 6m35s (etapa Flutter: 396,2s).
Erro exato em `android/app/build.gradle.kts`, linha 22:

```text
TORICO release signing: android/key.properties is missing. Follow docs/android-release-build.md; never commit credentials.
```

A execução foi interrompida nesse resultado, sem retry ou alterações em versões.
O guard de assinatura impediu fallback silencioso para debug. Não foi criado AAB,
não há tamanho/certificado/manifest final a declarar. O Google Services do novo
identificador ainda depende do cadastro manual; essa fase não foi homologada
porque o build parou antes. Esta preparação não aceita licenças de SDK
automaticamente nem fabrica configuração Firebase ou assinatura.

Depois de configurar Firebase/assinatura, usar defines públicos apropriados ao
controle nativo efetivamente implementado. Os defines piloto atuais não resolvem
sozinhos o gate nativo: ele hoje só protege a web. Não distribuir o binário antes
de corrigir essa pendência de segurança.

## Se houver sucesso futuro

AAB esperado: `build/app/outputs/bundle/release/app-release.aab`. Registrar tamanho,
SHA256, applicationId, min/target SDK efetivos, assinatura e permissões do manifest
mesclado. Valores atuais herdados do Flutter local: compile/target 36, min 24,
NDK 28.2.13676358; são configuração, não certificação de um artefato ausente.
AAB não é instalado diretamente: usar bundletool para gerar APKs compatíveis,
assinados, e instalar em dispositivo autorizado. Não enviar AAB à Play nesta missão.

## Testes físicos / pendências Google Play

- Cadastro Firebase e arquivo/options Android corretos; mesma identidade UID.
- Assinatura válida e backups; sem chave debug em release.
- Google login nativo, e-mail/senha e gate de acesso nativo homologados.
- OAuth externo, câmera no navegador e retomada no app: callback atual continua
  voltando ao PWA, sem nova integração/deep link inventado nesta branch.
- Painel, limite de histórico, áudio com toque, desconexão, limpeza e logout.
- REDE Pausada; não acionar Scheduler. Manter histórico ao desconectar.
- Permissões finais, diferentes Androids/telas, splash, ícone e acessibilidade.
- Exclusão de conta, páginas legais aprovadas, demo isolada e screenshots.
- Conta Play, declaração de dados, testes exigidos e upload somente em nova missão.

Fontes oficiais: [Flutter Android release](https://docs.flutter.dev/deployment/android),
[Firebase Android](https://firebase.google.com/docs/android/setup),
[Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html).
