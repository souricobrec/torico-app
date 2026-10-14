# TORICO — APK release e teste físico Android

## Atualização de login nativo — 13/10/2026

Branch `feature/android-current-login`: Android agora usa login oficial e PilotGate,
com e-mail/senha preservado, Google nativo e allowlist UID/e-mail verificado.
Análise aprovada, **52 testes aprovados**, AAB release gerado em 432,6 s,
estrutura validada pelo bundletool e APK universal validado pelo apksigner.
Sem login/OAuth real ou instalação executados nesta missão.

| Artefato novo | Caminho / dados |
|---|---|
| AAB | `C:/Users/CRZ/Documents/ChatGPT/TORICO/build/app/outputs/bundle/release/app-release.aab` |
| Tamanho / SHA256 AAB | 63.875.809 bytes / `27F7716F29ADAF85315F781E8CCE38DE6C10F94FAAAC0F8518E99E87A724228C` |
| APK de teste atualizado | `C:/Users/CRZ/Documents/ChatGPT/TORICO/build/app/outputs/apk/release-test/torico-native-login-release.apk` |
| Tamanho / SHA256 APK | 63.594.829 bytes / `7C694909CFBDDC3E6A858B1070EFD5E676F14F7E7BE2BEA21F8110C1BFD5075B` |
| APKS | `build/app/outputs/bundle/release/torico-native-login-release.apks` |
| Identidade | br.com.meutorico.app, versão 1.0.0 (versionCode 2), minSdk 24, targetSdk 36 |
| Assinatura | v2/v3 válidas; SHA256 certificado `8C15309583E8FD117A638EF348C774AEFC98D7713993C086C83FD4640D0389A6` |

Allowlist do novo build preserva UID e e-mails atuais: sourico.br.ec@gmail.com,
comercial.artcodex@gmail.com e UID 4EGxLrjY5gPNVEFhibfG6dSBCnF3. Builds sem defines
não liberam usuários. Controle de UI não substitui autorização backend/Firestore.
Ver comando/causa em `docs/android-login-alignment.md`.

Permissões atuais: INTERNET, ACCESS_NETWORK_STATE, USE_BIOMETRIC, USE_FINGERPRINT,
READ_GSERVICES e br.com.meutorico.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION.
As duas novas permissões vêm de androidx.biometric:biometric:1.1.0 no manifest
mesclado das dependências Google/Credential Manager; revisar antes da loja.
Não foi adicionada captura facial/câmera ao TORICO.

Para instalar sem apagar dados, em dispositivo/emulador já autorizado:

```powershell
adb -s <SERIAL> install -r "C:\Users\CRZ\Documents\ChatGPT\TORICO\build\app\outputs\apk\release-test\torico-native-login-release.apk"
```

Validar Google real com Google Services, seleção/cancelamento, e-mail/senha,
mesmo UID, usuário autorizado/não autorizado, sessão anterior e logout/limpeza.
O JSON local tem client Web (type 3), mas zero entradas Android type 1 na lista
OAuth; checar cadastro package/SHA se houver erro de configuração, sem criar
credenciais nesta missão. OAuth Mercado Pago/retorno nativo continuam pendentes.

Artefatos anteriores preservados em `build/android-release-backups/pre-native-login/`.
As seções de artefatos e geração a seguir registram o **APK anterior**; usar o
novo caminho acima para verificar o login corrigido.

Preparado em 12/10/2026 na branch `feature/android-store-build`, a partir do
AAB do commit `eeb4495`. Não houve recompilação Flutter, deploy, publicação,
criação de conta ou alteração de serviços/configurações remotas.

## Artefatos locais

| Item | Caminho / valor |
|---|---|
| AAB de origem | `build/app/outputs/bundle/release/app-release.aab` |
| SHA256 AAB conferido | `76E4DBA3870406DBFCB67B1AF41FDBF225C0A4AF6D85A4F56E631ECA0C8728CB` |
| Conjunto APKs universal | `build/app/outputs/bundle/release/torico-release.apks` |
| APK instalável | `build/app/outputs/apk/release-test/torico-universal-release.apk` |
| APK em caminho absoluto | `C:/Users/CRZ/Documents/ChatGPT/TORICO/build/app/outputs/apk/release-test/torico-universal-release.apk` |
| Tamanho APK | 63.172.773 bytes / 60,25 MiB |
| SHA256 APK | `F1C3E6D8BE2283BE32E466AB6D63EF48396420DB519ED04DB477BCD1D4D04930` |
| applicationId / nome | `br.com.meutorico.app` / TORICO |
| versionCode / versionName | 1 / 1.0.0 |
| minSdk / targetSdk | 24 / 36 (Android 7.0 ou posterior) |

APKs e AAB ficam ignorados pelo Git. Não anexar o APK ao repositório nem publicar
na Google Play nesta etapa. O APK universal contém todas as arquiteturas do AAB;
o tamanho não corresponde ao download otimizado da Play.

## Geração e assinatura

Foi usado bundletool oficial **1.18.3**, já disponível em:

`C:/Users/CRZ/.codex/visualizations/2026/10/01/01a0f9e6-bde9-7612-a5c8-8e611bb3a4a9/torico-android-firebase-aab/bundletool-all-1.18.3.jar`.

SHA256 da ferramenta conferido:
`A099CFA1543F55593BC2ED16A70A7C67FE54B1747BB7301F37FDFD6D91028E29`.

