# TORICO — correções da auditoria Beta e nova homologação isolada

Referência: `dfb91f6`, auditoria `beta-independent-audit-dfb91f6.md`. Branch: `codex/beta-audit-remediation`.

Código e testes locais; nenhuma publicação, migração ou operação sobre usuários reais está autorizada por este documento.

## Correções por prioridade

| Achado | Correção | Limite/compatibilidade |
| --- | --- | --- |
| Titularidade legada | Canonicalização decimal de números inteiros seguros e strings, removendo espaços externos e zeros à esquerda; comparação de integrações e aliases de titularidade | Números com precisão perdida, IDs inválidos, caminhos inesperados e conflitos exigem revisão; nenhum documento legado é reescrito em lote |
| UID arbitrário no PagBank | POST autenticado com Firebase ID Token, revogação verificada e UID exclusivo do token; GET retorna 401 | Não habilita o provedor ou sua interface; não mantém exceção para cliente antigo |
| Callback após desconexão | Geração privada por UID/plataforma capturada na emissão, conferida no consumo e na transação final de gravação; desconexão incrementa geração atomicamente | Cancela inclusive callback que já consumiu state e ainda aguarda o provedor; reconexão explicitamente iniciada depois é permitida |
| Mistura de JavaScript | Bootstrap, bundle, engine e assets em snapshot imutável `/releases/<hash>/`; bootstrap calcula as bases a partir da própria URL | Requer retenção dos snapshots anteriores e montagem completa da release; não invalida magicamente caches de instalações legadas |
| Crescimento de nonces | Quota transacional de cinco emissões por UID/plataforma em dez minutos; pool de cinco slots reutilizáveis | Excesso retorna 429; desconectar não zera quota; não há expurgo dos registros históricos existentes |
| Timeout OAuth | Prazo de 15 segundos cobrindo fetch e JSON para Mercado Pago/PagBank, abort e rejeição de resultado tardio | Não repete código ou reabre nonce; indisponibilidade exige reiniciar autorização |
| Ambientes | APP_ENV/NODE_ENV e aliases de projeto validados; modos locais exigem demo com ambos emuladores; modos desconhecidos/mistos são recusados | Não configura staging remoto com projeto real; defaults de produção preservados sem alterar Console |

### Titularidade e compatibilidade legada

`canonicalMerchantId` aceita apenas IDs positivos em formato decimal. Inteiros JS além da precisão segura são recusados, pois não se pode recuperar o identificador original por arredondamento. Strings decimais podem preservar IDs maiores; representação canônica tem até 30 dígitos. Valores como `123`, `"123"` e `" 000123 "` são equivalentes.

Sem migração, consultas por igualdade não cobrem todas essas representações. A implementação faz inventário completo **limitado** de `integrations` e de `mp_account_owners`, comparando canonicamente. O limite é 500 documentos em cada inventário; lê-se um adicional para detectar truncamento. Ao exceder o limite, falha com `legacy_inventory_required`, sem supor que não existe outro titular. Registro MP malformado também exige revisão, em vez de associação por tentativa.

A transação lê explicitamente a titularidade canônica, os aliases e as integrações, antes de gravar. Concorrentes para o mesmo merchant ID não podem ambos assumir titularidade. Vínculos existentes de outro UID, inclusive desconectados, não são transferidos automaticamente. Aliases antigos permanecem intactos. A mesma conta pode reconectar seu próprio vínculo por OAuth explícito.

Webhooks também comparam IDs canônicos e recusam múltiplas integrações conectadas equivalentes. Falha de inventário não pode cair no fallback de roteamento. Nenhuma venda ou agregado é alterado por esses controles.

**Trade-off deliberado para homologação:** a leitura limitada tem custo/latência proporcional ao inventário e pode bloquear novos vínculos/resolução quando há dados ambíguos. Não é desenho aprovado para escala pública. Antes de produção, inventariar volume e qualidade em missão autorizada; decidir entre esse modo temporário e um índice canônico completo com migração aditiva aprovada. Não se criou índice nem se ampliou IAM.

### Estados, geração e desconexão

Coleções novas privadas:

- `oauth_authorization_controls/{hash(plataforma,uid)}`: geração, início da janela e contador.
- `oauth_nonce_slots/{hash(plataforma,uid)}_{0..4}`: UID, plataforma, geração, digest, expiração e consumo.

O state v2 contém chave opaca, slot e aleatoriedade de 256 bits. A plataforma é conferida no registro. Guardar apenas o digest evita persistir a URL de autorização completa. Cada callback precisa consumir state válido uma única vez; uma transação impede consumo duplicado entre instâncias. Substituir um slot não torna seu state antigo reutilizável, pois o digest muda.

A desconexão grava status/tokens removidos e nova geração na mesma transação. A persistência do callback lê essa geração na sua própria transação. Se desconexão vencer a corrida, callback é recusado; se callback vencer primeiro, a desconexão deixa o estado final desconectado. Histórico, totais e usuário Firebase são preservados.

