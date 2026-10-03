import 'package:flutter/material.dart';

/// Presentation only: authentication and rollout remain owned by PilotGate.
class OfficialLoginLayout extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final bool googleBusy;
  final String? error;
  final VoidCallback onLogin;
  final VoidCallback? onGoogle;
  final VoidCallback? onResetPassword;
  final VoidCallback? onCreateAccount;

  const OfficialLoginLayout({
    super.key,
    required this.email,
    required this.password,
    required this.busy,
    this.googleBusy = false,
    this.error,
    required this.onLogin,
    this.onGoogle,
    this.onResetPassword,
    this.onCreateAccount,
  });

  static const navy = Color(0xFF031226);
  static const gold = Color(0xFFF7D65C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              key: const ValueKey('official-login-scroll'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/app_icon.png',
                        width: 64,
                        height: 64,
                        semanticLabel: 'Ícone TORICO',
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'TORICO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Seu negócio vendendo.\nOnde você estiver.',
                        key: ValueKey('official-login-slogan'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: gold,
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (googleBusy) const GoogleLoginProgress(),
                      Container(
                        key: const ValueKey('official-login-card'),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E2036),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: gold.withValues(alpha: .22),
                          ),
                        ),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Acesse o TORICO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: email,
                                readOnly: busy,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                style: const TextStyle(color: Colors.white),
                                decoration: _decoration(
                                  'E-mail',
                                  Icons.mail_outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: password,
                                readOnly: busy,
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                style: const TextStyle(color: Colors.white),
                                decoration: _decoration(
                                  'Senha',
                                  Icons.lock_outline,
                                ),
                                onSubmitted: (_) {
                                  if (!busy) onLogin();
                                },
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: busy ? null : onLogin,
                                style: FilledButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: gold,
                                  disabledForegroundColor: Colors.black,
                                  minimumSize: const Size(0, 52),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  busy && !googleBusy
                                      ? 'Entrando…'
                                      : 'Entrar no TORICO →',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: busy ? null : onResetPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: gold,
                                ),
                                child: const Text('Esqueci minha senha'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OU',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('official-google-button'),
                          onPressed: busy ? null : onGoogle,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF242424),
                            disabledBackgroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF242424),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/google_g.png',
                                width: 24,
                                height: 24,
                                excludeFromSemantics: true,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Fazer Login com o Google',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Material(
                        key: const ValueKey('official-create-account-card'),
                        color: const Color(0xFF0E2036),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: busy ? null : onCreateAccount,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ainda não tem conta?',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Criar conta grátis',
                                        style: TextStyle(
                                          color: gold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded, color: gold),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: gold),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: gold),
    ),
  );
}

class GoogleLoginProgress extends StatelessWidget {
  const GoogleLoginProgress({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2036),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OfficialLoginLayout.gold),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: OfficialLoginLayout.gold,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Conectando com Google...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Aguarde a conclusão do login.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}
