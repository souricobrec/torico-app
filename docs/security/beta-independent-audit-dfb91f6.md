# Auditoria das correções de segurança Beta TORICO

Data: 16/10/2026, America/Sao_Paulo. Referência auditada: `codex/beta-security-hardening`, commit `dfb91f6`.

**Parecer: NÃO APTO PARA PUBLICAÇÃO.** Os controles principais melhoraram e passaram nos testes, mas permanecem falhas reproduzidas e bloqueadores de compatibilidade/infraestrutura. Homologação local pode continuar. Este parecer não autoriza alterações ou publicação.

## Escopo e limites

Revisão do código, execução das suítes existentes e provas adversariais adicionais. Somente Auth/Firestore Emulators em `demo-torico-intake`, loopback, identidades `example.invalid` e credenciais fictícias. Não houve consulta a dados, configurações, índices, IAM, contas ou credenciais de produção. Nenhum OAuth real, deploy, mudança no código da aplicação, desconexão real, exclusão, migração ou publicação de binários.

Os vínculos legados avaliados são sintéticos. Não foi demonstrado que existam IDs numéricos ou duplicidades no banco real. Essa limitação é decisiva para interpretar os achados condicionais.

Não foi feita homologação em dispositivo/AVD nem teste de atualização de um PWA instalado em navegador real. O teste adicional de conteúdo Web utilizou o middleware Superstatic instalado com firebase-tools, servido localmente, sem inicialização Firebase ou acesso ao Hosting real.

## Resumo dos achados

| ID | Criticidade | Achado | Condição/evidência |
| --- | --- | --- | --- |
| S01 | Alta, condicional | ID Mercado Pago numérico legado escapa da verificação por ID string | Reproduzido em Firestore Emulator; existência real não verificada |
| S02 | Média | State anterior à desconexão pode reconectar a integração | Reproduzido com nonce real local, handler de desconexão e persistência transacional |
| S03 | Média | Hash em query não preserva o artefato de uma versão anterior do PWA | URL antiga recebeu bytes novos no middleware estático local |
| S04 | Média | Emissão de nonces sem quota e sem retenção implementada | Trinta emissões simultâneas para um UID produziram trinta documentos |
| S05 | Média | Troca de código OAuth sem prazo de timeout da aplicação | Callback permanece aguardando provedor simulado sem resposta, após consumir state |
| S06 | Alta, condicional | OAuth PagBank ainda aceita UID escolhido pelo cliente, sem ID Token | Handler reproduzido em VM, com configuração e provedor fictícios; configuração real não consultada |
| S07 | Baixa | Guard de ambientes não valida todos os modos de execução | `NODE_ENV=development` isoladamente e `APP_ENV=staging` não são recusados com projeto real, em teste puro sem SDK |

Nenhuma falha crítica foi confirmada no caminho Mercado Pago com IDs string canônicos, tokens Firebase verificados e infraestrutura correta. Isso não elimina os achados nem certifica outros caminhos não exercitados.

## S01 — comparação estrita de tipos nos vínculos legados

Fonte: [mercado-pago-security.js:43](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/mercado-pago-security.js:43), especialmente a consulta de igualdade na linha 49. A resolução de webhook também consulta string em [server.js:1178](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/server.js:1178).

Prova: uma integração de UID A recebeu `mercadoPagoUserId: 123456789` numérico, status conectado e ciphertext fictício. A persistência para UID B com `'123456789'` em texto foi aceita. As duas integrações permaneceram conectadas, e o registro de titularidade ficou em B. O Firestore não trata número e string como o mesmo valor.

O código de gravação atual converte o ID para string. Portanto, o risco depende de dados legados, importados ou administrativos com tipos divergentes; não é possível a um cliente comum gravar essa fixture pelas Rules atuais.

Impacto: a garantia de unicidade não cobre esse legado; a consulta de webhook pode ignorar o vínculo numérico. Não houve transferência ou alteração de tokens reais.

