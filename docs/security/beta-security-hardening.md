# TORICO — correções de segurança para homologação Beta

Base: `6c682dc` (`codex/account-deletion-integrated-validation`). Branch: `codex/beta-security-hardening`.

Esta entrega é código e validação local. Não autoriza deploy, migração, expurgo ou alteração de contas existentes.

## 1. OAuth Mercado Pago

O GET antigo aceitava um UID arbitrário e gerava um state assinado reutilizável. Agora:

- `POST /integrations/mercado-pago/connect` exige `Authorization: Bearer <Firebase ID Token>`; `verifyIdToken(token, true)` verifica inclusive revogação. UID vem exclusivamente do token. Query/body não escolhem a conta TORICO.
- Retorna uma URL de autorização oficial. O aplicativo prepara a autorização e pede um segundo toque explícito em **Abrir Mercado Pago**, preservando a ativação do navegador para nova aba/câmera. Nenhum token Firebase é colocado em URL.
- State aleatório de 256 bits, digest SHA256 no Firestore privado `mp_oauth_nonces`, validade de dez minutos. Uma transação consome o nonce antes da troca do código. Callbacks simultâneos/repetidos são recusados; falha de troca exige começar novamente. Recusa OAuth também consome state quando presente.
- O callback e o redirect URI registrado permanecem iguais. Criptografia AES-GCM e documentos privados/status do usuário são preservados.
- A transação de persistência consulta os vínculos preexistentes e usa `mp_account_owners/{merchantId}` como trava persistente de titularidade. Titular diferente ou duplicidade preexistente resulta em conflito, sem gravar tokens/status/transferir titularidade.
- Reconexão pelo mesmo UID é permitida. Desconectar não libera automaticamente a titularidade para outra pessoa. Troca de titular precisa de procedimento administrativo aprovado.
- Resolução de webhook recusa mais de um vínculo conectado, em vez de escolher o primeiro. A varredura limitada a mil usuários foi removida: não prova ausência de duplicidades. Ausência do índice gera falha fechada, não roteamento para um usuário arbitrário.

**Impacto:** nenhuma integração existente foi modificada. Vínculos únicos continuam legíveis sem registro prévio de titularidade. Nova autorização pode estabelecer a titularidade depois de conferir os vínculos legados. Vínculos ambíguos exigem reconciliação manual proposta, nunca desconexão automática. Histórico e totais não são modificados por esses controles.

## 2. Cache e sessão

Totais do dia e conexões usam namespace de projeto Firebase + UID. Instâncias ficam vinculadas à identidade de criação; mudança de identidade invalida leituras/escritas e notificações do controlador antigo. Respostas de integração verificam se a sessão ainda pertence ao usuário que iniciou a leitura.

As chaves globais legadas são ignoradas, sem atribuí-las à primeira pessoa que entrar. A limpeza explícita do dispositivo também remove caches por usuário e chaves locais de protocolo, sem excluir registros remotos. Preferência de som continua sendo do dispositivo.

Não havia histórico de vendas em SharedPreferences. O histórico usa caminhos Firestore `users/{uid}/sales`; Rules negam outro UID e o Navigator do gate é recriado por UID. O cache interno do SDK permanece associado aos caminhos/projeto. Isso não oferece proteção forense contra alguém com acesso ao armazenamento do aparelho; não confundir isolamento da interface com criptografia local.

Sair invalida o acesso ao namespace anterior; voltar com a mesma conta pode recuperar seu próprio cache. Sessão Firebase restaurada continua funcionando. Nenhuma alteração na allowlist de e-mails/UIDs.

## 3. Planos e Rules

Criação de perfil aceita apenas campos de perfil explicitamente enumerados. `plan`, `planName`, `planUpdatedAt`, papéis e permissões não são campos atribuíveis pelo cliente. Atualização mantém a lista de campos permitidos existente. Planos já gravados continuam legíveis; plano ausente é interpretado como Básico, sem escrita de concessão pelo aplicativo.

Alteração de plano fica reservada a processos administrativos com credenciais e IAM apropriados, fora do cliente. Esta missão não cria processo administrativo nem amplia privilégios. As novas coleções privadas são negadas pelas Rules abrangentes existentes. Admin SDK não é restringido por Rules; IAM precisa ser revisado antes da publicação.

