# Páginas legais públicas TORICO — 13/10/2026

Branch: `codex/public-legal-pages`. Responsável público informado pelo titular:
**Elton Cruz**. Contato provisório: `sourico.br.ec@gmail.com`.

## URLs publicadas

- https://www.meutorico.com.br/privacidade
- https://www.meutorico.com.br/termos
- https://www.meutorico.com.br/suporte
- https://www.meutorico.com.br/exclusao-de-conta

Também funcionam na raiz `meutorico.com.br`. Publicação no Firebase Hosting atual,
site `torico-ca479`, autorizada pelo titular após confirmação de que é compartilhado
com o PWA. As mesmas rotas ficam disponíveis no host do app e nos hosts técnicos.
Nenhuma migração de DNS/SAGA foi executada; preview/produção isolada não foram alterados.

## Fonte e escopo

HTMLs em `site-legal/public/{rota}/index.html`, CSS em
`site-legal/public/torico-legal/legal.css`. Identidade navy/dourado, leitura responsiva,
títulos semânticos, links reais, foco visível e link para pular ao conteúdo.
Não há formulário, JavaScript de coleta, SDK ou autenticação nessas páginas.
Não alteram a home, o login nem qualquer arquivo do Flutter.

Base editorial: `docs/legal/privacy-policy-draft.md`, `terms-of-use-draft.md`,
`store-readiness.md` e pacote Play. Textos explicam vendas autorizadas, OAuth,
tokens no backend, desconexão versus logout/limpeza, REDE pausada e solicitação
manual de exclusão. Não prometem processamento de pagamentos, captura de senha
Mercado Pago, exclusão automática ou homologação Android.

## Publicação preservando o PWA

O script `site-legal/publish.cjs` usa API Hosting com autenticação em memória da
instalação oficial Firebase CLI. Clona a versão ativa, acrescenta somente 5 arquivos
e 4 rewrites exatos para servir `/privacidade`, `/termos`, `/suporte` e
`/exclusao-de-conta` antes do catch-all existente do PWA. Mantém os headers e
demais regras anteriores. Não usa `firebase deploy` com build local potencialmente
desatualizado nem recompila o app.

Antes de finalizar/publicar, compara todos os hashes originais e configuração,
verifica que só as adições previstas ocorreram e detecta release concorrente.
O script impede colisões; não repetir para atualizar páginas existentes sem
revisar o processo/diff em missão posterior.

Comando executado, sem credenciais no comando:

```powershell
$env:FIREBASE_TOOLS_ROOT='C:\Users\CRZ\AppData\Roaming\npm\node_modules\firebase-tools'
node site-legal/publish.cjs publish 'C:\Users\CRZ\.codex\visualizations\2026\10\01\01a0f9e6-bde9-7612-a5c8-8e611bb3a4a9\torico-legal-publication'
```

## Releases e backup

- Release anterior: `sites/torico-ca479/releases/1791072326354000`.
- Versão anterior: `sites/torico-ca479/versions/bea5a7f88acf7775`.
- Release nova: `sites/torico-ca479/releases/1791861693429000`.
- Versão nova: `sites/torico-ca479/versions/97dc2d1ac5a07198`.
- **48 arquivos originais preservados**, nenhum removido ou modificado.
- Backup do inventário/configuração e relatórios locais:
  `C:/Users/CRZ/.codex/visualizations/2026/10/01/01a0f9e6-bde9-7612-a5c8-8e611bb3a4a9/torico-legal-publication/`.
  Arquivos `hosting-before.json`, `hosting-after.json`, `http-validation.json`;
  sem tokens ou credenciais. A versão antiga fica no histórico Hosting para rollback.

Rollback, somente quando autorizado: Firebase Console > Hosting > site
torico-ca479 > histórico de releases > restaurar a release/versão anterior acima.
Isso remove as novas rotas/regras e restaura exatamente o estado anterior, sem
alterar Auth/DNS/backend. Verificar antes se outra release posterior foi publicada;
não sobrescrever trabalho novo. Confirmar home/app e arquivos Flutter após rollback.

## Verificações realizadas

| Verificação | Resultado |
|---|---|
| 4 rotas em www, raiz, app e torico-ca479.web.app | 16 respostas HTTPS 200; conteúdo byte a byte igual aos HTMLs de origem |
| CSS público | HTTPS 200, conteúdo exato |
| 4 rotas HTTP em www | Redirecionamento para HTTPS |
| TLS | HTTPS sem ignorar validação de certificado |
| PWA index em app, raiz, www, web.app e firebaseapp.com | HTTP 200 e hash da versão anterior idêntico nos 5 hosts |
| Inventário PWA | Todos os 48 arquivos com hashes preservados |
| Rotas de navegação legais | Destinos internos são as 4 rotas validadas; mailto e link do app explícitos |
| Login/OAuth real | Não executado; nenhuma conta/dado alterado |

## Pendências de revisão humana

- Revisão jurídica dos textos, identificação complementar e mapa de bases legais.
- Prazos concretos de retenção de conta/vendas/logs/backups e exceções legais.
- Contratos, papéis dos prestadores e garantias de transferências internacionais.
- Processo de atendimento/exclusão: confirmar identidade, executar eliminação,
  informar retenções e resultado; página publicada não implementa esse backend.
- Opção de exclusão dentro do app ainda pendente para Google Play.
- Validar monitoramento do e-mail de suporte e definir contato profissional.
- Auditoria de dados/SDKs e Data safety; homologação Android ainda pendente.

Sem deploy de app/backend, alteração de OAuth, webhook, secrets, Cloud Run, Auth,
DNS, REDE/Scheduler ou banco. Nenhum APK/AAB versionado ou app enviado à Play.
