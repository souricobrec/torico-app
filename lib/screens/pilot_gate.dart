import 'package:flutter/material.dart';
import '../services/pilot_access_service.dart';
import 'launch_block_screen.dart';

/// Keeps the entire navigation stack behind the authenticated pilot UI gate.
class PilotGate extends StatefulWidget {
  final PilotAccessService access;
  final Stream<String?> authChanges;
  final String? initialUid;
  final Future<void> Function(String email, String password) signIn;
  final Future<void> Function() signOut;
  final WidgetBuilder appBuilder;

  const PilotGate({
    super.key,
    required this.access,
    required this.authChanges,
    required this.initialUid,
    required this.signIn,
    required this.signOut,
    required this.appBuilder,
  });

  @override
  State<PilotGate> createState() => _PilotGateState();
}

class _PilotGateState extends State<PilotGate> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.signIn(email.text.trim(), password.text);
      password.clear();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível entrar. Confira seus dados.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> exit() async {
    // Hide and destroy nested app routes before asynchronous sign-out.
    final clearing = widget.access.clear();
    setState(() {});
    await clearing;
    try {
      await widget.signOut();
    } catch (_) {
      /* UI remains blocked. */
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.access.requested) return const LaunchBlockScreen();
    return StreamBuilder<String?>(
      stream: widget.authChanges,
      initialData: widget.initialUid,
      builder: (context, snapshot) {
        final uid = snapshot.data;
        Widget content;
        if (snapshot.hasError) {
          content = const LaunchBlockScreen();
        } else if (widget.access.allows(uid)) {
          content = Navigator(
            key: ValueKey('pilot-app-$uid'),
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: widget.appBuilder),
          );
        } else if (uid != null) {
          content = const LaunchBlockScreen();
        } else {
          content = Scaffold(
            backgroundColor: const Color(0xFF031226),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Acesso piloto TORICO',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextField(
                          controller: password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                          onSubmitted: (_) {
                            if (!busy) login();
                          },
                        ),
                        const SizedBox(height: 20),
                        if (error != null)
                          Text(
                            error!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        FilledButton(
                          onPressed: busy ? null : login,
                          child: Text(busy ? 'Entrando…' : 'Entrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(child: content),
            Material(
              color: const Color(0xFF031226),
              child: SafeArea(
                top: false,
                child: TextButton(
                  onPressed: exit,
                  child: const Text('Sair do modo piloto'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
