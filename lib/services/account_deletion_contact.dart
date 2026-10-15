/// Prepares a manual request. Never registers or deletes an account.
abstract final class AccountDeletionContact {
  static const email = 'sourico.br.ec@gmail.com';
  static final publicPage = Uri.https(
    'www.meutorico.com.br',
    '/exclusao-de-conta',
  );
  static const subject = 'Exclusão de conta TORICO';
  static const body =
      'Quero solicitar a exclusão da minha conta TORICO e dos dados associados.\n\nE-mail da conta TORICO: [preencher]\n\nPor favor, confirme o recebimento, as etapas de verificação de identidade e a conclusão, incluindo eventuais retenções com motivo e prazo. Não incluirei senhas, tokens ou códigos de autenticação nesta mensagem.';
  // mailto spaces must not be encoded as plus signs.
  static Uri get emailDraft => Uri(
    scheme: 'mailto',
    path: email,
    query:
        'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );
}
