import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../services/account_deletion_contact.dart';
import '../services/account_deletion_intake_service.dart';
import '../services/auth_service.dart';

class AccountDeletionScreen extends StatefulWidget {
  final Future<bool> Function(Uri)? openExternal;
  final bool intakeEnabled;
  final AccountDeletionIntakeService? intakeService;
  final Future<void> Function()? reauthenticate;
  const AccountDeletionScreen({
    super.key,
    this.openExternal,
    this.intakeEnabled = AccountDeletionIntakeService.configuredEnabled,
    this.intakeService,
    this.reauthenticate,
  });
  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool confirmed = false, busy = false;
  String? notice;
  DeletionRequestStatus? requestStatus;
  late final intake =
      widget.intakeService ??
      AccountDeletionIntakeService(enabled: widget.intakeEnabled);

  Future<bool> recentAuthentication() async {
    if (widget.reauthenticate != null) {
      await widget.reauthenticate!();
      return true;
    }
    final auth = AuthService();
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('No session');
    final passwordRequired = auth.requiresPasswordReauthentication;
    final answer = await showDialog<String>(
      context: context,
      builder: (_) =>
          _RecentAuthenticationDialog(passwordRequired: passwordRequired),
    );
    if (answer == null) return false;
    if (!mounted || auth.currentUser?.uid != uid) {
      throw StateError('Session changed');
    }
    await auth.reauthenticateCurrentUser(
      password: passwordRequired ? answer : null,
    );
    return true;
  }

