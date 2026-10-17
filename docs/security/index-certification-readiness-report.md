# TORICO — correções finais e preparação da inspeção controlada

Branch `codex/index-certification-readiness`, base `41e260b`. Escopo: código/testes locais e procedimento futuro; nenhuma ação de infraestrutura real foi executada.

## Resultado das três correções

| Achado | Correção | Limite explícito |
| --- | --- | --- |
| ready isolado não comprova completude | Reconciliação independente de inventário e owners; certificado com hashes/contagens, projeto/revisão/epoch, duas assinaturas Ed25519 distintas e validade; fragmento assinado/hash por merchant antes de resolver/persistir | Assinaturas não tornam uma coleta truncada completa. Revisores, captura consistente e controle de escritores ainda precisam ser aprovados. Não há migrador/assinador/coletor real nesta entrega. |
| Arquivo especial omitido no PWA | Inventário sem protótipo e checagem de propriedade própria; nomes `__proto__`, `constructor`, `toString` entram no manifesto e cópia | Não atesta bytes atualmente publicados ou caches de PWA instalado; testes locais apenas. |
| Reconexão apaga metadados do owner | Merge apenas dos campos operacionais validados, preservando extras; UID, epoch, estado e merchant seguem conferidos pelo token/geração/índice/evidência | Metadados livres não autorizam mudança de titularidade; alterações externas por administradores ainda precisam de IAM e auditoria operacional. |

O ID canônico foi extraído para módulo próprio para compartilhar a mesma validação com o reconciliador, mantendo o export anterior de compatibilidade. Não foram alterados Firebase Token verification, callback/client/webhook OAuth, criptografia, UID, planos/preços, nonce/replay/quota, PagBank ou cache por UID.

## Falha segura e compatibilidade

Ausência de certificado/âncoras, assinaturas repetidas/inválidas, projeto/revisão divergente, prazo vencido, fragmento ausente/alterado ou claim estruturalmente inválido impedem ativação do caminho novo. Um owner legado removido que consta da evidência não vira conta livre. Um índice proposto que omita vínculo ou ignore conflito não passa pelo reconciliador.

Um owner novo após a base continua sendo reservado transacionalmente pelo backend. Não há transferência automática após desconexão. Reservas novas não podem ser removidas por ferramentas externas ou writers antigos; o certificado não protege contra administradores comprometidos nem substitui a gestão desses escritores.

Sem as novas configurações públicas/certificação, esse backend **não é implantável como troca imediata**. Marcadores ready antigos foram intencionalmente rejeitados; não há fallback inseguro para o formato anterior. Instalar âncoras, preparar inventário real, migrar, assinar/ativar e renovar exigem novas autorizações.

Validade máxima conservadora de 24 horas desde a captura foi implementada como bloqueio. Política de renovação, duração operacional, custódia/independência de signatários e contingência ainda precisam de aprovação. Não ativar sem esses processos: expiração interrompe resolução MP em vez de confiar em evidência antiga. A futura retenção/exclusão deve incluir certificados, fragmentos privados com UIDs e journals; nenhuma exclusão foi ativada.

## Validações executadas

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --reporter expanded`: 96 aprovados.
- `node --test backend/test/*.test.js`: 60 aprovados, zero falhas.
- Auth/Firestore Emulator: regressão de tokens válidos/inválidos/revogados, query UID rejeitado, Rules, planos, nonce/replay/quota, titularidade concorrente, desconexão e callbacks tardios.
- Certificação sintética em emuladores: ready sem evidência rejeitado; owner legado ausente não pode ser tomado; fragmento ausente, assinante repetido e certificado assinado desatualizado rejeitados; reconexões repetidas/concorrentes preservam audit e data original; UID estrangeiro rejeitado.
- Testes unitários: inventário incompleto, conflito omitido, ID sem precisão, paths duplicados, trust anchors ausentes/iguais, assinaturas inválidas, projeto/revisão incorretos, lease vencida e claims assinados mas estruturalmente inválidos.
- PWA: hashes A/B, referência de bootstrap/JS adulterados, inclusões/exclusões de arquivos especiais, preservação de assets/engine e rollback local.
- Escala de regressão: 501/1.000/2.001 registros nos mocks; 501/1.000/1.501 integrações e igual número de aliases nos emuladores, com resolução independente preservada. Testes de escala não são benchmark de produção nem prova de completude real.

Evidências locais: `.tmp-certification-readiness/backend.log`, `flutter.log`, `emulators.log`, `certification-results.json`. Projeto exclusivo `demo-torico-intake`; credencial fake de emulador, âncoras públicas/chaves privadas de teste geradas em memória, sem ADC/CLI de produção. Runners sanitizados e portas loopback exclusivas. Novas coleções de certificado/evidência foram incluídas nas verificações de leitura/escrita negadas a clientes autenticados.

Não foi realizado OAuth real ou teste Android/PWA instalado. Não foram gerados APK/AAB, consultados dados reais, índices/IAM implantados, secrets ou estado real de REDE/Scheduler. A execução local não comprova a configuração de produção.

## Procedimento futuro e permissões

Roteiro preparado, **não executado**: [controlled-infrastructure-read-only-sop.md](controlled-infrastructure-read-only-sop.md).

Inclui recursos exatos do projeto/banco, projeções mínimas de integrações e owners, readTime fixo/paginação, IAM/índices, orçamento, sanitização/HMAC, interrupção e critérios para solicitar certificação posterior. Permissões de dados mínimas propostas: `datastore.entities.get/list`; para metadados/índices, `datastore.databases.getMetadata` e `datastore.schemas.get/list`; para política do projeto, `resourcemanager.projects.getIamPolicy`. Leitura opcional de papéis/serviço demanda autorização própria. Nenhum papel ou permissão foi concedido. As permissões foram conferidas somente em documentação pública oficial, citada no SOP.

Detalhes do formato e limites: [mp-index-certification-design.md](mp-index-certification-design.md). Especificação de migração anterior recebeu aviso de substituição do ready isolado, preservando o histórico.

## Próxima etapa e rollback

**Apto para nova auditoria direcionada e para solicitar autorização de inspeção real estritamente em leitura. Não apto para migração/ativação/publicação imediata.**

Antes de qualquer escrita: aprovar inventário consistente, controle de escritores/deltas, revisor independente e âncoras, renovação/custódia, migrador/journal idempotente e retenção; homologar falhas de lotes e rollback em ambiente isolado; obter autorização própria para cada ação real.

Como nada foi publicado, não há ambiente real a restaurar. Rollback futuro PWA preserva snapshots íntegros das duas releases e páginas legais. Backend exige revisão compatível com certificados válidos e reservas novas; não restaurar certificado vencido/mapa antigo, remover owners ou reabrir GET/nonce. Plano operacional de contingência deverá ser aprovado antes da implantação, não improvisado durante incidente.
