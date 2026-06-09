class IntegrationService {
  static const bool isSimulationMode = true;

  Future<bool> connect(String plataforma) async {
    // MVP atual:
    // A conexão ainda é simulada para permitir testes do fluxo do TORICO.
    //
    // Integração real futura:
    // - iniciar autorização da plataforma;
    // - validar retorno no backend;
    // - salvar tokens com segurança fora do Flutter/PWA;
    // - receber webhooks;
    // - gravar vendas reais no Firestore.
    await Future.delayed(const Duration(seconds: 2));

    return true;
  }

  String getConnectionModeLabel() {
    return isSimulationMode ? 'Conexão simulada' : 'Conexão real';
  }

  String getConnectionModeDescription(String plataforma) {
    if (isSimulationMode) {
      return '$plataforma será adicionada em modo de teste. Vendas reais ainda não serão recebidas automaticamente.';
    }

    return '$plataforma será conectada com autorização real da plataforma.';
  }
}
