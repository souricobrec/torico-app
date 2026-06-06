class IntegrationService {
  Future<bool> connect(String plataforma) async {
    await Future.delayed(const Duration(seconds: 2));

    return true;
  }
}
