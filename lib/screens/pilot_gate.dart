import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/pilot_access_service.dart';
import 'launch_block_screen.dart';
import '../widgets/official_login_layout.dart';

/// Keeps the entire navigation stack behind the authenticated pilot UI gate.
class PilotGate extends StatefulWidget {
  final PilotAccessService access;
  final Stream<PilotIdentity?> authChanges;
  final PilotIdentity? initialIdentity;
  final Future<void> Function()? signInGoogle;
  final Future<void> Function(String email)? resetPassword;
  final Future<void> Function(String email, String password)? createAccount;
  final Future<void> Function(String email, String password) signIn;
  final Future<void> Function() signOut;
  final WidgetBuilder appBuilder;

  const PilotGate({
    super.key,
    required this.access,
    required this.authChanges,
    required this.initialIdentity,
    this.signInGoogle,
    this.resetPassword,
    this.createAccount,
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

  Future<void> googleLogin() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.signInGoogle!();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => error = AuthService.googleErrorMessage(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = AuthService.googleErrorMessage('unknown'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recoverPassword() async {
    if (email.text.trim().isEmpty) {
      setState(() => error = 'Digite seu e-mail para recuperar a senha.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.resetPassword!(email.text.trim());
      if (mounted) {
        setState(
          () => error =
              'Se houver uma conta elegível, você receberá as instruções por e-mail.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Não foi possível enviar as instruções. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> registerAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar conta grátis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O acesso ao app continua sujeito à liberação da sua conta.',
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha (mínimo 6 caracteres)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Criar conta grátis'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (!email.text.trim().contains('@') || password.text.length < 6) {
      setState(
        () => error =
            'Informe um e-mail válido e uma senha de pelo menos 6 caracteres.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.createAccount!(email.text.trim(), password.text);
      password.clear();
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível criar a conta. Se já tem conta, entre ou recupere sua senha.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.access.requested) return const LaunchBlockScreen();
    return StreamBuilder<PilotIdentity?>(
      stream: widget.authChanges,
      initialData: widget.initialIdentity,
      builder: (context, snapshot) {
        final identity = snapshot.data;
        final uid = identity?.uid;
        Widget content;
        if (snapshot.hasError) {
          content = const LaunchBlockScreen();
        } else if (widget.access.allows(
          uid,
          email: identity?.email,
          emailVerified: identity?.emailVerified ?? false,
        )) {
          content = Navigator(
            key: ValueKey('pilot-app-$uid'),
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: widget.appBuilder),
          );
        } else if (uid != null) {
          content = const Scaffold(
            backgroundColor: Color(0xFF031226),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Acesso não liberado. Entre com uma conta autorizada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          );
        } else if (widget.access.official) {
          content = OfficialLoginLayout(
            email: email,
            password: password,
            busy: busy,
            error: error,
            onLogin: login,
            onGoogle: widget.signInGoogle == null ? null : googleLogin,
            onResetPassword: widget.resetPassword == null
                ? null
                : recoverPassword,
            onCreateAccount: widget.createAccount == null
                ? null
                : registerAccount,
          );
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
                        Text(
                          widget.access.official
                              ? 'TORICO'
                              : 'Acesso piloto TORICO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        if (widget.access.official) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Seu negócio vendendo. Onde você estiver.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFF7D65C),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Acesse o TORICO',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
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
                        if (widget.signInGoogle != null)
                          OutlinedButton(
                            onPressed: busy ? null : googleLogin,
                            child: const Text('Entrar com Google'),
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
            if (!widget.access.official || uid != null)
              Material(
                color: const Color(0xFF031226),
                child: SafeArea(
                  top: false,
                  child: TextButton(
                    onPressed: exit,
                    child: Text(
                      widget.access.official
                          ? 'Sair da conta'
                          : 'Sair do modo piloto',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
