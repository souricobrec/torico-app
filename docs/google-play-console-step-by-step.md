# TORICO — operação futura na Google Play Console

Preparado em 13/10/2026. **Somente documentação: nenhuma ação na Console executada.**
Responsável: Elton Cruz. Marca: TORICO. Identificador: `br.com.meutorico.app`.

## 1. Entender o estado atual antes de começar

AAB/APK assinados e Firebase Android configurado. Páginas legais públicas e
materiais iniciais preparados. **Isso não significa que o Android esteja homologado
ou pronto para envio.** Criar conta/rascunho não exige afirmar conclusão dos testes;
envio para revisão/distribuição fechada deve aguardar os bloqueios abaixo.

| Pendência | Situação / ação |
|---|---|
| Teste físico | Pendente; Pixel 8 teve timeout e Pixel 4 ficou instável. Usar hardware adequado |
| Screenshots Android reais | Pendentes; imagens em provisional-web são reconstruções editoriais, não capturas do app |
| Google login nativo | Implementação atual web; homologar Android antes de anunciá-lo |
| OAuth/retorno nativo | Callback volta ao PWA; deep link/retomada Android precisa homologação |
| Controle piloto nativo | Gate atual protege a web; implementar/validar bloqueio Android |
| Exclusão dentro do app | Pendente; logout, limpeza e desconexão não substituem exclusão |
| Exclusão manual | Página externa existe; validar atendimento, eliminação e retenções |
| Revisão jurídica | Prazos, bases legais, prestadores/transferências e termos precisam revisão humana |
| Segurança OAuth | Pendências registradas de autenticação do início, exclusividade do vínculo e consumo único do state |
| Acesso reviewer | Preparar demo revisável e instruções; não criar usuário nem guardar senha no Git |

Não enviar as prévias editoriais como screenshots nativos finais. Não iniciar
teste com usuários reais antes de resolver os bloqueios de segurança/acesso.

## 2. Separar os arquivos locais

Raiz: `C:/Users/CRZ/Documents/ChatGPT/TORICO/`.

| Material | Caminho relativo à raiz | Uso |
|---|---|---|
| AAB release | `build/app/outputs/bundle/release/app-release.aab` | Artefato destinado ao upload futuro Play; não versionar |
| APK universal | `build/app/outputs/apk/release-test/torico-universal-release.apk` | Teste manual local; não substituir AAB no envio |
| Ícone | `store-assets/google-play/icon-512.png` | 512×512 PNG RGBA; aprovação visual |
| Feature graphic | `store-assets/google-play/feature-graphic-1024x500.png` | 1024×500 PNG RGB; aprovação visual |
| Prévias provisórias | `store-assets/google-play/provisional-web/01-login.png` até `05-conta-integracoes.png` | Referência editorial; substituir por capturas Android reais |
| Textos/declaratórios | `docs/google-play-submission-pack.md` | Base para ficha e respostas a validar |
| Metadados gráficos | `store-assets/google-play/manifest.json` | Dimensões/tamanhos das imagens |
| Testes | `docs/android-physical-test.md` e `docs/android-emulator-test.md` | Checklist e resultados/limitações |

AAB atual: 63.506.004 bytes, minSdk 24, targetSdk 36, versionCode 1,
versionName 1.0.0. SHA256:
`76E4DBA3870406DBFCB67B1AF41FDBF225C0A4AF6D85A4F56E631ECA0C8728CB`.
Conferir hash antes do upload. Se correções exigirem novo build, usar o novo
artefato validado e atualizar este registro; nunca enviar o AAB antigo por hábito.
Incrementar versionCode para novos envios quando o anterior já tiver sido utilizado.

Keystore, senhas, `key.properties` e `google-services.json` ficam privados.
Não são materiais da ficha e não devem ser enviados como documentos/screenshots.

## 3. Criar ou acessar a conta — ação futura do titular

1. Acessar https://play.google.com/console com conta Google do titular; verificar
   se já há conta de desenvolvedor antes de criar outra.
2. Se nova, selecionar o tipo apropriado. A intenção é pessoa física; confirmar
   elegibilidade conforme os recursos financeiros efetivos e as exigências da
   Google. Categoria Negócios não dispensa essa análise.
3. Ler contrato e condições, preparar dados verdadeiros de identificação, endereço,
   telefone e contatos. Examinar quais dados ficarão públicos; não confundir nome
   da marca TORICO com identidade legal exigida.