Nenhum job de expurgo/TTL foi criado. O pool novo fica limitado a cinco documentos por UID/plataforma, mais um controle. Registros v1 em `mp_oauth_nonces` e `oauth_states` não foram apagados. Sua retenção/limpeza requer decisão e autorização separadas. Esses controles também precisam constar de futura revisão do procedimento de exclusão de conta; essa funcionalidade não foi ativada.

O endpoint é autenticado, mas a quota não equivale a proteção global contra criação abusiva de contas. Monitoramento, orçamento e proteção de origem confiável continuam pendentes para abertura ampla. A allowlist do frontend não substitui autorização ou quota no backend.

### Timeout e ausência de gravação parcial

O helper limita resposta e leitura do JSON. Mesmo um provedor que ignore abort não pode entregar resultado tardio à persistência. HTTP inválido, JSON inválido, ausência de access token e falhas de transporte resultam em erro sanitizado; não se devolve corpo do provedor ou credenciais.

Em erro/timeout, o state continua consumido. Nenhum token/status de integração é gravado por esse caminho. Cota/slot consumido são metadados legítimos de controle, não uma integração parcial. Não há retry automático de código OAuth, revogação remota ou alteração de client/callback/webhook.

O prazo não cobre todo o processamento SDK Firebase/Firestore nem garante comportamento do provedor quanto a autorizações remotas já emitidas. Falha de persistência posterior à emissão remota continua exigindo novo início e investigação sanitizada, sem fingir sucesso. Não foi realizado OAuth real.

## PWA: montagem imutável e compatibilidade

O template `web/flutter_bootstrap.js` mantém `entrypointBaseUrl`, `assetBase` e `canvasKitBaseUrl` dentro da URL de seu próprio snapshot. Não registra novo worker de cache. O script de montagem verifica manifests/hashes, recusa symlinks e formatos desconhecidos, preserva versões anteriores e só troca o shell depois de preparar os arquivos. Snapshot existente com bytes diferentes causa erro; não é sobrescrito.

Comandos **locais de preparação**, sem deploy:

```text
flutter build web --release --no-pub [dart-defines públicos aprovados]
node scripts/version-web-shell.mjs build/web --initial
```

`--initial` é somente para a primeira release imutável coordenada, após revisão do legado. Para a seguinte, fornecer staging/backup completo anterior:

```text
node scripts/version-web-shell.mjs build/web CAMINHO_DO_STAGING_ANTERIOR
```

Não executar o segundo comando sem saber qual release está sendo preservada. O CLI recusa omissão desse argumento/decisão inicial. Não há deploy embutido. `/releases/**` recebe cache imutável; shell, metadata e nomes estáveis exigem revalidação.

Em atualização, a URL A continua entregando arquivos A mesmo após gerar B. Em rollback, restaurar shell A mantendo ambos os snapshots. O manifesto contém todos os arquivos do snapshot, incluindo dependências; alterar um snapshot antigo é proibido.

**Instalações legadas:** query hash do formato anterior não se converte automaticamente em artefato imutável. HTML/JS/worker já frescos podem continuar antigos. A primeira transição exige janela, testes em navegador instalado e orientação de recarga/atualização. Não se prometeu atualização instantânea, funcionamento offline novo ou compatibilidade de worker antigo com qualquer engine futura.

**Hosting compartilhado:** preparar release completa com páginas legais e rewrites existentes. O JSON local não é inventário da configuração real. Não executar `firebase deploy` diretamente sobre um smoke build sem conferir isso. O build local desta missão é teste de compilação, não artefato autorizado para distribuição: a publicação precisa dos defines públicos de piloto/domínios aprovados.

## Ambientes

Backend aceita APP_ENV conhecido (`production`, `development`, `preview`, `demo`, `test`) e NODE_ENV conhecido. Combinações contraditórias, aliases divergentes, demo em modo produção/Cloud Run e portas inválidas são recusados sem imprimir valores sensíveis. Modos locais exigem projeto `demo-*`, ambos hosts de emulador em loopback e ausência de credenciais/secrets de provedor.

Flutter `development` e `preview` usam somente API HTTP local; `FirebaseEnvironment` exige projeto demo e host local coerente. Produção mantém HTTPS remoto e opções Firebase existentes, rejeitando overrides de emulador. Preview remoto com Firebase real requer desenho específico posterior; não é liberado como fallback para produção.

Os runners locais sanitizam ambiente, não usam ADC/CLI login e não importam dados reais. O fixture de health demo mantém intake desligado; a matriz de segurança da exclusão continua recusando execução em produção.

## Validação

Resultados desta branch, executados exclusivamente com serviços locais/simulados:

