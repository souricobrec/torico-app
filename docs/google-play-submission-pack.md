# TORICO — pacote sugerido para Google Play

Preparado em 13/10/2026. Idioma pt-BR. Revisão de `store-listing-draft.md`.
Somente documentação: não cria conta/app na Console, não envia artefatos e não
publica. Textos finais sugeridos, condicionados à homologação do Android e
aprovação do titular. As respostas de políticas abaixo ainda não são declarações
prontas para envio.

## 1. Ficha sugerida

| Campo | Conteúdo sugerido |
|---|---|
| Nome | TORICO |
| Descrição curta | Acompanhe as vendas do dia e as últimas vendas aprovadas do Mercado Pago |
| Categoria | Aplicativo / Negócios |
| Tags | Buscar opções disponíveis relacionadas a gestão de negócios e produtividade; selecionar somente tags que existam na Console e descrevam o app |
| Suporte público | sourico.br.ec@gmail.com (provisório; confirmar monitoramento pelo titular) |
| Site institucional | https://www.meutorico.com.br — validar conteúdo público antes de cadastrar |
| App web | https://app.meutorico.com.br — não confundir com a ficha Android |
| Política de privacidade pública | https://www.meutorico.com.br/privacidade — publicada em 13/10/2026; revisão humana de retenção/obrigações ainda pendente |
| Termos de uso | https://www.meutorico.com.br/termos |
| Suporte | https://www.meutorico.com.br/suporte |
| Solicitação externa de exclusão | https://www.meutorico.com.br/exclusao-de-conta — instruções e contato por e-mail, atendimento manual; não executa exclusão automática |

TORICO tem 6 caracteres. A descrição curta cabe no limite de 80 caracteres.
Categoria e tags são escolhas editoriais; não definem respostas sobre recursos
financeiros. Preço, países e condições Plus exigem decisão separada; não foram
definidos nesta preparação.

### Descrição longa — texto sugerido para copiar após homologação

Seu negócio vendendo. Onde você estiver.

O TORICO ajuda comerciantes a acompanhar as vendas do negócio pelo celular,
com um painel do dia e uma visão simples das vendas recentes.

Conecte sua conta Mercado Pago pela autorização oficial do provedor e acompanhe
as vendas aprovadas recebidas pela integração.

Com o TORICO você pode:

- Consultar o total de vendas do dia atual.
- Ver as últimas 10 vendas no plano Básico, da mais recente para a mais antiga,
  com valor, plataforma, data e status.
- Ativar o som de novas vendas no dispositivo enquanto o painel estiver aberto.
- Gerenciar e desconectar Mercado Pago, mantendo o histórico já salvo.
- Sair da conta ou limpar dados locais do dispositivo sem remover as integrações
  salvas na nuvem.

O TORICO não solicita sua senha do Mercado Pago. A conexão é feita por OAuth
oficial: você autentica e autoriza o acesso diretamente no ambiente do Mercado
Pago. O login TORICO e a conta Mercado Pago podem usar e-mails diferentes.

Mercado Pago é a integração disponível nesta fase. REDE está pausada e as demais
integrações estão em preparação. O TORICO acompanha vendas; não inicia pagamentos
e não substitui os registros oficiais do provedor.

O acesso está em fase controlada. Disponibilidade de recursos e condições de
outros planos serão informadas antes de qualquer contratação.

Suporte: sourico.br.ec@gmail.com.

**Nota editorial, não copiar na ficha:** texto abaixo de 4.000 caracteres. Não
promete Google login nativo homologado, notificações com app fechado, exportação,
relatórios completos, vínculo institucional com Mercado Pago ou preços novos.
Revisar cada funcionalidade contra o Android testado antes de usar.

### Texto para suporte/reviewer

O TORICO usa Firebase para autenticar o usuário. A autorização Mercado Pago ocorre
no navegador oficial do provedor por OAuth. O TORICO não recebe a senha Mercado
Pago; tokens de integração são armazenados criptografados no backend.
Para revisão, será necessário fornecer acesso dedicado às telas do app sem exigir
conta financeira pessoal do reviewer ou verificação facial. Esse acesso demo
ainda não foi criado. Não enviar senha ou token no Git.