4. Pagar a taxa de cadastro única, atualmente **US$ 25**, conferindo valor final,
   moeda e forma de pagamento exibidos. Guardar recibo privadamente.
5. Concluir verificações de identidade/contato e outras tarefas do painel.
   Para conta pessoal nova, cumprir verificação de dispositivo Android quando
   solicitada. Sem aparelho compatível disponível, essa etapa pode bloquear
   a operação; o APK válido não substitui a verificação.
6. Proteger a conta e manter acesso/recuperação sob controle do titular.

Não criar/pagar conta como parte desta missão. Verificar regras novamente no dia.

## 4. Criar o rascunho do app

1. Em Todos os apps, escolher Criar app.
2. Nome: **TORICO**; idioma padrão: **Português (Brasil)**; tipo: **Aplicativo**.
3. Escolher grátis/pago somente após decisão do titular. Não inventar preços
   ou condições Plus; revisar consequências da escolha antes de confirmar.
4. Ler/confirmar declarações apresentadas pela Console e criar o rascunho.
5. Conferir tarefas do dashboard; criação de rascunho não publica o app.
6. O package é associado ao artefato enviado: verificar `br.com.meutorico.app`
   antes do primeiro upload. Não usar o antigo `com.example.vendaon`.

## 5. Preencher a ficha inicial e os links

Em Presença na loja / Ficha principal (nomes dos menus podem variar):

- Nome TORICO; descrição curta e longa do pacote, após aprovação contra o Android
  homologado. Limites: nome 30, curta 80, longa 4.000 caracteres.
- Categoria sugerida Negócios; escolher somente tags existentes e fiéis ao app.
- Ícone e feature graphic aprovados; screenshots reais de login, Painel,
  Histórico, Plano e Conta com dados fictícios. Sem UID/e-mails/clientes reais.
- Suporte provisório: **sourico.br.ec@gmail.com**; confirmar caixa monitorada.
- Site: https://www.meutorico.com.br.

URLs legais públicas:

| Finalidade | URL |
|---|---|
| Privacidade | https://www.meutorico.com.br/privacidade |
| Termos | https://www.meutorico.com.br/termos |
| Suporte | https://www.meutorico.com.br/suporte |
| Solicitação de exclusão | https://www.meutorico.com.br/exclusao-de-conta |

Inserir privacidade/exclusão nos campos próprios; termos e suporte nas áreas
apropriadas/instruções, sem inventar campos que a Console não possui. Abrir URLs
sem login, conferir HTTPS e conteúdo. Página de solicitação manual não comprova
eliminação implementada nem substitui opção de exclusão dentro do app.

## 6. Preencher App content e Data safety

Completar as tarefas de Conteúdo do app antes de solicitar revisão:

1. **Acesso ao app:** informar restrições e fornecer acesso dedicado ao reviewer
   com dados demo, sem exigir conta financeira pessoal/verificação facial. Credenciais
   privadas apenas no campo apropriado da Console, nunca no Git ou screenshots.
2. **Anúncios:** resposta provável “não”; confirmar dependências/binário atuais.
3. **Público-alvo:** adultos/comerciantes é a sugestão; titular confirmar faixas.
   Não selecionar crianças para aumentar alcance. Completar IARC separadamente.
4. **Data safety:** usar a matriz do pacote como ponto de partida, não copiar
   respostas incertas como fatos. Declarar dados de login, IDs, vendas e dados
   técnicos efetivamente coletados, inclusive SDKs. Revisar compartilhamento,
   finalidades, obrigatoriedade, retenção e criptografia em trânsito.
5. **Exclusão:** confirmar opção no app, página externa e atendimento operacional;
   não afirmar função ausente. Logout/limpeza/desconexão são ações diferentes.
6. **Recursos financeiros:** preencher mesmo sendo aplicativo de acompanhamento;
   avaliar taxonomia conforme comportamento. Não afirmar pagamentos, crédito
   ou ausência de qualquer recurso financeiro sem análise.
7. Concluir declarações adicionais que aparecerem; parar se houver dúvida.

Essas informações se aplicam também à distribuição fechada, não só à produção.
Salvar rascunhos enquanto auditorias estiverem pendentes; não solicitar revisão
com resposta sabidamente incompleta/falsa.

## 7. Preparar faixa fechada e upload — somente depois dos bloqueios

1. Abrir Testar e lançar / Teste fechado; criar ou selecionar a faixa adequada,
   com nome interno como `piloto-torico`. Não selecionar Produção/Teste aberto.
