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

## Firebase — cadastro manual e validação local

Na migração anterior, o JSON registrava `com.example.vendaon` e foi removido do
rastreamento Git. Nesta missão o titular substituiu o arquivo local por uma
configuração oficial correspondente a `br.com.meutorico.app`. O arquivo permanece
ignorado; nenhum cadastro, usuário ou configuração remota foi alterado pelo Codex.

Dados públicos validados e usados em `DefaultFirebaseOptions.android`:

| Campo | Valor |
|---|---|
| project_id | torico-ca479 |
| package_name | br.com.meutorico.app |
| mobilesdk_app_id | 1:16783123127:android:a0f5f77bcdd6d6e48e6332 |
| project_number / messagingSenderId | 16783123127 — mantido |
| storage_bucket | torico-ca479.firebasestorage.app — mantido |
| apiKey Android | Primeira chave pública válida do client correspondente, como selecionada pelo Google Services |

O JSON possui duas chaves públicas. A seleção segue o
[plugin oficial Google Services](https://github.com/google/play-services-plugins/blob/main/google-services-plugin/src/main/kotlin/com/google/gms/googleservices/GoogleServicesTask.kt),
não exige artificialmente que exista apenas uma. Foi verificada a ausência de
`private_key`, `client_secret`, `refresh_token`, `password`/senha, também nos
objetos aninhados. Somente appId e apiKey Android mudaram em firebase_options.dart.
Web (incluindo authDomain), iOS/macOS, projeto, bucket e sender ID foram preservados.
O JSON local não será versionado.

Procedimento de cadastro para referência (o titular forneceu a configuração;
não executar novamente nem apagar o app anterior):

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
   Nesta validação a constante Android foi atualizada com a configuração fornecida.
   Manter opções web, projeto, Auth e usuários intactos.
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

Nenhum keystore ou senha foi gerado pelo Codex. O titular criou localmente
`C:/Users/CRZ/.torico-signing/upload.p12` e preencheu `android/key.properties`.
Ambos foram lidos apenas para validação, sem imprimir senhas ou alterar os arquivos.
PKCS12, acesso à chave privada e storeFile foram verificados. Fingerprints do
certificado local correspondem aos informados pelo titular como cadastrados:

- SHA-1: `7B:86:78:7C:A9:44:0C:AE:AC:09:B5:22:3D:E5:6F:B1:15:6C:20:8F`.
- SHA-256: `8C:15:30:95:83:E8:FD:11:7A:63:8E:F3:48:C7:74:AE:FC:98:D7:71:39:93:C0:86:C8:3F:D4:64:0D:03:89:A6`.

O Gradle release continua usando somente signingConfigs.release; não há fallback
debug. Não foi alterado Firebase Auth nem registrado fingerprint pelo Codex.
Exemplo com placeholders para configuração futura:
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

Resultado histórico da preparação anterior (`2f26475`): clean e pub get concluídos, análise sem problemas,
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

## Resultado desta validação — 12/10/2026

Após a substituição manual do JSON pelo titular, a sequência solicitada concluiu:

| Etapa | Resultado |
|---|---|
| flutter clean | Sucesso |
| flutter pub get | Sucesso, sem atualização de versões |
| flutter analyze | Sem problemas |
| flutter test | 47 testes aprovados |
| flutter build appbundle --release | Sucesso; Gradle em 1.990,5 segundos |

O primeiro build instalou componentes locais ausentes, mantendo as versões
exigidas: NDK 28.2.13676358, Build-Tools 36.0.0, Platforms 36/35/34 e CMake
3.22.1. As licenças já estavam aceitas no SDK; não foi executado comando de
aceitação de licenças. Não houve downgrade, retry de build ou deploy.

- AAB: `C:/Users/CRZ/Documents/ChatGPT/TORICO/build/app/outputs/bundle/release/app-release.aab`.
- Tamanho: **63.506.004 bytes (60,56 MiB)**.
- SHA256: `76E4DBA3870406DBFCB67B1AF41FDBF225C0A4AF6D85A4F56E631ECA0C8728CB`.
- applicationId: **br.com.meutorico.app**.
- minSdk efetivo: **24**; targetSdk efetivo: **36**.
- `jarsigner -verify`: código 0, `jar verified`; certificado do AAB com SHA-1
  e SHA-256 idênticos aos da chave de upload acima.
- `bundletool 1.18.3 validate`: código 0; estrutura válida. Ferramenta oficial
  baixada fora do repositório, SHA256 verificado contra o digest da release.
  `bundletool dump manifest --module=base` confirmou os mesmos SDKs, identificador
  e permissões diretamente do AAB.

Permissões do manifest release empacotado em
`build/app/intermediates/packaged_manifests/release/processReleaseManifestForPackage/AndroidManifest.xml`:

- `android.permission.INTERNET`.
- `android.permission.ACCESS_NETWORK_STATE`.
- `com.google.android.providers.gsf.permission.READ_GSERVICES`.
- `br.com.meutorico.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (também declarada
  pelo app como permissão interna signature).

Não há câmera, microfone, localização ou armazenamento nesse manifest.
Avisos registrados: audioplayers_android ainda aplica Kotlin Gradle Plugin,
compatibilidade futura com Built-in Kotlin pendente; plugins Java usam APIs
obsoletas/operações não verificadas. Nenhuma dependência foi alterada para ocultá-los.
O jarsigner também informa certificado autoassinado, ausência de timestamp e
diferenças de leitura JarFile/JarInputStream na ordem do manifest/entradas; sua
verificação retorna sucesso, assim como a validação estrutural do bundletool.
Isso não substitui teste de instalação Android.

AAB não é instalado diretamente: usar bundletool para gerar APKs compatíveis,
assinados, e instalar em dispositivo autorizado. Não enviar AAB à Play nesta missão.

## Testes físicos / pendências Google Play

- Firebase Android e assinatura local validados; homologar login em aparelho e
  registrar também fingerprints Play App Signing quando houver distribuição.
- Manter backup privado da assinatura; nenhuma chave/JSON foi versionado.
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
