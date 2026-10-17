# TORICO — correção dos três bloqueadores finais Beta

Branch: `codex/beta-final-blockers`. Referência: `299f7cb`, auditoria `beta-final-audit-299f7cb.md`.

## Alterações

1. **Limite global removido:** `canonicalIntegrationMatches` não consulta mais collection group, não varre owners e não usa teto de 500. Resolve apenas `mp_account_owners/{ID canônico}` e a integração MP do UID apontado. Leitura consistente em transação. Callback confere geração, certificação do índice e owner canônico na mesma transação dos tokens/status.
2. **Legados inválidos isolados:** dados alheios não são lidos. Conflito, schema/epoch divergente ou integração inválida produzem erro somente no merchant afetado e diagnóstico estruturado com código/hash do merchant, sem tokens, UID ou conteúdo de documentos. IDs privados válidos numéricos e strings com zeros/espaços são comparados canonicamente. Nenhum legado é reescrito pelo resolvedor.
3. **Snapshots PWA estritos:** normalização do shell permanece apenas na entrada de montagem. Snapshot selado é verificado e copiado byte a byte, incluindo a referência de bootstrap no HTML. Metadata extra e subárvore `releases` dentro do snapshot não são mais ignoradas. Alteração do HTML, bundle ou arquivo inesperado bloqueia montagem antes de trocar o shell. Arquivos com o mesmo manifesto não recebem bytes normalizados diferentes.

Firebase ID Token/revogação, UID derivado do token, PagBank autenticado, state opaco com expiração/consumo único, geração na desconexão, quota de nonces, timeout OAuth, Rules de plano e cache por UID permanecem. Não foram alterados client/callback/webhook OAuth ou criptografia.

## Dependência interrompida — não publicar

A ativação do resolvedor exige um **índice lógico completo certificado**. É impossível provar ausência de aliases legados arbitrários apenas com uma consulta direta. Não foi adicionada exceção insegura de compatibilidade.

Sem marcador privado de certificação e entries versionadas, o código novo recusa operações MP com 503/409. Portanto, não é substituição imediata do backend publicado. A etapa dependente de migração/certificação real está interrompida, conforme a restrição da missão.

Especificação detalhada: `mp-ownership-index-migration-spec.md`. Nenhum índice real, migração, marcador de produção, credencial ou nova permissão foi criado. Não há endpoint para ativar o índice. Coleções privadas continuam negadas ao cliente pelas Rules existentes.

## Custo e compatibilidade

| Caminho | Leituras de documentos por tentativa, sem retries |
| --- | --- |
| Resolver merchant existente | 3: marcador + owner + integração |
| Merchant ausente com índice certificado | 2: marcador + owner ausente |
| Índice ainda não certificado | 1: marcador |
| Persistir callback | 3: geração + marcador + owner; grava owner e as duas entradas privadas/status atuais |

Consumo de state/emissão de nonce mantém custos próprios anteriores. Retries transacionais e faturamento de leituras ausentes dependem do serviço; não se apresenta preço monetário nem benchmark de produção. O custo da resolução é O(1) em relação ao total de integrações. Não há índice composto adicional para doc.get; o backfill autorizado será um custo administrativo O(N) separado, nunca por webhook.

Integrações e tokens existentes não são apagados. Vínculos legados continuam legíveis após backfill certificado, inclusive numéricos/padded; a compatibilidade depende dessa preparação. Conflitos entre UIDs exigem revisão, não transferência automática. Tombstones/reservas antigos permanecem. Se o usuário autorizar outra conta MP para o mesmo UID, eventos da conta anterior não usam o token substituto.

Clientes POST autenticados permanecem compatíveis após preparação coordenada. GET antigo continua 401. Android antigo não se atualiza pelo Hosting; states de protocolos anteriores precisam reiniciar. Não prometer continuidade sem janela entre revisões incompatíveis. Nenhuma conta existente foi testada ou modificada em produção.

## Testes

