class Sale {
  final double amount;
  final DateTime createdAt;

  /// Origem da venda:
  /// - simulator: venda criada pelo botão "+ Nova Venda"
  /// - webhook: venda recebida futuramente de uma plataforma real
  final String source;

  /// Status da venda:
  /// - approved
  /// - cancelled
  /// - refunded
  /// - pending
  final String status;

  /// ID externo da venda na plataforma real.
  /// Exemplo futuro: ID do pagamento no Mercado Pago.
  final String? externalId;

  /// Dados brutos recebidos de uma integração real.
  /// No simulador fica vazio.
  final Map<String, dynamic>? rawPayload;

  Sale({
    required this.amount,
    required this.createdAt,
    this.source = 'simulator',
    this.status = 'approved',
    this.externalId,
    this.rawPayload,
  });
}