Recomendação: antes de ativar, inventariar tipos e representações, incluindo espaços/zeros e caminhos inesperados; definir ID canônico e tratamento de colisões. A ausência de conflitos deve ser verificável. Não normalizar, escolher titular ou transferir credenciais automaticamente. Qualquer migração precisa de aprovação, backup, validação de titularidade e ensaio. Até lá, bloquear a publicação dessa parte.

## S02 — autorização pendente sobrevive à desconexão

Fontes: [mercado-pago-security.js:25](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/mercado-pago-security.js:25), [disconnect-platform.js:26](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/disconnect-platform.js:26) e persistência de titularidade na linha 43 do módulo de segurança.

Prova: emitir nonce para A, conectar fixture, executar desconexão autenticada e confirmar `disconnected`; consumir o nonce anterior e persistir o resultado de autorização para o mesmo titular. A integração voltou a `connected` com novo ciphertext fictício.

A trava de titularidade protege contra outro UID, mas não invalida autorizações anteriores do mesmo UID. Uma conclusão atrasada pode desfazer a intenção de desconectar. O teste não autenticou no Mercado Pago: simulou somente o resultado do provedor.

Recomendação: projetar uma geração de autorização/integração ou marcador equivalente. Desconexão deve invalidar tentativas anteriores, e a persistência do callback deve conferir essa geração atomicamente. Uma nova reconexão iniciada explicitamente depois da desconexão deve continuar permitida. Testar também ordem inversa, duas autorizações simultâneas e falhas parciais. Não corrigido nesta auditoria.

## S03 — versionamento por query ainda permite mistura de releases

Fonte: [version-web-shell.mjs:21](C:/Users/CRZ/Documents/ChatGPT/TORICO/scripts/version-web-shell.mjs:21). O script altera referências, mas continua substituindo `main.dart.js` e `flutter_bootstrap.js` nos mesmos caminhos.

Prova: salvar bootstrap da release A, preparar release B no mesmo diretório e solicitar `main.dart.js?v=<hash-A>`. O middleware estático utilizado pelo Hosting Emulator retornou o JavaScript B com HTTP 200. O hash na query não é validado como identidade do conteúdo pelo servidor.

Não foi demonstrado um crash do Flutter real. Foi demonstrada a ausência de garantia contra mistura de versões, por exemplo em carregamento atrasado atravessando uma publicação. Os testes existentes verificam mudança das strings de URL, mas não esse cenário entre releases.

Os novos headers de revalidação são adequados para nomes estáveis. Eles não removem entradas antigas ainda frescas no navegador. A política imutável fica restrita a `/assets/hashed/**`; não existem evidências de que todos os artefatos da release sejam preservados nesse formato.

Recomendação: artefatos com nomes/caminhos imutáveis por conteúdo, preservação das versões necessárias e montagem atômica da release; alinhar bootstrap, worker e carregamentos tardios. Ensaiar com instalação antiga, atualização durante carregamento, rede lenta, rollback e offline. Testar os headers na configuração final de Hosting, não apenas no JSON do repositório. Não houve alteração do script ou do Hosting.

## S04 — crescimento de nonces e ausência de limitação

Fonte: [mercado-pago-security.js:19](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/mercado-pago-security.js:19) e POST em [server.js:3051](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/server.js:3051).

Trinta chamadas paralelas de `issue` para um UID foram aceitas, com trinta documentos novos. A validade de dez minutos impede uso tardio; não remove o documento. Não há quota por UID, limite de tentativas pendentes nem expurgo nessa implementação.

O emissor exige Firebase ID Token, mas a allowlist do frontend não limita chamadas diretas de outro usuário Firebase autenticado. Isso não concede acesso a outro UID, porém permite crescimento de escritas/custo e sobrecarga do endpoint. A prova chamou o store; a revisão do handler confirmou que não há limiter adicional nessa rota.

Recomendação: quota compartilhada por UID e origem confiável, limite de tentativas pendentes e observabilidade sanitizada. Aprovar retenção e mecanismo de expurgo antes de executá-los. `expiresAtMs` numérico não constitui política TTL ativada. Não reutilizar automaticamente o limiter de outras rotas nem confiar indiscriminadamente em X-Forwarded-For.