Todos usam fixtures sintéticas, projeto `demo-*` ou mocks; nenhum teste acessa produção.

| Validação executada | Resultado |
| --- | --- |
| `flutter analyze --no-pub` | Sem problemas |
| `flutter test --no-pub --reporter expanded` | 96 aprovados |
| `node --test backend/test/*.test.js` | 53 aprovados; zero falhas |
| Auth/Firestore Emulator | Autenticação/revogação, Rules, planos, nonce/replay/quota, concorrência de titularidade, callback tardio/desconexão e PagBank aprovados |
| Escala em Firestore Emulator | 501, 1.000 e 1.501 integrações adicionais e mesmo número de aliases; merchant válido continua resolvendo e conflito fica isolado |
| Snapshots PWA | HTML/JS adulterados e arquivos extras rejeitados; A/B, assets/engine preservados e rollback aprovados |

Logs locais: `.tmp-beta-remediation/final-blockers-flutter.log`, `final-blockers-backend.log` e `final-blockers-emulators.log`. Comandos do runner: `node backend/test-support/run-deletion-emulators.cjs MODULO_AUTH_EMULATOR JAR_FIRESTORE`. Não há benchmark monetário ou de latência real; mocks contam três leituras, e as consultas funcionais também foram exercitadas no emulador. Testes não homologam o inventário/certificação real nem o cache de um navegador já instalado.

Cobertura adicionada: 501/1.000/2.001 registros no teste unitário com contagem constante de leituras; 501/1.000/1.501 integrações **adicionais** e igual número de aliases nos emuladores; canonicalização numérica/string; conflito isolado; índice não certificado e epoch inválido; troca de conta sem roteamento com token substituto; adulteração da referência HTML/JS e arquivos extras; preservação de snapshots/rollback.

As fixtures versionadas não são ferramentas de migração. Testes de titularidade legada agora declaram o resultado conhecido do índice sintético, em vez de depender de varredura global; testes de conflito e corrida permanecem.

## Implantação futura e rollback

1. Nova auditoria direcionada do índice/certificação e snapshots estritos. Homologar fixtures, concorrência e clients já instalados em ambiente autorizado.
2. Autorizar separadamente inventário real em leitura; aprovar plano de backfill aditivo, tratamento de ambiguidades, controle de escritores, retenção e permissões administrativas mínimas.
3. Preparar backup de dados/configuração e revisão backend de contingência que entenda índice e geração. Reconciliar índice antes de liberar código novo; nenhuma publicação automática.
4. Em janela aprovada, coordenar interrupção de novos vínculos antigos, certificação final e backend/clients compatíveis. Preservar callbacks oficiais e eventos existentes. Não encaminhar tráfego para mistura de protocolos incompatíveis.
5. PWA: montar release completa com defines públicos aprovados, páginas legais, rewrites e snapshots anteriores. Verificar hashes estritos antes de publicar. Testar abas/PWA instalado e Android; esta missão não substitui homologação em aparelho.
6. Rollback PWA restaura shell/metadata de release compatível, mantendo snapshots de ambas as versões e páginas legais. Snapshot adulterado deve ser recuperado de backup íntegro, nunca re-selado silenciosamente.
7. Backend/índice: preservar reservas novas e deltas; não restaurar mapa obsoleto nem apagar owners. Suspender novos vínculos pelo procedimento autorizado caso não haja revisão segura. Não reabrir GET/nonce, não voltar à revisão vulnerável ou à varredura como fallback automático.

## Parecer e pendências

Código preparado para **nova auditoria direcionada e testes isolados**. Não apto a deploy/ativação imediata: migração/certificação de índice permanece dependente de autorização, além de homologação em PWA/Android instalado, OAuth real posterior e revisão do procedimento operacional de rollout/rollback.

Não houve deploy, leitura de dados/credenciais reais, alteração Firebase Console/IAM/Cloud Run/Rules implantadas, mudanças em preços, REDE/Scheduler ou ativação de exclusão de conta. Alterações locais antigas não fazem parte da entrega.