## 4. Cache PWA e ambientes

`firebase.json` passa a exigir revalidação em rotas estáveis, HTML, JS, CSS, manifest e worker. Cache imutável fica reservado à convenção `/assets/hashed/**`: usar esse diretório apenas para arquivos cujo nome/conteúdo nunca será sobrescrito.

`node scripts/version-web-shell.mjs <diretório-do-build>` adiciona hashes de conteúdo às URLs de `main.dart.js` e `flutter_bootstrap.js`. Executar **depois** de compilar, **antes** de montar a release. É idempotente, não faz deploy e recusa formato desconhecido ou service worker com cache de recursos. Mantém nomes/caminhos base, evitando quebrar carregamento relativo.

Um cliente que já guardou HTML/JS com headers antigos pode continuar antigo até revalidar o shell. Headers novos não apagam cache já fresco. A homologação deve incluir atualização normal e instalação antiga; orientar recarga/limpeza apenas quando necessário. Não prometer atualização instantânea de todas as instalações.

Produção mantém opções Firebase e API atuais. Desenvolvimento exige `FIREBASE_DEMO_PROJECT=demo-*`, `FIREBASE_EMULATOR_HOST` local, API HTTP no mesmo host e ambos emuladores. Exemplo local: `APP_ENV=development`, API `http://localhost:3333`, Auth `localhost:19099`, Firestore `localhost:18891`. Android Emulator usa `10.0.2.2` no cliente; processos backend/emuladores usam loopback no computador.

Preview remoto com Firebase real separado ainda precisa de desenho/configuração própria aprovada; não reutiliza automaticamente Firebase de produção. A configuração não demonstrada é recusada. Não há suporte implícito a um Firebase de staging remoto nesta entrega. Todos os hosts passam pelo gate autenticado; nomes contendo `--visual-pre-lojas` e localhost não o contornam.

O backend rejeita mistura de projeto real com emuladores, projeto demo sem ambos emuladores locais, credenciais de arquivo em modo demo e demo em Cloud Run. Os runners fornecem ambiente sanitizado e não herdam ADC/secrets.

Allowlist do frontend é controle de apresentação do piloto, não autorização administrativa. Operações protegidas usam identidade Firebase verificada e propriedade do UID; Rules impedem concessão de plano. Não se deve confiar em flags de URL ou campos enviados pelo cliente para operações privilegiadas.

## 5. Validação local

- `flutter analyze --no-pub` e `flutter test --no-pub --reporter compact`.
- `node --test backend/test/*.test.js`.
- `node backend/test-support/run-deletion-emulators.cjs <módulo-Auth-Emulator> <JAR-Firestore>`: tokens reais do Auth Emulator válidos/inválidos/expirados/revogados, UID forjado ignorado, nonce concorrente/replay/expiração, titularidade concorrente e legado duplicado, Rules de plano e acesso privado/cruzado.
- `node backend/test-support/run-deletion-integrated.cjs <módulo-Auth-Emulator> <JAR-Firestore> <SDK-Flutter>`: regressão do recebimento de solicitações via Flutter/API/emuladores, falhas e preservação dos dados de fixture.
- Build Web local e versionamento do shell, sem Hosting deploy. Cenários de atualização são automatizados com duas versões fictícias; nenhuma release pública foi alterada.

Somente projeto `demo-torico-intake`, usuários `example.invalid` e dados fictícios. Não executado OAuth real, teste em aparelho, AVD ou revisão de dados de produção.

Resultados obtidos nesta branch:

| Verificação | Resultado |
| --- | --- |
| Flutter analyze | Sem problemas após correção de um aviso de estilo |
| Flutter test | 95 testes aprovados |
| Backend node:test | 38 testes aprovados |
| Auth/Firestore Emulator | Aprovado; inclusive quatro callbacks simultâneos produzem apenas uma troca de código e uma persistência simulada |
| Integração Flutter/API/emuladores | Cinco testes normais e um com Firestore indisponível aprovados; dez documentos protegidos e dois usuários fictícios preservados |
| Bloqueio Cloud Run/demo | Inicialização recusada; com flag desligada a rota responde 404 antes do parser |
| Web release local | Compilação aprovada, sem deploy; script de versionamento aplicado e testado com duas releases fictícias |