## S05 — timeout e recuperação da troca OAuth

Fonte: [server.js:3096](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/server.js:3096), consumo anterior ao `fetch` da linha 3105.

O callback usa `fetch` sem AbortSignal/deadline explícito. Com provedor simulado que não responde, o handler ficou pendente e o nonce já estava consumido. O ensaio observou uma janela curta controlada e a ausência de prazo no código; não mediu timeout real de Cloud Run ou limites internos de transporte.

Recomendação: prazo limitado, erros distintos de indisponibilidade, correlação sanitizada e orientação clara para reiniciar. Não reabrir nonce consumido nem fazer retry cego que permita replay. Testar timeout, erro HTTP, resposta inválida e falha de persistência após troca bem-sucedida. O teste não prova invalidação de tokens legítimos preexistentes pelo provedor; esse efeito externo não foi homologado.

## S06 — cobertura incompleta de autorização no backend

Fonte: [server.js:2013](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/server.js:2013).

O início PagBank continua público, usa `req.query.userId` e só depende de configuração OAuth disponível. Em VM, sem header de autenticação, o handler emitiu state para `synthetic-victim` e montou redirecionamento. Nenhuma conexão foi feita ao provedor e nenhum registro foi gravado por esse ensaio.

Se a configuração estiver ausente, o caminho retorna 503. Não é possível afirmar que esteja operacional em produção sem inspeção autorizada posterior. O status “Em preparação” na interface não é barreira de autorização.

Recomendação: manter a plataforma bloqueada no backend por controle explícito até revisão própria, ou aplicar identidade derivada do token e controles equivalentes. Não habilitar PagBank para testar este achado. REDE permanece fora da ativação; seus endpoints administrativos usam dev key, e isso precisa continuar independente da interface.

## S07 — separação de ambientes parcialmente convencional

Fonte: [environment-isolation.js:5](C:/Users/CRZ/Documents/ChatGPT/TORICO/backend/environment-isolation.js:5), [api_config.dart:12](C:/Users/CRZ/Documents/ChatGPT/TORICO/lib/config/api_config.dart:12), [firebase_environment.dart:23](C:/Users/CRZ/Documents/ChatGPT/TORICO/lib/config/firebase_environment.dart:23).

O guard recusa combinações explícitas perigosas demo/emulador/credenciais/Cloud Run. Contudo, a função aceita projeto real quando somente `NODE_ENV=development` é definido ou quando `APP_ENV=staging` é informado. A prova não inicializou SDK nem acessou esse projeto. Não é bypass remoto: é risco de configuração operacional inadvertida.

No Flutter, os valores aceitos são mais restritos. Também não há configuração funcional de preview remoto aprovada: ApiConfig exige HTTPS remoto para preview e FirebaseEnvironment exige HTTP local. Essa limitação é reconhecida na documentação, mas não deve ser tratada como staging pronto.

Recomendação: contrato único de ambientes, validação de valores desconhecidos, modo local explícito e preflight que não herde ADC/secrets. Não ampliar suporte a staging usando produção como fallback.

## Controles confirmados

