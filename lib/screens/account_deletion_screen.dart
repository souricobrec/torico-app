import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../services/account_deletion_contact.dart';

class AccountDeletionScreen extends StatefulWidget {
  final Future<bool> Function(Uri)? openExternal;
  const AccountDeletionScreen({super.key, this.openExternal});
  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool confirmed = false, busy = false;
  String? notice;
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
                const Text(
                  'Solicitação com atendimento manual',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Este fluxo prepara um e-mail. Não envia a mensagem, não registra um pedido no servidor e não exclui sua conta ou seus dados.',
                  style: TextStyle(color: Colors.white, height: 1.5),
                ),
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
                  'Envie o e-mail preferencialmente pela conta cadastrada no TORICO. O responsável verificará sua identidade antes de processar o pedido e confirmará a conclusão. Não envie senha, token, código OAuth ou documento nesta mensagem.',
                ),
                section(
                  'Como acompanhar',
                  'Após enviar, aguarde a confirmação de recebimento e acompanhe respondendo à mesma conversa com o suporte. Peça a confirmação final e informações sobre eventuais retenções. Abrir o e-mail não comprova envio, recebimento ou exclusão.',
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldLight,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: confirmed && !busy
                      ? () =>
                            open(AccountDeletionContact.emailDraft, email: true)
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