## 2. Estado técnico e bloqueios

- AAB e APK release já gerados e assinados: `br.com.meutorico.app`, targetSdk 36,
  minSdk 24. Build atual com ícone adaptativo corrigido em 13/10/2026:
  versão 1.0.0 (3), APK
  `build/app/outputs/apk/release-test/torico-icon-fixed-release.apk`; AAB em
  `build/app/outputs/bundle/release/app-release.aab`. Dados/hashes em
  `docs/android-physical-test.md`; sem envio à Play.
- Pixel 8: timeout; Pixel 4: instabilidade de CPU/memória; emulação encerrada.
  APK/AAB válidos, mas não homologados em execução. Teste físico pendente.
- Google login Android implementado com google_sign_in + Firebase na branch
  `feature/android-current-login`; execução real ainda precisa homologação.
- Controle piloto Android alinhado ao PilotGate com allowlist UID/e-mail verificado;
  testes e build documentados em `docs/android-physical-test.md`. Homologar no APK.
- Callback Mercado Pago retorna ao PWA; retorno automático nativo/deep link pendente.
- Exclusão de conta/dados no app ainda pendente. Página externa pública publicada,
  com solicitação por e-mail; concluir procedimento operacional de eliminação,
  retenção e atendimento antes da submissão. A página não homologa esse processo.
- Pendências OAuth previamente registradas: autenticação Firebase no início da
  conexão, exclusividade da conta vinculada e consumo único do state.
- Verificar bibliotecas nativas 64-bit/16 KB, recuperação de senha, rede, áudio e
  ciclo de vida em hardware adequado. Não declarar aprovação pelo build sozinho.
- Auditar USE_BIOMETRIC/USE_FINGERPRINT acrescentadas pelas dependências nativas
  Google/AndroidX biometric; ausência de câmera não elimina a revisão de SDKs.

## 3. Instruções para futuros testadores fechados

**Ainda não há link de adesão nem versão distribuída pela Play.** Usar o texto
abaixo somente após autorização, correções e configuração da faixa de teste:

1. Receba do responsável o link privado de adesão e use a conta Google convidada.
2. Aceite participar e instale pela Play usando essa mesma conta. Não usar o
   link do PWA como substituto do teste Android.
3. Abra TORICO e entre com a identidade de teste autorizada. A lista de testadores
   Play e a autorização dentro do TORICO são controles distintos.
4. Confira Painel, Histórico (máximo 10 vendas no Básico), Plano e Conta.
5. Ative o som de teste; registre comportamento sem internet e ao fechar/reabrir.
6. Teste sair e entrar novamente. Limpeza local encerra a sessão e não remove a
   integração na nuvem. Execute limpeza/desconexão somente com autorização.
7. Mercado Pago real é opcional nesta primeira revisão; não use conta de terceiro,
   não compartilhe senha e não gere venda/pagamento sem consentimento explícito.
   Se autorizado, registre navegador aberto e destino do retorno OAuth.
8. Envie feedback privado com versão, Android/modelo, passos e resultado. Oculte
   e-mails, UID, vendas pessoais, tokens e códigos em screenshots/logs.
9. Para contas pessoais abrangidas pela regra, manter inscrição contínua por
   pelo menos 14 dias com mínimo de 12 testadores; coletar feedback real e só
   depois solicitar acesso à produção. A condição não garante aprovação.

Se houver crash, acesso indevido ou associação incorreta de conta, interromper
o fluxo e informar o responsável. Não alterar serviços para contornar o problema.

## 4. Checklist para cadastro futuro na Console

- [ ] Resolver bloqueios nativos/de segurança e obter testes em aparelho.
- [ ] Aprovar nome, textos, categoria/tags e suporte monitorado.
- [ ] Aprovar pessoa física como titular, preparar identidade/contatos privados e
  verificar elegibilidade do tipo de conta para os recursos efetivos.