- OAuth Mercado Pago: `verifyIdToken(token, true)`; UID do token; UID em query não escolhe titular. Tokens inválidos, expirados e revogados foram recusados nos testes locais.
- Nonce aleatório de 256 bits, digest privado e expiração de dez minutos. Cinco consumos simultâneos tiveram um vencedor. Quatro callbacks concorrentes produziram uma troca e uma persistência simuladas. Replay foi recusado.
- Contas com ID string canônico: transações entre dois UIDs tiveram um vencedor; tentativa posterior cruzada foi negada. Duplicidade string preexistente foi recusada sem alterar fixtures. Reconexão do mesmo titular continua permitida.
- Tokens continuam criptografados pelo código existente, separados do status mínimo legível. Callback oficial e URL de retorno não foram alterados nesta auditoria. Não houve desconexão automática em lote ou invalidação de tokens reais.
- Cache por projeto/UID, namespace legado ignorado, instância antiga recusada na troca de identidade. Gate recria Navigator por UID. Testes Flutter cobriram logout, retorno à mesma conta e troca de projeto/conta. Não há prova de isolamento forense do armazenamento físico, nem promessa de remoção do cache interno do SDK ao sair.
- Rules recusaram criação/alteração de Plus, papel administrativo e leitura cruzada de venda. Perfil legítimo foi aceito; plano concedido administrativamente permaneceu legível. Coleções de nonce/titularidade são privadas pelas Rules.
- Allowlist é apresentação do piloto. Operações Mercado Pago protegidas usam autenticação/propriedade reais, e não uma flag de URL. Isso não certifica automaticamente todas as rotas do backend, como mostra S06.
- Matriz de bloqueio de exclusão permaneceu fechada fora de demo/emuladores. Nenhuma operação destrutiva foi ativada.

## Compatibilidade e requisitos de migração

| Combinação/caso | Resultado esperado/evidência | Condição para publicação |
| --- | --- | --- |
| Cliente antigo GET + backend novo | GET responde 401 e não emite state | Atualização obrigatória ou suspensão comunicada de novas conexões |
| Cliente novo POST + backend antigo | Rota autenticada POST não existe no código anterior | Não distribuir lados incompatíveis sem janela e plano |
| State assinado antigo + callback novo | Recusado pelo formato/store novos | Reiniciar OAuth em trânsito, sem afrouxar replay |
| Integração canônica já conectada | Permanece gravada e legível, sem reconexão obrigatória | Confirmar índice e ausência de ambiguidades |
| Legado numérico/duplicado | Pode escapar da consulta ou bloquear resolução | Inventário e proposta de reconciliação, sem alterações automáticas |
| Cliente antigo que cria perfil com `plan: basic` | Recebe 403 nas Rules novas, reproduzido no emulador | Mapear versões/fluxos e atualizar cliente; não reabrir autoatribuição |
| Plano existente atribuído administrativamente | Continua legível | Preservar dados e campos protegidos |
| Android antigo instalado | Não muda seu protocolo por atualização do Hosting | Plano de entrega de versão compatível e homologação nativa |
| Hosting compartilhado e páginas legais | JSON local tem catch-all PWA; build local consultado não continha `/privacidade/index.html` | Montar e comparar release completa, preservando legais e rewrites |

Infraestrutura não certificada nesta missão: índice de igualdade de `mercadoPagoUserId` no escopo collection group `integrations`; permissões Firestore para consultar legados e ler/escrever os dois novos registros privados; permissão Firebase Auth necessária à checagem de revogação; limites/custos, observabilidade e retenção. Emuladores não demonstram que índices e IAM reais estejam corretos.

Não há arquivo de índices versionado integrando essa necessidade à release. Não há solicitação aqui para conceder novos privilégios; primeiro comparar as necessidades com as permissões existentes, aplicando mínimo privilégio em revisão autorizada separada.

## Testes efetivamente executados nesta auditoria

| Execução | Resultado |
| --- | --- |
| `flutter analyze --no-pub` | Sem problemas |
| `flutter test --no-pub --reporter expanded` | 95/95 aprovados |
| `node --test backend/test/*.test.js` | Primeira execução: 37/38, timeout de startup em health; repetição sequencial final: 38/38 |
| `node --test backend/test/healthz.test.js` | 4/4 aprovados isoladamente |
| Harness Auth/Firestore + provas independentes | Suíte original aprovada e quatro provas adicionais A01–A04 concluídas; somente demo e fixtures |
| Integração Flutter → API → Auth/Firestore | Cinco cenários normais + um cenário de indisponibilidade aprovados; documentos protegidos e usuários fictícios preservados |
| Provas estáticas/HTTP locais adicionais | 4/4 concluídas: A05 cache, A06 ambientes, A07 timeout, A08 rota PagBank |

