# Checklist Google Play — TORICO

Preparação em 12/10/2026. Não criar conta nem enviar artefato nesta missão.

## Conta e cadastro

- [ ] Titular aprovar publicação como pessoa física e exposição dos campos
  obrigatórios de identidade/contato; preparar identidade verificada, endereço,
  e-mail e telefone exigidos em canal privado, nunca no Git.
- [ ] Só após autorização: abrir conta, cumprir verificação, taxa vigente e
  verificação de dispositivo Android quando solicitada; não realizado aqui.
- [ ] Confirmar elegibilidade do tipo de conta para os recursos declarados.
- [ ] Reservar nome TORICO/identificador definitivo antes do primeiro envio.
- [ ] Definir países, idioma pt-BR, distribuição/preço (não definidos aqui).
- [ ] Responder classificação IARC, público-alvo e declaração de anúncios,
  acesso ao app e recursos financeiros de forma fiel ao binário.

## Artefato

- [ ] Substituir ID placeholder de forma coordenada com Firebase e assinaturas.
- [ ] Gerar keystore de upload com autorização; backup privado seguro. Nunca
  versionar keystore, senhas ou key.properties. Configurar Play App Signing.
- [ ] Gerar **AAB de distribuição**, não usar APK assinado em debug para upload.
- [ ] Verificar target API: na consulta atual, novos apps precisam de API 36+
  desde 31/08/2026. Flutter define o target; inspecionar o artefato final.
- [ ] Verificar minSdk, suporte 64-bit, bibliotecas nativas/alinhamento 16 KB,
  tamanho, funcionamento offline/sem conexão e relatório pré-lançamento.
- [ ] Auditar manifest mesclado; manter apenas permissões justificadas.
- [ ] Testar gate nativo, Google login, e-mail/senha, recuperação, desconexão,
  limpeza local e retorno OAuth no Android físico. Não basta o PWA funcionar.

## Ficha e materiais

- [ ] Nome TORICO; descrição curta até 80 e longa até 4.000 caracteres.
- [ ] Ícone Play 512×512 PNG, até 1.024 KB; derivar do asset oficial sem redesign.
- [ ] Feature graphic 1024×500 JPEG/PNG sem alpha, ainda não criado.
- [ ] Pelo menos 2 screenshots; preparar 4–6 reais: login, painel, histórico
  básico, Conta e confirmação de desconexão. Até 8 por tipo de dispositivo;
  atender dimensões/formato oficiais. Preparar tablet só se declarar suporte.
- [ ] Usar dados fictícios identificados; sem tokens, e-mails/UIDs de usuários
  reais ou marcas de plataformas apresentadas como ativas quando não estão.
- [ ] REDE Pausada; demais em preparação. Não prometer notificações em segundo
  plano, relatórios/exportações ou integrações não entregues.
- [ ] Informar e-mail de suporte, website e política HTTPS pública sem login.
- [ ] Aprovar [textos](store-listing-draft.md) e [demo](store-demo-account.md).

## Privacidade e revisão

- [ ] Publicar política final com identidade do responsável e contato.
- [ ] Preencher Data safety com inventário de dados, SDKs, usos e retenção;
  não marcar “nenhum dado” por ser Firebase/serviço de terceiro.
- [ ] Implementar caminho de exclusão de conta no app **e** página externa
  funcional de solicitação. Logout/limpar/desconectar não satisfazem exclusão.
- [ ] Definir o que deve ser eliminado e o que tem retenção legal justificada.
- [ ] Dar acesso ao reviewer via conta dedicada e dados demo; todas as áreas
  devem ser revisáveis sem conta Mercado Pago pessoal/verificação facial.
- [ ] Não liberar faturamento/Plus pago sem avaliar política de pagamentos.
- [ ] Para nova conta pessoal abrangida pela regra: teste fechado com pelo menos
  **12 participantes inscritos continuamente por 14 dias**, depois solicitar
  acesso à produção. Teste interno não substitui essa condição.
- [ ] Publicação e rollout somente por nova autorização; guardar rollback.

## Referências

[Teste pessoal](https://support.google.com/googleplay/android-developer/answer/14151465),
[target API](https://developer.android.com/google/play/requirements/target-sdk),
[arte gráfica](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en),
[exclusão](https://support.google.com/googleplay/android-developer/answer/13327111),
[Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
