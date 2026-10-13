# Política de Privacidade — TORICO

**Rascunho inicial de 12/10/2026 — não publicado e não substitui a política atual.**
Antes de publicar: preencher responsável, validar inventário e retenção,
aprovar bases legais/contratos e implementar os fluxos de exclusão exigidos.

## 1. Quem cuida dos seus dados

O TORICO é um aplicativo para acompanhar vendas do negócio.
Responsável pelo serviço: **[nome civil completo do titular — preencher]**.
Contato provisório para suporte e privacidade: sourico.br.ec@gmail.com.
Informações complementares de identificação/contato: **[validar e preencher]**.

Para a conta TORICO e operação do serviço, o responsável define como os dados
são usados. Para informações dos clientes recebidas pelo comerciante, a divisão
de responsabilidades deve ser formalizada conforme a relação aplicável; não
presumimos que o comerciante possa compartilhar qualquer dado sem justificativa.

## 2. Informações usadas

- **Login:** e-mail, identificador Firebase (UID), situação de verificação e,
  quando disponibilizados pelo Google, nome/foto. No login por senha, a senha
  digitada é processada pelo Firebase Authentication, não pelos registros de vendas.
- **Integração:** identificador da conta Mercado Pago, situação da conexão,
  datas e tokens de autorização necessários ao funcionamento.
- **Vendas:** identificadores, valor, plataforma, status, data/hora, totais e
  histórico. Webhooks e respostas da API podem conter outros campos, incluindo
  identificador do pagador quando fornecido; revisar e limitar esses campos ao necessário.
- **Funcionamento:** registros técnicos de acesso/erro e informações tratadas
  pelos serviços de infraestrutura e seus SDKs, conforme a configuração efetiva.
- **Dispositivo:** preferências como áudio e caches locais do TORICO.

Não pedimos senha do Mercado Pago. A autorização ocorre no ambiente oficial
do provedor via OAuth. Eventual verificação por câmera é conduzida pelo Mercado
Pago no navegador externo; o TORICO não implementa captura facial neste escopo.

## 3. Para que usamos

Usamos informações para autenticar sua conta, vincular a integração autorizada,
receber eventos de vendas, evitar duplicidade, apresentar painel/histórico,
atender suporte e proteger o serviço. O painel considera o dia atual; o Básico
mostra uma prévia limitada, sem eliminar o restante do histórico por esse limite.

As bases legais deverão corresponder a cada finalidade, como execução do serviço
solicitado, obrigações legais, exercício de direitos e proteção do serviço quando
cabível. Consentimento é usado quando efetivamente necessário e aplicável, não
como autorização genérica para toda coleta. **[Aprovar o mapa de bases legais.]**

## 4. Serviços envolvidos e segurança

Firebase Authentication, Firestore e infraestrutura Google Cloud participam do
funcionamento. Mercado Pago participa da autorização e consulta dos eventos.
Cada provedor também tem políticas próprias aplicáveis à sua atuação.

Os tokens Mercado Pago são armazenados criptografados no backend e não são
exibidos pelo app nem publicados no documento de status da integração. Usamos
HTTPS e controles de acesso. Não existe promessa de segurança absoluta; medidas
e processos devem ser mantidos e revisados continuamente.

A infraestrutura pode tratar dados fora do Brasil. Antes da publicação, o
responsável deve confirmar locais, contratos e garantias de transferência
internacional adequadas; não afirmar que todos os dados ficam no Brasil.

Não há SDK de publicidade listado na revisão atual do app. Não usamos essa
observação para afirmar ausência de dados técnicos coletados pelos provedores.
Compartilhamentos adicionais deverão ser informados e avaliados antes de ocorrer.

## 5. Desconectar, sair e limpar o dispositivo

Sair encerra a sessão local. Limpar dados do dispositivo remove os caches e
preferências locais do TORICO e encerra a sessão; não exclui integração na nuvem.

Desconectar Mercado Pago marca o vínculo como desconectado e remove os tokens
desse vínculo no TORICO, impedindo novas gravações de vendas para ele. Vendas já
salvas e totais anteriores são mantidos. A autorização no próprio Mercado Pago
não é revogada globalmente por essa ação; pode ser gerenciada também no provedor.
Uma nova conexão exige nova autorização. Essas ações não excluem a conta TORICO.

## 6. Retenção e seus direitos

Manteremos dados pelo período necessário às finalidades informadas e às
obrigações aplicáveis, evitando retenção indefinida sem motivo. **[Definir prazos
de conta, vendas, logs e backups, e procedimento de eliminação antes de publicar.]**
Após término ou solicitação de exclusão, dados sem justificativa de retenção devem
ser eliminados; eventuais exceções devem ser informadas com a razão e o prazo.

Você pode solicitar confirmação de tratamento, acesso, correção e, conforme a
legislação aplicável, portabilidade, informações sobre compartilhamento,
anonimização/exclusão e revogação de consentimento. Escreva ao contato acima.
Pode ser necessária verificação proporcional de identidade para proteger sua conta.
Não envie senha, token ou documentos sensíveis sem orientação por canal adequado.
Reclamações não resolvidas podem ser levadas à ANPD pelos canais oficiais.

**Nota editorial:** atualmente não há fluxo completo de exclusão de conta/dados
no app. Ele e a página externa de solicitação devem ser implementados antes da
submissão às lojas. Este rascunho não afirma que essa função já existe.

## 7. Atualizações

Mudanças relevantes devem ser comunicadas de forma acessível. A versão aprovada
e sua data devem ser mantidas no app e em página pública, sem exigir login.

## Referências para aprovação, não promessas adicionais

[Direitos dos titulares — ANPD](https://www.gov.br/anpd/pt-br/assuntos/titular-de-dados/direito-dos-titulares)
e [transferências internacionais — ANPD](https://www.gov.br/anpd/pt-br/assuntos/assuntos-internacionais/transferencia-internacional-de-dados).
Rascunho sujeito à revisão do responsável e validação jurídica antes de publicação.