- [ ] Criar conta apenas em missão autorizada; cumprir verificações exigidas,
  inclusive dispositivo quando solicitado. Nenhuma conta foi criada aqui.
- [ ] Criar aplicativo TORICO, pt-BR, tipo aplicativo; decidir distribuição/preço
  e países com titular. Não executar nesta missão.
- [ ] Configurar Play App Signing mantendo chave de upload privada; cadastrar
  fingerprints de distribuição Firebase em missão própria autorizada.
- [ ] Preencher ficha com assets aprovados e URLs públicas funcionais.
- [ ] Completar acesso ao app com credenciais reviewer privadas, instruções e
  dados demo; reviewer deve conseguir revisar áreas protegidas.
- [ ] Completar política de privacidade, Data safety, exclusão, público-alvo,
  anúncios, recursos financeiros e questionário IARC fiel ao conteúdo.
- [ ] Revalidar target API/políticas vigentes no dia e integridade/compatibilidade
  do AAB, permissões, versão e bibliotecas nativas.
- [ ] Configurar faixa fechada, testadores e release somente quando autorizado;
  acompanhar feedback/relatório pré-lançamento e documentar correções.
- [ ] Solicitar acesso à produção quando elegível; publicação requer nova missão.

## 5. Respostas prováveis — confirmar antes de enviar

Inventário preliminar baseado nos documentos e dependências locais. Firebase Auth,
Firestore, backend e SDKs participam da coleta; serviço de terceiro não significa
"nenhum dado coletado". Auditar campos/payloads, logs e bibliotecas transitivas.

| Pergunta / tipo | Resposta provável | Confirmação necessária |
|---|---|---|
| Coleta de dados | Sim | Inventário completo por tipo e SDK |
| E-mail / identificadores de usuário | Coletados para conta, acesso e associação | UID, e-mail verificado, IDs do provedor; obrigatoriedade por fluxo |
| Nome / foto | Possíveis no login Google | Confirmar dados recebidos, persistidos e usados; não marcar ausentes sem verificar |
| Informações financeiras / histórico de compras | Dados de transação/vendas coletados | Classificar histórico e outros dados financeiros conforme campos reais, inclusive dados do pagador; não presumir saldo/cartão |
| Senha Mercado Pago | Não capturada pelo TORICO | OAuth oficial; não confundir tokens com senha |
| Fotos/vídeos/câmera/biometria | TORICO não implementa captura facial neste escopo | Verificação externa do Mercado Pago não implica permissão de câmera do app; revisar qualquer SDK futuro |
| Diagnósticos / IDs de dispositivo | A determinar | Infraestrutura, logs, SDKs e dependências transitivas; ausência de Analytics/Crashlytics diretos não prova ausência de toda coleta |
| Atividade no app | A determinar | Auditar eventos e logs; não assumir analytics implementado |
| Preferências locais / áudio | Preferência local | Confirmar se permanece no dispositivo e se não é enviada |
| Compartilhamento | A determinar por destinatário e finalidade | Avaliar Google/Firebase como prestadores e Mercado Pago; aplicar exceções de prestador/transferência iniciada pelo usuário somente quando cabíveis, sem marcar tudo como não compartilhado |
| Criptografia em trânsito | Provavelmente sim, com HTTPS/Firebase | Confirmar todos os fluxos Android, SDKs e logs; criptografia de tokens em repouso não responde essa pergunta |
| Coleta obrigatória/opcional | Conta necessária; integração voluntária | Preencher por tipo, login e recurso; suporte depende do que usuário envia |
| Finalidades | Funcionalidade, gerenciamento de conta; segurança quando aplicável | Não marcar publicidade/analytics sem evidência |
| Exclusão de conta | Fluxo completo ainda não disponível | Página web externa publicada em /exclusao-de-conta com solicitação manual; implementar opção no app e validar eliminação; logout/limpeza/desconexão não substituem exclusão |
| Retenção após exclusão | Ainda não definida integralmente | Estabelecer eliminação de conta, vendas, tokens, logs/backups e exceções justificadas; política coerente |
| Público-alvo | Sugerido: adultos, 18+, comerciantes | Titular confirmar; não direcionado a crianças; IARC é questionário distinto, não inventar classificação |
| Anúncios | Provável: não contém anúncios | Nenhum SDK publicitário direto no pubspec revisado; confirmar binário/dependências/comportamento |
| Recursos financeiros | Declaração obrigatória; considerar "Other" para acompanhamento de vendas | Não é crédito, investimento, carteira nem inicia transferência; a integração financeira exige avaliação da taxonomia efetiva, não marcar "nenhum" automaticamente |
| Compras/Plus | Condições futuras não definidas | Sem preço/promessa nova; avaliar política de pagamentos antes de vender recursos digitais |