2. Configurar países/disponibilidade aprovados pelo titular.
3. Na aba Testadores, criar lista de e-mails ou selecionar Google Group. Usar
   contas Google reais consentidas; manter lista fora do Git.
4. Criar release na faixa fechada e revisar Play App Signing. Preservar a chave
   de upload; a assinatura de distribuição Play pode ser diferente. Fingerprints
   Firebase devem ser alinhados em missão própria autorizada antes de homologar
   login da versão distribuída. Não alterar assinatura/Firebase nesta missão.
5. Enviar **AAB**, conferir package, versão, SDK e avisos. Não enviar APK universal
   como substituto nem outro build com configurações antigas.
6. Preencher nome/notas da release e revisar erros/avisos. Examinar relatório
   pré-lançamento quando disponível; resolver falhas reais.
7. Salvar rascunho e revisar Resumo da publicação. **Enviar para revisão ou iniciar
   rollout fechado é publicação/distribuição externa:** requer autorização nova
   e requisitos satisfeitos. Nenhum desses botões foi acionado nesta missão.

## 8. Obter e distribuir o link de teste

Após revisão/disponibilização da release fechada, retornar à aba Testadores e
copiar o link de adesão fornecido pela Console. Não inventar URL de teste ou
presumir que estará ativo antes da release estar disponível.

Enviar privadamente aos participantes autorizados em missão própria. Eles devem
aderir e instalar pela Play com a mesma conta Google incluída na lista. O app
fechado normalmente não é encontrado pela pesquisa pública. Verificar dispositivo,
país e elegibilidade se a página disser indisponível.

A lista de testadores Play **não** libera automaticamente a allowlist do TORICO.
Não criar contas Firebase manualmente nem alterar OAuth para contornar bloqueio.
Usar as instruções de testadores do pacote e coletar feedback sem informações sensíveis.

## 9. Acompanhar 12 testadores por 14 dias

Para contas pessoais novas abrangidas pela regra (criadas após 13/11/2023), manter
ao menos **12 testadores inscritos continuamente por 14 dias** antes de solicitar
acesso à produção. Convite/lista não é adesão, e APK instalado por fora não é
substituto do teste fechado. Teste interno também não substitui esse requisito.

1. Registrar privadamente adesão, aparelho/Android, versão testada e feedback.
2. Acompanhar progresso/elegibilidade na Console; não iniciar contagem no pagamento
   da taxa ou criação da lista. Saída/reentrada rompe a continuidade daquele tester.
3. Realizar testes reais de login, painel, histórico, conta, áudio e retomada,
   documentar problemas, corrigir e verificar em versões posteriores.
4. Não fabricar participação ou usar contas controladas pelo titular como usuários
   fictícios. Preparar participantes suficientes para manter o mínimo.
5. Quando elegível, responder ao formulário de acesso à produção sobre teste,
   feedback e prontidão. Isso depende de avaliação Google; 14 dias não garantem
   aprovação ou publicação automática. Enviar somente em missão autorizada.

## 10. Verificação final do titular

- [ ] Identidade/conta verificadas e taxa registrada privadamente.
- [ ] Teste físico, Google login, gate piloto e retorno OAuth nativos homologados.
- [ ] Segurança OAuth e acesso reviewer resolvidos.
- [ ] Exclusão no app, processo manual e retenção implementados/validados.
- [ ] Textos jurídicos revisados, URLs HTTPS públicas e suporte monitorado.
- [ ] Screenshots nativos reais; ícone/feature graphic aprovados.
- [ ] Ficha e declarações fiéis ao artefato; sem novas promessas/preços.
- [ ] AAB correto e testes de versão distribuída com assinatura Play.
- [ ] Testadores consentidos, link ativo, feedback e continuidade acompanhados.
- [ ] Nova autorização antes de qualquer envio/rollout ou publicação em produção.

## Referências oficiais consultadas em 13/10/2026

- [Cadastro, taxa e verificações](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en).
- [Configurar testes e testadores](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en).
- [Preparar release](https://support.google.com/googleplay/android-developer/answer/9859348?hl=en).
- [Requisito de teste pessoal](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
- [Assets e ficha](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
- [Exclusão](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

Nenhuma conta criada, taxa paga, tester convidado, artefato enviado, publicação,
deploy ou alteração em Firebase/backend/OAuth/secrets/Cloud Run/REDE/Scheduler
foi executada nesta preparação.