| Verificação | Resultado |
| --- | --- |
| Flutter analyze | Sem problemas |
| Flutter test | 96 testes aprovados |
| Backend node:test | 47 testes aprovados |
| Auth/Firestore Emulator | Aprovado: suite anterior e quatro grupos adicionais de correção, inclusive revogação real de token fictício no PagBank |
| Integração Flutter/API/emuladores | Cinco cenários normais + um de indisponibilidade aprovados; usuários/documentos protegidos preservados |
| PWA | Build release local e montagem inicial aprovados; snapshots A/B, assets, engine, corrupção e rollback aprovados nos testes |

Evidências locais: `.tmp-beta-remediation/emulator-results.json` e `.tmp-deletion-integrated/run-2026-10-16T23-30-19-097Z/summary.json`. Artefatos temporários e binários de build não são versionados. Os testes do fixture de health foram ajustados para projeto demo e intake desligado; a asserção do projeto também foi alinhada. Uma execução inicial desse fixture precisou ser encerrada enquanto aguardava um emulador que não fazia parte do smoke de health. A suíte final passou sem relaxar o guard do produto.

Comandos:

```text
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
node --test backend/test/*.test.js
node backend/test-support/run-deletion-emulators.cjs MODULO_AUTH_EMULATOR JAR_FIRESTORE
node backend/test-support/run-deletion-integrated.cjs MODULO_AUTH_EMULATOR JAR_FIRESTORE SDK_FLUTTER
```

Testes adicionais cobrem canonicalização e IDs inseguros; aliases legados; associação cruzada e concorrente; geração antes/depois da desconexão; slots, quota compartilhada, expiração e replay; PagBank sem autenticação/com token revogado real do emulador; timeout em headers/JSON, abort ignorado, respostas inválidas; snapshots A/B, engine/assets, alteração indevida e rollback; matriz de ambientes e bloqueio de exclusão.

## Impacto, proposta de migração e publicação futura

1. Revisão independente e nova homologação isolada. Nenhum passo seguinte está autorizado por esta entrega.
2. Em missão de leitura autorizada, conferir volume/tipos/caminhos de vínculos e aliases, versões publicadas, IAM, fallback MVP e estado dos snapshots/worker/legal pages. Não inferir estado real a partir das fixtures.
3. Se o inventário exceder o limite ou houver ambiguidades, interromper a ativação e apresentar migração **aditiva**: campo canônico/registro de titularidade novo, comparação em dry-run e resolução de conflitos aprovada. Não apagar/reescrever legados em lote nem transferir tokens automaticamente. Implantação de índice/IAM requer autorização específica.
4. Conferir permissão administrativa para ler controles/slots/titularidade e inventário e para verificar revogação Auth. Rules atuais já negam acesso direto a essas coleções; não há concessão ao cliente.
5. Registrar releases/revisões/configurações anteriores. Montar snapshot completo e preservar legais. Testar piloto/Google/e-mail, contas trocadas, retorno OAuth, desconexão e atualizações entre versões instaladas em homologação autorizada.
6. Aprovar janela e sequência. Clientes que já fazem POST autenticado não escolhem UID e podem usar state v2 sem interpretar seu conteúdo. GET antigo continua 401. States MP/PagBank antigos precisam reiniciar a autorização. Tokens e integrações já gravados não são invalidados por implantação de schema; nenhuma reconexão em massa é necessária.
7. Rollout do backend e clientes deve considerar requests em trânsito: revisões antigas não entendem v2 e não conferem geração. Planejar drenagem/janela de novas autorizações, não balancear indefinidamente protocolos incompatíveis. Não garantir zero indisponibilidade de novas conexões.
8. Android instalado não se atualiza com Hosting. Entregar versão compatível somente após homologação/autorização apropriada; não foi gerado/publicado APK/AAB aqui.

## Rollback e riscos restantes

Nenhuma produção foi alterada; nesta missão não há ambiente real a restaurar. A branch e os artefatos locais são revisáveis.

Em rollout futuro, voltar apenas a revisão que preserve autenticação, canonicalização e geração. **Não usar `dfb91f6` como rollback seguro de backend:** ele não bloqueia callback consumido antes de desconectar e usa protocolo anterior. Se necessário, suspender novas autorizações por intervenção previamente aprovada; não reabrir GET inseguro, reativar nonce ou excluir controles. Definir esse procedimento antes de publicar.

No PWA, restaurar shell/metadata/configuração completos de uma release compatível, mantendo snapshots e páginas legais. Não remover snapshots que clientes anteriores ainda possam requisitar. Retenção/limpeza de artefatos e nonces históricos requer política própria aprovada.

Pendentes: revisão independente; inventário/volume real e IAM; decisão de migração/índice se necessário; retenção de dados históricos; custo/latência da leitura limitada; proteção global contra abuso; teste em navegador/PWA instalado e Android; OAuth real posterior com autorização; observabilidade e procedimento de suspensão de novas autorizações. PagBank permanece não homologado comercialmente e não foi ativado. REDE/Scheduler, preços, secrets, usuários e integrações reais não foram modificados.

Parecer: apto a **nova auditoria e homologação isolada**, com as limitações descritas. Não apto à ativação automática ou publicação nesta missão.
