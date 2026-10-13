# TORICO — preparação para lojas

Revisão: 12/10/2026. Base inspecionada: `visual-pre-lojas`, `4ac50de`.
Branch desta preparação: `feature/store-readiness`.

Atualização Android: `feature/android-store-build`, baseada em `a379638`.
Android recebeu identificador definitivo e configuração de assinatura privada;
o cadastro Firebase e o artefato release ainda dependem das etapas descritas em
[android-release-build.md](android-release-build.md). iOS permanece inalterado.

**Preparação documental concluída; ainda não pronto para submissão nativa.**
O PWA validado não demonstra que Android/iOS estejam homologados. Esta missão
não cria contas de desenvolvedor ou demo, não publica, não muda Firebase,
backend, OAuth, secrets, DNS ou dados. REDE/Scheduler não foram acionados.

## Configuração inspecionada

| Item | Evidência no repositório | Decisão / pendência |
|---|---|---|
| Nome | AndroidManifest.xml, Info.plist e MaterialApp: TORICO | Mantido |
| Versão | pubspec.yaml: 1.0.0+1 | Incrementar build number antes de cada upload |
| Android | android/app/build.gradle.kts: namespace/applicationId br.com.meutorico.app | Decisão definitiva aplicada na branch Android; MainActivity alinhada |
| Firebase Android | JSON antigo local para com.example.vendaon, removido do Git | Cadastro novo e opções Firebase Android ainda necessários, manualmente |
| iOS | project.pbxproj: com.example.vendaon; testes .RunnerTests | Escolher bundle ID definitivo e atualizar juntos os targets |
| Firebase iOS | firebase_options.dart lança UnsupportedError para iOS; sem GoogleService-Info.plist | Configuração iOS ausente; bloqueia inicialização |
| Assinatura Android | release usa signingConfigs.release; exige key.properties privado | Keystore/configuração não gerados; não há fallback debug |
| SDK Android local | FlutterExtension.kt: compile/target 36, min 24, NDK 28.2.13676358 | Valores herdados; confirmar no APK/AAB mesclado |
| iOS mínimo | project.pbxproj: 13.0; podspecs locais firebase_core 4.10.0/firebase_auth 6.5.2 exigem 15.0 | Incompatibilidade; alinhar deployment target em todos os targets/configurações no Mac |
| Google login | AuthService.loginWithGoogle usa signInWithPopup | Implementação web; adaptar e testar login nativo sem alterar UID/vínculos |
| Gate piloto | DomainBlockService.shouldBlock retorna false fora da web | Allowlist do PWA não protege o binário nativo; definir controle equivalente antes de distribuir |
| OAuth Mercado Pago | Launcher externo; retorno tratado em main somente se kIsWeb | Callback atual volta ao PWA; retorno nativo/deep links e retomada precisam de missão separada |
| Ícone fonte | assets/images/app_icon.png: 1254×1254 RGB, marca T navy/dourado | Identidade preservada; revisar máscara/adaptive icon e exportações |
| Ícones gerados | Android xxxhdpi 192×192; iOS marketing 1024×1024 RGB sem alpha | Validar todos os tamanhos em dispositivos; não regenerados nesta missão |
| Splash Flutter | SplashScreen usa logo e slogan navy/dourado | Já existe; revisar tamanhos em telas pequenas |
| Splash nativo | Android launch_background branco/default; iOS LaunchImage 1×1 | Personalização nativa pendente, inclusive Android 12+ |
| API | ApiConfig produção: https://api.meutorico.com.br | Preservada |
| Exclusão de conta | Logout, limpeza local e desconexão não excluem usuário/histórico | Fluxo de exclusão de conta/dados ainda precisa ser implementado |

Decisão do titular aplicada ao Android: `br.com.meutorico.app`. Isso não significa
reserva na Play nem cadastro Firebase concluído. Identificador iOS ainda pendente.
Coordenar Firebase, SHA de assinatura, login e provisioning sem migrar/excluir
usuários existentes. Ver [build Android](android-release-build.md).

## Permissões e dados

O manifest principal não tinha INTERNET; esta branch adiciona somente essa
permissão normal para a rede funcionar em release. Debug/profile já a declaravam.
Não foram encontradas permissões explícitas de câmera, microfone, localização,
contatos ou armazenamento amplo no manifest principal, nem usage descriptions
equivalentes no Info.plist. PROCESS_TEXT é consulta de atividade, não acesso a
arquivos/contatos. Auditar também o manifest **mesclado** e os SDKs no artefato.
Não adicionar câmera ao TORICO só porque Mercado Pago pode pedi-la: a verificação
ocorre no navegador oficial externo. Nenhuma permissão sensível foi adicionada.

Inventário preliminar para Data safety/App Privacy (validar no binário final):

