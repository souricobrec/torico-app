# Checklist Apple App Store — TORICO

Preparação em 12/10/2026. Windows disponível; build iOS não exigido nesta missão.

## Titular e identidade

- [ ] Aprovar conta individual: nome civil do titular será o vendedor; marca
  do app continua TORICO. Não prometer vendedor corporativo usando conta pessoal.
- [ ] Só depois de autorização: Apple Account com 2FA, dados/documentos do
  titular, adesão e taxa vigente. Nenhuma conta/compra feita aqui.
- [ ] Confirmar elegibilidade individual diante da regra de serviços regulados;
  TORICO acompanha vendas, não executa pagamentos/crédito. Classificação é
  avaliada pela Apple, não garantida pela categoria Business sugerida.
- [ ] Aprovar bundle ID, registrar App ID, certificados/profiles em missão
  autorizada; não usar definitivamente com.example.vendaon sem decisão.

## Técnica nativa — bloqueios atuais

- [ ] Obter macOS/Xcode; conferir requisitos vigentes de upload. Fonte consultada:
  desde 28/04/2026, Xcode 26+ e SDK iOS 26+; isso não é o deployment target mínimo.
- [ ] Configurar Firebase iOS: hoje currentPlatform lança UnsupportedError.
  Integrar configuração oficial, capabilities e URLs de login sem segredos no app.
- [ ] Alinhar deployment target: projeto está em iOS 13.0, mas os podspecs locais
  de firebase_core 4.10.0 e firebase_auth 6.5.2 declaram mínimo 15.0.
- [ ] Adaptar Google login web para SDK/fluxo nativo mantendo associação ao mesmo
  Firebase UID. Avaliar **4.8**: login equivalente com requisitos de privacidade,
  normalmente Sign in with Apple, ou exceção justificável. Não implementado aqui.
- [ ] Gate nativo hoje não aplica allowlist do PWA; corrigir antes de distribuir.
- [ ] Testar retorno OAuth externo para o app: hoje callback retorna ao PWA e
  main só processa parâmetros na web. Não alterar callback neste checklist.
- [ ] Personalizar LaunchScreen nativo (LaunchImage atual 1×1), testar iPhone/iPad.
- [ ] Conferir ícone marketing 1024×1024 opaco, tamanhos gerados e máscaras;
  asset existente RGB sem alpha, identidade navy/dourado mantida.
- [ ] Auditar Info.plist, entitlements, privacy manifests dos SDKs e APIs de
  motivo obrigatório. Não inventar permissões câmera/microfone/localização.
- [ ] Revisar declaração de export compliance/criptografia segundo APIs/SDKs
  efetivamente usados; tokens criptografados no backend não bastam para responder.
- [ ] Gerar archive/IPA de distribuição no Mac, assinar e validar; usar TestFlight
  apenas em missão autorizada, depois testes físicos incluindo acessibilidade.

## App Store Connect e conteúdo

- [ ] Nome até 30, subtítulo até 30, descrição e palavras-chave até 100 caracteres
  no campo de keywords; ver [rascunhos](store-listing-draft.md).
- [ ] Categoria sugerida Business; responder classificação etária vigente.
- [ ] Informar Support URL funcional com contato, Privacy Policy URL pública,
  responsável/copyright e contato específico para App Review.
- [ ] Screenshots reais da UI iPhone nas resoluções aceitas para os dispositivos
  selecionados; também iPad se suportado. Preparar 4–6 telas e conferir a tabela
  atual de tamanhos, sem fingir que prints do PWA são homologação nativa.
- [ ] Não expor credenciais, vendas reais, dados de clientes ou OAuth state.
- [ ] Preencher App Privacy, incluindo SDKs, identidade, dados comerciais e
  técnicos vinculados; distinguir finalidade e tracking corretamente.
- [ ] Implementar início de exclusão de conta **dentro do app** para quem cria
  conta. Suporte por e-mail sozinho não demonstra cumprimento da regra.
- [ ] Revisar planos/assinaturas e regras IAP antes de oferecer Plus pago.
- [ ] Aprovar textos legais e sincronizá-los com as telas do app.

## Reviewer

- [ ] Conta demo dedicada operante, com login/senha privados e acesso já liberado.
- [ ] Dados fictícios e instruções transparentes; não depender de OAuth real,
  câmera ou acesso à conta financeira pessoal do reviewer.
- [ ] Se Mercado Pago não puder ser opcional ainda, implementar experiência
  demonstrativa isolada primeiro. Hoje não há modo demo implementado.
- [ ] Explicar recurso principal, desconexão, histórico limitado e REDE pausada;
  nenhum fluxo deve ficar oculto da revisão. Ver [plano demo](store-demo-account.md).
- [ ] Não enviar binário nesta missão; revisão real e aprovação são futuras.

## Referências

[Inscrição individual](https://developer.apple.com/programs/enroll/),
[Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
[exclusão de conta](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/),
[requisitos SDK](https://developer.apple.com/news/upcoming-requirements/?id=02032026a),
[screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/),
[App Privacy](https://developer.apple.com/app-store/app-privacy-details/).