O helper local `BuildToricoApks.java`, na mesma pasta de validação, lê
`android/key.properties` como Java Properties e chama bundletool em memória:
`build-apks --mode=universal`, com o AAB, saída `.apks` e assinatura release.
As senhas não entram nos argumentos do processo do sistema, não são impressas
nem gravadas em arquivos temporários. O helper não contém credenciais.
Depois foi extraído somente `universal.apk` do `.apks`, para o caminho acima.

`apksigner verify --verbose --print-certs` retornou código 0 e `Verifies`:
assinaturas v2 e v3 válidas, um assinante, certificado da chave de upload local.

- SHA-1 certificado: `7B:86:78:7C:A9:44:0C:AE:AC:09:B5:22:3D:E5:6F:B1:15:6C:20:8F`.
- SHA-256 certificado: `8C:15:30:95:83:E8:FD:11:7A:63:8E:F3:48:C7:74:AE:FC:98:D7:71:39:93:C0:86:C8:3F:D4:64:0D:03:89:A6`.

`aapt2 dump badging` e `aapt2 dump xmltree --file AndroidManifest.xml` confirmaram
identidade, SDKs e permissões diretamente no APK final:

- `android.permission.INTERNET`.
- `android.permission.ACCESS_NETWORK_STATE`.
- `com.google.android.providers.gsf.permission.READ_GSERVICES`.
- `br.com.meutorico.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.

Sem permissão de câmera, microfone, localização ou armazenamento no manifest.
Não houve fallback para assinatura debug. Nenhum teste de instalação ou login
em aparelho foi executado nesta missão.

## Instalação manual

1. Usar aparelho de teste autorizado com Android 7.0 ou posterior.
2. Transferir o APK por meio privado e conferir o SHA256 antes de instalar.
3. Permitir instalação dessa origem somente durante o teste; desabilitar depois.
4. Se existir app com mesmo package e assinatura diferente, registrar o conflito;
   não desinstalar nem limpar dados automaticamente.
5. Instalar, abrir e registrar modelo, versão Android e resultado de cada item.
   Não capturar senhas, tokens ou dados financeiros nas evidências.

Opcional, com Android SDK/ADB local e USB autorizado:

```powershell
adb install -r "C:\Users\CRZ\Documents\ChatGPT\TORICO\build\app\outputs\apk\release-test\torico-universal-release.apk"
```

Não foi executado `adb install`, login ou OAuth nesta preparação.

## Checklist físico — ainda não executado

| Teste | Verificação esperada |
|---|---|
| Instalar APK | Instala sem erro; nome e ícone TORICO |
| Abrir app / tela inicial | Layout legível, teclado e rolagem funcionam |
| Login e-mail/senha | Usuário de teste entra e mantém seu UID existente |
| Login Google | Registrar resultado; implementação nativa ainda não homologada |
| Controle piloto | Gate nativo implementado; validar UID permitido, e-mail verificado autorizado, não autorizado e lista vazia no novo APK |
| Painel | Total do dia atual; zero sem vendas hoje é válido |
| Histórico | Básico mostra até 10 vendas recentes; histórico existente preservado |
| Conta | Logout somente em Conta; textos e status coerentes |
| Limpar dados locais | Encerra sessão e limpa dados locais; integrações na nuvem permanecem |
| Sair | Encerra sessão; não desconecta Mercado Pago |
| Conectar Mercado Pago | Browser externo oficial; TORICO não solicita senha Mercado Pago |
| Retorno OAuth | Registrar retorno ao PWA e retomada manual no app; deep link nativo pendente |
| Desconectar Mercado Pago | Somente com consentimento do titular; confirmar histórico preservado |
| Som de venda | Ativar/testar; nova venda aprovada, sem som em duplicada/recusada |
| Sem internet | Mensagem coerente, sem perda de dados nem travamento |
| Fechar/reabrir | Sessão e preferências coerentes; verificar conexão novamente |
| Fontes de venda | Mercado Pago conforme conexão real; REDE Pausada; demais Em preparação |

## Pendências antes de distribuição a pilotos / teste fechado

- Controle piloto nativo corrigido na branch `feature/android-current-login`:
  Android usa PilotGate e a mesma validação UID/e-mail verificado. Builds sem
  allowlist não liberam usuários; homologar em execução e manter proteção de
  backend/Firestore independente do gate de UI.
- Login Google Android implementado com google_sign_in oficial e troca do ID token
  por credencial Firebase; web mantém signInWithPopup. Homologação real ainda
  pendente, sem alterações Firebase Auth/Console.
- Callback Mercado Pago continua retornando ao PWA oficial; deep link/retorno
  automático ao Android ainda pendente. Testar retomada manual sem prometer
  conclusão automática nativa.
- Instalação e todos os itens físicos acima ainda pendentes; APK gerado e
  assinatura válida não significam homologação funcional em aparelho.
- Segurança OAuth previamente registrada (autenticação do início, exclusividade
  da conta vinculada e consumo único do state) segue fora desta geração de APK.
- Antes da Play: seguir `docs/google-play-checklist.md`, dados de revisão,
  privacidade, exclusão de conta e cadastro de fingerprints Play App Signing.

Nenhum backend, OAuth client, webhook, Firebase Console, Cloud Run, DNS, secrets,
REDE/Scheduler ou dado de usuário foi alterado. Nenhum artefato binário foi
commitado/enviado. Arquivos privados de assinatura/configuração permanecem locais.
