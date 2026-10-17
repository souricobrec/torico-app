# TORICO — certificação independente do índice MP

Branch: `codex/index-certification-readiness`, base `41e260b`. Código e validação sintética; não é autorização para configurar, certificar, migrar ou publicar em produção.

## Mudança de significado de ready

`ready` passa a indicar somente que existe uma referência candidata. Não prova completude. O runtime também exige certificado assinado por **duas chaves Ed25519 distintas**, previamente confiadas pela configuração pública controlada do backend, projeto/epoch/revisão compatíveis, prazo válido e evidência íntegra do merchant consultado.

Chaves públicas não vêm do próprio certificado. Configurações futuras: `MP_INDEX_CERTIFIER_PUBLIC_KEY` e `MP_INDEX_REVIEWER_PUBLIC_KEY` (PEM SPKI Ed25519). Sem ambas, falha segura. Não há chaves reais no repositório nem alterações de configuração implantada. Provisionar âncoras, custodiar chaves privadas dos revisores e aprovar sua independência são tarefas futuras autorizadas separadamente. A chave privada não pertence ao backend nem ao Firestore.

O código não descobre credenciais, coleta infraestrutura ou assina certificados reais. `reconcileInventory` é função pura; o emissor de certificados existente nos testes gera chaves **efêmeras em memória**, somente para `demo-*`.

## Reconciliação e evidência

Entradas do reconciliador: inventário consistente de `sources` (paths e campos mínimos de integrações MP/aliases) e `owners` propostos. Caminhos determinam UID/merchant; não se aceita UID arbitrário associado a integração de outro caminho. Outras plataformas são ignoradas; plataforma MP em caminho inesperado é erro. Caminho duplicado, ID irrecuperável, owner omitido, entry extra, estado incorreto ou titular conflitante impedem produzir evidência.

Agrupamento por ID canônico: inteiro seguro/string decimal/padded. Um UID gera `owned`; mais de um UID exige `conflict`. Inclui reservas desconectadas e aliases. IDs com precisão perdida ou formato sem identidade recuperável não são corrigidos por aproximação. Exigem revisão antes de certificar ausência.

Saída: hashes determinísticos de origem e índice, contagens e 256 fragmentos por prefixo do SHA-256 do merchant. Cada fragmento contém mapa de claims canônicos. Não contém tokens, e-mails ou vendas; UIDs são privados. Fragmento limitado a 512.000 bytes de JSON canônico para margem operacional perante o documento Firestore. Excesso bloqueia certificação: requer evolução de formato revisada, não truncamento. Não há limite global de 500 registros ou varredura no resolvedor.

Certificado em `mp_index_certificates/{SHA256(payloadCanonico)}`:

- `payload.version = 1`, `projectId`, `epoch`, `sourceRevision` (64 hex), `writerProtocol = certified-index-v1`;
- `capturedAtMs`, `issuedAtMs`, `expiresAtMs`;
- `sourceDigest`, `indexDigest`, `sourceCount`, `merchantCount`, `shardDigests` (256 prefixos);
- `signatures`: duas assinaturas destacadas do payload canônico, uma para cada âncora confiada.

Marcador `mp_ownership_index/active`: `version:1`, `state:ready`, `epoch`, `certificateId`, `sourceRevision`, `writerProtocol`. Fragmentos não vazios: `mp_index_evidence/{certificateId}_{prefixo}`. Nome por certificado impede renovar evidências sobrescrevendo as de uma certificação anterior. Um fragmento atestado como vazio não precisa existir no banco; o hash vazio assinado comprova essa ausência na base inventariada.

Na transação: validar marcador → certificado/assinaturas → fragmento requerido/hash → owner atual → integração privada quando resolver. Se a base certificada aponta um titular e o owner sumiu ou mudou, retornar erro, nunca declarar merchant livre. Claim `conflict` bloqueia o merchant afetado. Fragmento ausente/alterado bloqueia os merchants desse fragmento; não usar fallback de scan. Reconexão atualiza campos operacionais com merge, preservando evidências extras. UID e merchant são obtidos/validados pelo fluxo autenticado, nunca de metadado livre.

## Atualidade, independência e limites de confiança

O protótipo impõe no máximo **24 horas entre captura e expiração**, rejeita emissão futura e certificado vencido. Tests usam lease menor. Este é limite conservador de segurança, **não SLA operacional aprovado**. Implantar assim sem processo de renovação causaria interrupção ao expirar. Aprovar duração, renovação, monitoramento, custódia/rotação de âncoras e contingência antes de ativar.

Hashes/assinaturas demonstram integridade e concordância dos revisores sobre o inventário recebido. Não demonstram, por mágica, que o coletor leu todo o mundo real. Dois revisores que assinarem a mesma coleta truncada podem atestar uma omissão. A coleta precisa de readTime consistente, paginação reconciliada, contagens, prova de conclusão, controle de todos os escritores e revisão independente efetiva. Só flags `complete` ou `writerFence` seriam insuficientes; o runtime não as usa como prova.

Mudanças posteriores feitas exclusivamente pelo protocolo novo são transacionais. Alterações externas/administrativas não coordenadas, exclusão de reservas novas após a base e comprometimento dos dois signatários continuam fora da garantia. Bloquear esses escritores, auditar deltas e proteger reservas é condição operacional obrigatória. O certificado não autoriza transferências nem substitui IAM.

O reconciliador não tem coletor, journal, migrador, assinador real ou endpoint de ativação. Esses componentes ainda precisam de desenho/aprovação próprios. Nenhum documento real foi gravado. As Rules deny-all atuais já negam acesso cliente às novas coleções; IAM real não foi verificado ou modificado.

## Custos e implantação futura

Por tentativa, antes de retries: resolução com claim legado não vazio = até cinco leituras (marcador, certificado, fragmento, owner, integração). Prefixo certificado vazio dispensa fragmento (até quatro). Owner novo ausente: três/quatro, conforme prefixo. Callback: geração + marcador + certificado + fragmento opcional + owner = quatro/cinco leituras, além do consumo do state; grava owner/integração/status como antes. Verificação criptográfica ocorre localmente a cada operação, sem cache que prolongue validade indevidamente.

Certificação administrativa: inventário O(N+A), reconciliação O(N+A), até M owners e 256 fragmentos + um certificado + um marcador, mais journal. Revisão dupla pode exigir segunda captura/verificação. Não houve estimativa monetária: região, preços e volumes reais não foram consultados. Leituras diretas não precisam de índice composto novo; coleta pode depender de índices existentes e sua revisão é parte da inspeção futura.

Não publicar até: inspeção real autorizada em leitura, auditoria deste novo formato, aprovação dos revisores/âncoras/renovação, migrador idempotente com falhas parciais, plano de bloqueio de escritores e rollback compatível. Renovar certificado não transfere UID, não limpa aliases e não apaga tokens. Nunca restaurar certificado vencido ou índice antigo por cima de novos vínculos. Rollback exige evidência válida e preservação das reservas/deltas; não reabrir GET/nonce ou voltar à confiança em ready isolado.