As respostas devem cobrir o conjunto de versões/faixas distribuídas conforme a
regra Google, inclusive SDKs. Não alegar revisão independente de segurança.
Documentos em `docs/legal/` são os rascunhos de origem. Páginas públicas derivadas
foram publicadas em 13/10/2026, identificando Elton Cruz como responsável, conforme
informado pelo titular. A publicação não significa revisão jurídica ou conformidade
Google Play completa; prazos de retenção e procedimentos de exclusão seguem pendentes.

## 6. Materiais gráficos faltantes

| Material | Estado | Ação necessária |
|---|---|---|
| Ícone Play 512×512 | Gerado: `store-assets/google-play/icon-512.png`, PNG RGBA, 488.462 bytes | Aprovação editorial; asset Play preservado, independente das camadas Android |
| Ícone launcher Android | Corrigido: fundo navy, T oficial central e camadas adaptativas/monochrome, PNGs legados | Testar launcher/recents no emulador e aparelho; asset Play separado e preservado; ver `docs/android-adaptive-icon.md` |
| Logo fonte | `assets/images/torico_logo.png`: 2172×724, 1.423.017 bytes | Referência de identidade, não substitui ícone quadrado |
| Feature graphic 1024×500 | Gerada: `store-assets/google-play/feature-graphic-1024x500.png`, PNG RGB sem alpha, 82.248 bytes | Aprovação editorial; navy/dourado, slogan oficial, sem promessa adicional |
| Prévias web editoriais | 5 PNGs 1080×1920 em `store-assets/google-play/provisional-web/` | Reconstruções HTML/CSS offline baseadas no layout Flutter/PWA, com selo de demonstração; não são capturas do app em execução |
| Screenshots Android reais | Ainda pendentes; emulador bloqueado por hardware | Substituir prévias por capturas reais de login, Painel, Histórico, Plano e Conta em aparelho homologado, com dados fictícios |
| Dados de demonstração | Não criados | Planejar dados isolados/fictícios, sem usuário real ou alterações em produção |

Não usar prévias editoriais como prova de execução Android ou como screenshots
nativos finais. Materiais gráficos foram preparados em 13/10/2026, sem gerar novo
APK/AAB, deploy ou publicação. REDE Pausada; outras plataformas Em preparação.
Detalhes, origem, reprodução e tamanhos: `store-assets/google-play/README.md` e
`manifest.json`. Teste físico e homologação nativa continuam pendentes.

## 7. Antes de criar o app: decisões e pendências manuais

O pacote textual está preparado; o produto **não está pronto para submissão**.
Faltam homologação nativa em aparelho, correções de acesso/OAuth, exclusão de conta
no app e processo manual validado, revisão humana da política pública, auditoria
Data safety, reviewer/demo, gráficos/screenshots
e decisão do titular sobre conta/países/preço. A criação de rascunho na Console
não substitui esses requisitos. Não executar cadastro/publicação nesta missão.

## Referências oficiais consultadas em 13/10/2026

- [Ficha e assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).
- [Data safety: tipos, coleta e compartilhamento](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
- [Exclusão de conta](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
- [Recursos financeiros](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en).
- [Teste fechado para contas pessoais](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
- [Política de dados](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).

Revalidar regras no dia do cadastro. Nenhuma conta, binário, configuração de
assinatura, Firebase, backend, OAuth, secret ou Scheduler foi alterado neste pacote.