  Future<void> submitRequest() async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
    });
    var attempted = false;
    try {
      if (!await recentAuthentication()) {
        if (mounted) {
          setState(
            () => notice =
                'Confirmação não concluída. Nenhum pedido foi enviado.',
          );
        }
        return;
      }
      attempted = true;
      final status = await intake.submit();
      if (mounted) {
        setState(() {
          requestStatus = status;
          notice =
              'Pedido recebido pelo servidor. Sua conta ainda não foi excluída.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => notice = attempted
              ? 'Recebimento não confirmado. Consulte o status ou tente novamente. Sua conta não foi apresentada como excluída.'
              : 'Não foi possível confirmar sua identidade. Nenhum pedido foi enviado.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> checkRequest() async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      final status = await intake.current();
      if (mounted) {
        setState(() {
          requestStatus = status;
          notice = status == null
              ? 'Nenhuma solicitação registrada foi encontrada para esta conta.'
              : 'Estado consultado no servidor. Recebimento não significa exclusão concluída.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => notice =
              'Não foi possível consultar agora. O estado da solicitação não foi atualizado.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> open(Uri uri, {bool email = false}) async {
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      final opened =
          await (widget.openExternal?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!mounted) return;
      setState(
        () => notice = opened
            ? (email
                  ? 'E-mail aberto. Envio não confirmado: revise e envie no seu aplicativo de e-mail. O aplicativo não confirmou o envio ou o registro da solicitação.'
                  : 'Página externa aberta. Nenhuma solicitação foi registrada pelo aplicativo.')
            : 'Não foi possível abrir. Copie o e-mail abaixo e envie pelo seu serviço de e-mail. Nenhuma solicitação foi registrada.',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => notice =
              'Não foi possível abrir. Use o e-mail de suporte abaixo. Nenhuma solicitação foi registrada.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Excluir minha conta'),
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.intakeEnabled
                      ? 'Solicitação de exclusão de conta'
                      : 'Solicitação com atendimento manual',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.intakeEnabled
                      ? 'Você pode registrar um pedido autenticado e consultar seu protocolo. Esta etapa não exclui a conta, não remove dados e não desconecta integrações.'
                      : 'Este fluxo prepara um e-mail. Não envia a mensagem, não registra um pedido no servidor e não exclui sua conta ou seus dados.',
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
                if (widget.intakeEnabled) ...[
                  if (requestStatus != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            'Protocolo: ${requestStatus!.protocol}',
                            style: const TextStyle(color: AppColors.goldLight),
                          ),
                          Text(
                            'Estado: ${requestStatus!.label}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  CheckboxListTile(
                    value: confirmed,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => confirmed = v ?? false),
                    title: const Text(
                      'Solicito a exclusão da conta TORICO e entendo que o recebimento não conclui a exclusão.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: confirmed && !busy ? submitRequest : null,
                    child: const Text('Registrar solicitação autenticada'),
                  ),
                  TextButton(
                    onPressed: busy ? null : checkRequest,
                    child: const Text('Consultar minha solicitação'),
                  ),
                  if (busy) const LinearProgressIndicator(),
                ],
                section(
                  'Informações abrangidas pela exclusão',
                  'Conta de autenticação e perfil TORICO; vínculos de integrações e tokens OAuth criptografados; histórico de vendas, totais diários e dados associados à conta, ressalvadas retenções legalmente necessárias. Sua conta e seus registros no Mercado Pago não são excluídos por este pedido.',
                ),
                section(
                  'Possíveis retenções',
                  'Somente dados cuja retenção seja legalmente necessária poderão ser mantidos. O responsável deverá informar quais dados, motivo e prazo. Os critérios de retenção e backups ainda estão em revisão; não há prazo automático de conclusão definido.',
                ),
                section(
                  'Como será processado',
                  widget.intakeEnabled
                      ? 'O servidor registra apenas o recebimento do pedido. Esta fase não executa exclusão, não bloqueia vendas ou integrações e não revoga credenciais. O atendimento e qualquer processamento posterior dependem de revisão e autorização.'
                      : 'Envie o e-mail preferencialmente pela conta cadastrada no TORICO. O responsável verificará sua identidade antes de processar o pedido e confirmará a conclusão. Não envie senha, token, código OAuth ou documento nesta mensagem.',
                ),
                section(
                  'Como acompanhar',
                  widget.intakeEnabled
                      ? 'Use Consultar minha solicitação na mesma conta TORICO. Preserve o protocolo. Para dúvidas, contate o suporte informando o protocolo, sem enviar senhas ou tokens. Não há exclusão automática nesta fase.'
                      : 'Após enviar, aguarde a confirmação de recebimento e acompanhe respondendo à mesma conversa com o suporte. Peça a confirmação final e informações sobre eventuais retenções. Abrir o e-mail não comprova envio, recebimento ou exclusão.',
                ),
                section(
                  'São ações diferentes',
                  'Sair encerra a sessão. Limpar dados deste dispositivo remove dados locais e sai. Desconectar Mercado Pago remove o vínculo no TORICO, mantendo vendas antigas. Solicitar exclusão pede a eliminação da conta e dos dados associados.',
                ),
                const SelectableText(
                  AccountDeletionContact.email,
                  style: TextStyle(color: AppColors.goldLight),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          await Clipboard.setData(
                            const ClipboardData(
                              text: AccountDeletionContact.email,
                            ),
                          );
                          if (mounted) {
                            setState(
                              () => notice =
                                  'E-mail copiado. Nenhuma solicitação enviada ou registrada.',
                            );
                          }
                        },
                  child: const Text('Copiar e-mail de suporte'),
                ),
                if (!widget.intakeEnabled)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.goldLight,
                    checkColor: Colors.black,
                    value: confirmed,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => confirmed = v ?? false),
                    title: const Text(
                      'Entendo que devo revisar e enviar o e-mail para solicitar a exclusão.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 12),
                if (!widget.intakeEnabled)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldLight,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: confirmed && !busy
                        ? () => open(
                            AccountDeletionContact.emailDraft,
                            email: true,
                          )
                        : null,
                    child: Text(
                      busy ? 'Abrindo...' : 'Preparar solicitação por e-mail',
                    ),
                  ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => open(AccountDeletionContact.publicPage),
                  child: const Text('Ver página pública de exclusão'),
                ),
                if (notice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        notice!,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget section(String title, String body) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.goldLight,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: Colors.white70, height: 1.5)),
      ],
    ),
  );
}

class _RecentAuthenticationDialog extends StatefulWidget {
  final bool passwordRequired;
  const _RecentAuthenticationDialog({required this.passwordRequired});
  @override
  State<_RecentAuthenticationDialog> createState() =>
      _RecentAuthenticationDialogState();
}

class _RecentAuthenticationDialogState
    extends State<_RecentAuthenticationDialog> {
  final password = TextEditingController();
  @override
  void dispose() {
    password.clear();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirme sua conta TORICO'),
    content: widget.passwordRequired
        ? TextField(
            controller: password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Senha TORICO (não Mercado Pago)',
            ),
          )
        : const Text(
            'Confirme a mesma conta Google para registrar o pedido. Nenhuma exclusão será executada.',
          ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(
          context,
          widget.passwordRequired ? password.text : '',
        ),
        child: const Text('Confirmar identidade'),
      ),
    ],
  );
}