| Dados | Uso | Destino / cuidado |
|---|---|---|
| E-mail, UID, nome/foto se fornecidos pelo Google | Login, identidade e suporte | Firebase Authentication; vinculados ao usuário |
| Senha TORICO ou credencial de login | Autenticação | Processada pelo Firebase Auth; não incluir em logs ou formulários de vendas |
| ID da conta Mercado Pago e tokens OAuth | Vincular integração e consultar eventos autorizados | Backend/Firestore privado; tokens criptografados, não públicos |
| ID, valor, status, plataforma, data/hora das vendas e totais | Painel e histórico | Firestore; informações comerciais/financeiras vinculadas à conta |
| Payloads de webhook/API e payer_id quando presente | Processamento/deduplicação | Podem incluir dados de terceiros; revisar minimização/retenção |
| IP, logs operacionais e dados técnicos dos SDKs | Segurança e funcionamento | Google Cloud/Firebase e provedores; auditar coleta efetiva e retenção |
| Preferência de áudio, cache de plataformas e total do dia | Experiência local | SharedPreferences; distinguir de dados enviados ao servidor |

Sem Analytics, Crashlytics ou SDK de anúncios listado no pubspec inspecionado.
Isso não autoriza declarar “nenhum dado coletado”: Firebase/Google/MP e logs
tratam dados. Auditar dependências e tráfego; distinguir coleta, compartilhamento
e exceções de prestadores nas definições de cada loja. Não declarar tracking ou
ausência dele sem concluir a auditoria. Desconectar não é excluir conta.

## Pessoa física e marca

A marca visível pode continuar TORICO, sujeita a disponibilidade/direitos.
Apple individual exibe o nome civil do titular como vendedor; não prometer
“TORICO” como razão social/vendedor. Google exige verificação e divulga campos
de identidade/contato conforme tipo de conta e regras aplicáveis. Confirmar
campos públicos antes de abrir contas, inclusive endereço quando exigido.
Não publicar CPF, documentos, telefone privado ou credenciais no Git.

Categoria inicial sugerida: **Negócios / Business**, pela função de acompanhamento
comercial. Confirmar categoria e declaração de recursos financeiros com as
lojas. TORICO não inicia pagamentos, não é banco nem oferece crédito neste
escopo. Isso não garante elegibilidade como pessoa física: se enquadrado em
serviço financeiro regulado, verificar exigência de entidade jurídica.
Classificação indicativa será resultado dos questionários, não escolha arbitrária
de “Livre”/4+. Produto destinado a comerciantes adultos, não voltado a crianças.

## Materiais preparados

- [Google Play](google-play-checklist.md) e [Apple](apple-store-checklist.md).
- [Textos iniciais](store-listing-draft.md).
- [Fluxo demo](store-demo-account.md), sem credenciais/usuários criados.
- [Privacidade — rascunho](legal/privacy-policy-draft.md).
- [Termos — rascunho](legal/terms-of-use-draft.md).
- [Resultados de validação](store-validation.md).

As políticas existentes no app e no site precisam ser conciliadas com os
rascunhos antes de publicar. `https://www.meutorico.com.br/privacidade`, `/termos`
e `/contato` são destinos **propostos**, não certificados como páginas legais
finais nesta missão. Publicar páginas HTTPS acessíveis sem login, informar URLs
reais nas lojas e adicionar uma rota específica de solicitação de exclusão.
Suporte provisório: sourico.br.ec@gmail.com. Confirmar atendimento desse canal.

## Ordem para próxima missão, sem execução aqui

1. Aprovar identificadores, titular responsável, contato e textos legais.
2. Resolver segurança OAuth antes de distribuir a usuários reais: validar ID
   Token no início da conexão, prevenir associação indevida/múltipla e consumir
   state/nonce uma única vez. Não corrigido nesta branch; estado PagBank é outro fluxo.
3. Implementar controle de acesso nativo e login Google nativo; configurar iOS
   e assinaturas em ambiente autorizado, preservando UIDs existentes.
4. Avaliar regra Apple 4.8 e oferecer login equivalente (normalmente Sign in
   with Apple), ou justificar exceção real; e-mail/senha sozinho não comprova conformidade.
5. Implementar exclusão de conta/dados com política de retenção e verificação
   de identidade; não executar exclusões nesta preparação.
6. Homologar OAuth externo/retomada nativa em dispositivos físicos, sem mudar
   callback/client nesta missão. Alinhar splash e adaptive icon.
7. Após autorização específica, preparar demo isolada e políticas públicas.
8. Preparar assinatura de distribuição/AAB/IPA e screenshots reais; revisar
   declarações, testes exigidos e submissão em missões futuras.

## Fontes oficiais consultadas em 12/10/2026

- [Identidade de conta Play](https://support.google.com/googleplay/android-developer/answer/13628312?hl=en).
- [Teste para conta pessoal](https://support.google.com/googleplay/android-developer/answer/14151465).
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
- [App Privacy](https://developer.apple.com/app-store/app-privacy-details/).
- [Inscrição Apple individual](https://developer.apple.com/programs/enroll/).
- [Review Apple: 2.1, 4.8 e 5.1.1](https://developer.apple.com/app-store/review/guidelines/).
- [Login federado Flutter/Firebase](https://firebase.google.com/docs/auth/flutter/federated-auth).

Reconsultar requisitos na data da submissão; documentação não garante aprovação.