A primeira regressão integrada esperava que a combinação demo/Cloud Run abrisse a porta e retornasse 404. O novo guard recusa a inicialização; o teste foi atualizado para exigir essa proteção e a execução seguinte passou. Não houve relaxamento do bloqueio para fazer o teste passar.

Evidência local da integração: `.tmp-deletion-integrated/run-2026-10-16T02-34-42-866Z/summary.json`. Esses artefatos de execução não são incluídos no Git.

## 6. Plano de compatibilidade — depende de nova autorização

1. Revisão independente destas mudanças e inventário **somente leitura autorizado** dos vínculos existentes, tipos dos identificadores, índices e IAM. Não foi feito nesta missão.
2. Confirmar índice de campo `mercadoPagoUserId` no collection group `integrations`. Não criar índice automaticamente nem remover índices existentes. Sem índice, suspender publicação desta parte e apresentar a adição específica.
3. Propor reconciliação das duplicidades encontradas, validando titularidade com os envolvidos. Não escolher primeiro UID, transferir tokens ou desconectar automaticamente. Preparar registro de titularidade para legados somente após aprovação; nenhuma migração foi executada.
4. Aprovar política de retenção de nonces consumidos/expirados e titularidades. Não há TTL/expurgo ativado nem exclusão de registros. Monitoramento, limitação de emissão de nonces por UID e retenção precisam de revisão operacional antes de abertura ampla.
5. Preservar release Hosting, revisão backend, Rules e configuração prévias. Montar release Flutter com defines públicos aprovados, versionar shell e **incluir as páginas legais e seus rewrites atuais**. Não executar deploy genérico que substitua essas páginas; o `firebase.json` do repositório não é inventário da release compartilhada.
6. Homologar cliente e backend juntos em ambiente isolado. Planejar janela de OAuth: cliente antigo usa GET sem token e receberá orientação para atualizar. Não manter fallback inseguro. States antigos em trânsito precisam reiniciar autorização. Usuários já conectados não precisam reconectar.
7. Após nova autorização, planejar publicação coordenada (Rules, novo cliente e backend) e validação de versões/cache. A ordem e janela devem ser aprovadas; publicar qualquer lado isolado pode impedir novas conexões temporariamente. Nenhuma troca silenciosa foi feita.

**Não há compatibilidade segura para continuar autorizando GET com UID arbitrário.** Esta limitação impede rollout automático; não impede a homologação isolada.

## 7. Rollback proposto

- Nesta missão: não há produção a restaurar; a branch contém as mudanças para revisão, sem merge/deploy. Os arquivos locais não relacionados foram preservados.
- Em implantação futura: restaurar release completa Hosting (incluindo legais) se necessário, preservando dados. Manter correções de autenticação e Rules restritivas; não reabrir GET inseguro ou permissão de autoatribuição de plano para recuperar funcionalidade.
- Se OAuth novo falhar, suspender novas autorizações e orientar atualização/reinício; manter consultas e integrações já existentes. Rollback de backend que reintroduza associação insegura não é aceitável sem análise específica.
- Nonces/titularidades novos são aditivos: não apagar em rollback; estados consumidos não devem voltar a disponíveis. Alteração ou expurgo depende de autorização e plano separado.

## 8. Parecer e pendências

Elegível para revisão e homologação Beta **isolada**, condicionado aos resultados registrados. Não equivale a autorização de Beta público/produção.

Bloqueadores para ativação: revisão independente, verificação de índices/IAM e vínculos legados, decisão sobre conflitos/transferências, rollout coordenado com atualização do PWA e preservação das páginas legais. Pendentes: testes Android/PWA reais (troca de contas offline e versão previamente instalada), OAuth oficial com consentimento posterior, observabilidade e retenção aprovadas. Recursos ainda não homologados de outras plataformas não são ativados por esta entrega.

Exclusão de conta continua restrita a demo com emuladores; matriz de bloqueio em produção permanece nos testes existentes. REDE/Scheduler, preços, secrets e produção não foram alterados.
