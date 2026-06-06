import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/app_colors.dart';
import '../core/app_texts.dart';
import 'login_screen.dart';
import '../widgets/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final AuthService _authService = AuthService();

  bool carregando = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 120),
              Image.asset(
                'assets/images/torico_logo.png',
                width: largura < 600 ? largura * 0.75 : 420,
              ),

              const SizedBox(height: 50),

              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'E-mail',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: largura < 600 ? 60 : 75,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: carregando
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final senha = senhaController.text.trim();

                          if (email.isEmpty || senha.isEmpty) {
                            AppSnackBar.show(
                              context,
                              'Preencha e-mail e senha para continuar.',
                            );
                            return;
                          }
                          if (!email.contains('@') || !email.contains('.')) {
                            AppSnackBar.show(
                              context,
                              'Digite um e-mail válido.',
                            );
                            return;
                          }
                          setState(() {
                            carregando = true;
                          });

                          try {
                            await _authService.login(
                              email: email,
                              password: senha,
                            );

                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String mensagem = 'E-mail ou senha inválidos.';

                            if (e.code == 'user-not-found') {
                              mensagem = 'Conta não encontrada.';
                            } else if (e.code == 'wrong-password') {
                              mensagem = 'Senha incorreta.';
                            } else if (e.code == 'invalid-email') {
                              mensagem = 'Digite um e-mail válido.';
                            } else if (e.code == 'invalid-credential') {
                              mensagem = 'E-mail ou senha inválidos.';
                            }

                            if (mounted) {
                              AppSnackBar.show(context, mensagem);

                              setState(() {
                                carregando = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackBar.show(
                                context,
                                'Erro ao tentar entrar.',
                              );

                              setState(() {
                                carregando = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    carregando ? 'Entrando...' : 'Entrar',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  AppSnackBar.show(
                    context,
                    'Recuperação de senha será adicionada em breve.',
                  );
                },
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 5),
              TextButton(
                onPressed: carregando
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        final senha = senhaController.text.trim();

                        if (email.isEmpty || senha.isEmpty) {
                          AppSnackBar.show(
                            context,
                            'Preencha e-mail e senha para criar sua conta.',
                          );
                          return;
                        }

                        if (!email.contains('@') || !email.contains('.')) {
                          AppSnackBar.show(context, 'Digite um e-mail válido.');
                          return;
                        }

                        if (senha.length < 6) {
                          AppSnackBar.show(
                            context,
                            'A senha precisa ter pelo menos 6 caracteres.',
                          );
                          return;
                        }

                        setState(() {
                          carregando = true;
                        });

                        try {
                          await _authService.register(
                            email: email,
                            password: senha,
                          );

                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            AppSnackBar.show(
                              context,
                              'Não foi possível criar a conta.',
                            );

                            setState(() {
                              carregando = false;
                            });
                          }
                        }
                      },
                child: const Text(
                  'Criar conta grátis',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