Os testes adversariais passam quando confirmam a reprodução do problema; **4/4 não significa ausência de vulnerabilidade**. Os primeiros ajustes do ensaio Superstatic corrigiram somente a fixture Windows (diretório estático e uma expectativa de header não coberta pelo middleware isolado). Nenhum ajuste foi aplicado ao produto. O teste final prova identidade dos bytes, não headers reais de produção.

Firestore Emulator registrou `Transaction lock timeout` durante a contenção; os retries terminaram e as invariantes de unicidade/consumo passaram. Isso é evidência de contenção e não um benchmark de desempenho. A repetição sequencial do backend resolveu o timeout de health observado sob carga; não foi mascarado nem corrigido em código.

Provas adicionais locais, não incorporadas ao código do produto:

- `.tmp-beta-independent-audit/run-emulators.cjs` e `audit-emulators.mjs`: harness sanitizado; recusa portas ocupadas; encerra somente processos criados pelo ensaio.
- `.tmp-beta-independent-audit/independent-probes.mjs` e `emulator-evidence.json`: S01/S02/S04 e compatibilidade das Rules.
- `.tmp-beta-independent-audit/static-probes.mjs`: S03/S05/S06/S07.
- `.tmp-deletion-integrated/run-2026-10-16T23-07-42-728Z/summary.json`: regressão integrada desta auditoria.

## Estratégia recomendada de publicação coordenada

1. Autorizar correções dos achados, com testes de regressão adicionais. Nenhuma correção foi feita aqui.
2. Concluir S01/S02/S03 e definir bloqueio explícito das plataformas não homologadas. Aprovar quotas/retention e recuperação de falhas.
3. Em nova missão autorizada de leitura, verificar versões reais, índice, IAM, tipos/duplicidades e configuração dos fallbacks. Confirmar `ENABLE_MERCADO_PAGO_MVP_FALLBACK` desativado no cenário multi-merchant; sua existência no código é dependência operacional, não certificação da configuração atual.
4. Se necessário, aprovar migração separada, ensaiada e reversível, sem decidir titularidade automaticamente. Não alterar criptografia/chaves ou executar desconexões em lote.
5. Montar release completa de Hosting com páginas legais, controles piloto, defines públicos aprovados e assets versionados corretamente. Registrar release/revisão/configuração anteriores e evidência de equivalência fora do escopo.
6. Preparar versões Android/PWA compatíveis e orientação de atualização. Declarar janela em que novas conexões podem ficar indisponíveis; preservar navegação de usuários conectados. Não manter GET inseguro para evitar a janela.
7. Ensaiar em ambiente isolado a matriz velho/novo, expiração, desconexão concorrente, rede lenta, troca de conta, atualização e rollback. Solicitar autorização específica para homologação OAuth real posterior.
8. Somente após parecer favorável e nova autorização: executar a sequência de infraestrutura/Rules/backend/clientes aprovada, com critérios de interrupção e monitoramento. Os passos desta lista são proposta; nenhum foi executado em produção.

Rollback: preservar correções de autorização e Rules restritivas; não restaurar vulnerabilidades para recuperar compatibilidade. Em falha, suspender novas conexões e orientar atualização/reinício, mantendo integrações e histórico existentes. Restaurar apenas release completa compatível e previamente validada; não apagar titularidades, reabrir nonces consumidos ou reatribuir contas. Este commit não deve ser publicado como está.

## Decisões pendentes

Correção de representação legada; geração de cancelamento/reconexão; formato imutável dos artefatos; quota e retenção; prazo/recovery de OAuth; bloqueio backend de plataformas futuras; contrato de ambientes; migração/índice/IAM; política de atualização de clientes antigos e janela operacional. Dependências reais permanecem desconhecidas por restrição de escopo, não aprovadas por inferência.

HEAD permanece `dfb91f6`. Alterações locais preexistentes de registrants foram preservadas. Apenas relatório e provas temporárias foram gerados; não houve commit, push, merge ou deploy nesta missão.
