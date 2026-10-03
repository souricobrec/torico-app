/// UI rollout policy only. Does not modify connections, cached data or sales.
class ActiveSalesSources {
  static bool isActive(String platform) =>
      platform.trim().toLowerCase() == 'mercado pago';
  static List<String> connected(Iterable<String> platforms) =>
      platforms.any(isActive) ? ['Mercado Pago'] : [];
  static String status(Iterable<String> platforms) =>
      connected(platforms).isEmpty
      ? 'Nenhuma fonte ativa'
      : 'Monitorando 1 fonte de venda: Mercado Pago';
  static String panelLabel(Iterable<String> platforms) =>
      connected(platforms).isEmpty
      ? 'Nenhuma plataforma ativa'
      : 'Plataforma ativa: Mercado Pago';
  static const redeStatus = 'Pausada';
}
