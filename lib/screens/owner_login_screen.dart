import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import 'login_screen.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool carregando = false;
  bool ocultarSenha = true;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  bool emailValido(String email) {
    return email.contains('@') && email.contains('.');
  }

  Future<void> entrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      AppSnackBar.show(context, 'Preencha e-mail e senha para continuar.');
      return;
    }

    if (!emailValido(email)) {
      AppSnackBar.show(context, 'Digite um e-mail válido.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await _authService.login(email: email, password: senha);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        AppSnackBar.show(context, 'Erro ao tentar entrar.');

        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> criarConta() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      AppSnackBar.show(
        context,
        'Preencha e-mail e senha para criar sua conta.',
      );
      return;
    }

    if (!emailValido(email)) {
      AppSnackBar.show(context, 'Digite um e-mail válido.');
      return;
    }

    if (senha.length < 6) {
      AppSnackBar.show(context, 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await _authService.register(email: email, password: senha);

      if (mounted) {
        AppSnackBar.show(
          context,
          'Conta criada! Enviamos um e-mail de verificação.',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível criar a conta.';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está cadastrado.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha precisa ser mais forte.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Digite um e-mail válido.';
      } else if (e.code == 'operation-not-allowed') {
        mensagem = 'Login por e-mail e senha não está ativado no Firebase.';
      }

      if (mounted) {
        AppSnackBar.show(context, mensagem);

        setState(() {
          carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Erro inesperado ao criar conta.');

        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> recuperarSenha() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      AppSnackBar.show(context, 'Digite seu e-mail para recuperar a senha.');
      return;
    }

    if (!emailValido(email)) {
      AppSnackBar.show(context, 'Digite um e-mail válido.');
      return;
    }

    try {
      await _authService.resetPassword(email: email);

      if (mounted) {
        AppSnackBar.show(
          context,
          'Enviamos um e-mail de recuperação de senha.',
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível enviar o e-mail.';

      if (e.code == 'user-not-found') {
        mensagem = 'Conta não encontrada.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Digite um e-mail válido.';
      }

      if (mounted) {
        AppSnackBar.show(context, mensagem);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Erro ao enviar recuperação de senha.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;
    final largura = tamanhoTela.width;
    final altura = tamanhoTela.height;

    final bool isMobile = largura < 600;
    final bool telaBaixa = altura < 760;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 22 : 40,
            isMobile ? 12 : 42,
            isMobile ? 22 : 40,
            20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _LoginHeader(isMobile: isMobile, telaBaixa: telaBaixa),

                  SizedBox(height: isMobile ? 18 : 42),

                  _LoginCard(
                    emailController: emailController,
                    senhaController: senhaController,
                    carregando: carregando,
                    ocultarSenha: ocultarSenha,
                    onToggleSenha: () {
                      setState(() {
                        ocultarSenha = !ocultarSenha;
                      });
                    },
                    onEntrar: entrar,
                    onRecuperarSenha: recuperarSenha,
                  ),

                  SizedBox(height: isMobile ? 12 : 18),

                  _CreateAccountCard(
                    carregando: carregando,
                    onCriarConta: criarConta,
                  ),

                  SizedBox(height: isMobile ? 16 : 30),

                  const _ValueMessage(),

                  if (!isMobile) ...[
                    const SizedBox(height: 28),
                    const _BenefitsRow(),
                  ],

                  SizedBox(height: isMobile ? 14 : 26),

                  const _SecurityMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  final bool isMobile;
  final bool telaBaixa;

  const _LoginHeader({required this.isMobile, required this.telaBaixa});

  @override
  Widget build(BuildContext context) {
    final double iconSize = isMobile ? (telaBaixa ? 78 : 88) : 140;
    final double titleSize = isMobile ? (telaBaixa ? 36 : 40) : 54;
    final double sloganSize = isMobile ? (telaBaixa ? 16 : 18) : 24;

    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.26),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/images/app_icon.png', fit: BoxFit.contain),
        ),

        SizedBox(height: isMobile ? 8 : 18),

        Text(
          'TORICO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldLight,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            height: 1,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 8 : 16),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Seu negócio vendendo.\n',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sloganSize,
                  height: 1.22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: 'Onde você estiver.',
                style: TextStyle(
                  color: AppColors.goldLight,
                  fontSize: sloganSize,
                  height: 1.22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController senhaController;
  final bool carregando;
  final bool ocultarSenha;
  final VoidCallback onToggleSenha;
  final VoidCallback onEntrar;
  final VoidCallback onRecuperarSenha;

  const _LoginCard({
    required this.emailController,
    required this.senhaController,
    required this.carregando,
    required this.ocultarSenha,
    required this.onToggleSenha,
    required this.onEntrar,
    required this.onRecuperarSenha,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 22,
        isMobile ? 18 : 26,
        isMobile ? 18 : 22,
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF06182C),
        borderRadius: BorderRadius.circular(isMobile ? 26 : 30),
        border: Border.all(color: AppColors.gold.withOpacity(0.58), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          BoxShadow(color: AppColors.gold.withOpacity(0.06), blurRadius: 40),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.goldLight,
                size: isMobile ? 34 : 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acesse sua conta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 23 : 27,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entre para acompanhar suas vendas em tempo real.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 14 : 16,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 18 : 30),

          const Text(
            'E-mail',
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          _PremiumTextField(
            controller: emailController,
            hintText: 'seu@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          SizedBox(height: isMobile ? 12 : 20),

          const Text(
            'Senha',
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          _PremiumTextField(
            controller: senhaController,
            hintText: 'Sua senha',
            icon: Icons.lock_outline_rounded,
            obscureText: ocultarSenha,
            suffixIcon: IconButton(
              onPressed: onToggleSenha,
              icon: Icon(
                ocultarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
              ),
            ),
          ),

          SizedBox(height: isMobile ? 18 : 28),

          SizedBox(
            width: double.infinity,
            height: isMobile ? 54 : 62,
            child: ElevatedButton(
              onPressed: carregando ? null : onEntrar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.gold.withOpacity(0.45),
                elevation: 10,
                shadowColor: AppColors.gold.withOpacity(0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: carregando
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Entrar no TORICO',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: isMobile ? 24 : 27,
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: isMobile ? 8 : 14),

          Center(
            child: TextButton.icon(
              onPressed: carregando ? null : onRecuperarSenha,
              icon: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white60,
                size: 20,
              ),
              label: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white, fontSize: isMobile ? 16 : 17),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.38),
          fontSize: isMobile ? 16 : 17,
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.16),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isMobile ? 16 : 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.20),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.goldLight, width: 1.4),
        ),
      ),
    );
  }
}

class _CreateAccountCard extends StatelessWidget {
  final bool carregando;
  final VoidCallback onCriarConta;

  const _CreateAccountCard({
    required this.carregando,
    required this.onCriarConta,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: carregando ? null : onCriarConta,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 14 : 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF06182C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.42),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 46 : 54,
                height: isMobile ? 46 : 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.goldLight,
                  size: isMobile ? 24 : 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ainda não tem conta?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Criar conta grátis',
                      style: TextStyle(
                        color: AppColors.goldLight,
                        fontSize: isMobile ? 18 : 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.goldLight,
                size: isMobile ? 30 : 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueMessage extends StatelessWidget {
  const _ValueMessage();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Text(
      'Simples, rápido e em tempo real.\nTudo que você precisa para vender mais.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: isMobile ? 15 : 18,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _BenefitItem(
            icon: Icons.trending_up_rounded,
            text: 'Acompanhe suas\nvendas em tempo real',
          ),
        ),
        _DividerLine(),
        Expanded(
          child: _BenefitItem(
            icon: Icons.notifications_active_rounded,
            text: 'Receba alertas de\ncada nova venda',
          ),
        ),
        _DividerLine(),
        Expanded(
          child: _BenefitItem(
            icon: Icons.monetization_on_rounded,
            text: 'Mais controle e\nmais resultados',
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.045),
            border: Border.all(color: AppColors.gold.withOpacity(0.18)),
          ),
          child: Icon(icon, color: AppColors.goldLight, size: 30),
        ),

        const SizedBox(height: 12),

        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.74),
            fontSize: 13,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 78,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.14),
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isMobile = largura < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: AppColors.goldLight,
            size: isMobile ? 26 : 32,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: isMobile ? 13 : 15,
                  height: 1.32,
                ),
                children: const [
                  TextSpan(
                    text: 'Seus dados protegidos com tecnologia Firebase. ',
                  ),
                  TextSpan(
                    text: 'Plataforma segura.',
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
