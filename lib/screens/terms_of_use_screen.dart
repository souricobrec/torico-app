import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const String _updatedAt = '13 de junho de 2026';
  static const String _contactEmail = 'sourico.br.ec@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        title: const Text(
          'Termos de Uso',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _LegalHeader(
                    title: 'Termos de Uso — TORICO',
                    subtitle: 'Última atualização: $_updatedAt',
                  ),
                  SizedBox(height: 18),
                  _LegalParagraph(
                    'Estes Termos de Uso regulam o acesso e uso do TORICO, aplicativo/PWA criado para ajudar comerciantes a acompanhar suas vendas em tempo real. Ao usar o TORICO, você declara que leu, entendeu e concorda com estes Termos.',
                  ),
                  _LegalSection(
                    title: '1. Sobre o TORICO',
                    body:
                        'O TORICO é uma ferramenta de acompanhamento de vendas para pequenos e médios comerciantes.\n\nO objetivo principal do serviço é permitir que o usuário visualize informações como total vendido no dia, histórico de vendas, resumo por plataforma e status da integração com plataformas de pagamento.',
                  ),
                  _LegalSection(
                    title: '2. Conta de usuário',
                    body:
                        'Para usar o TORICO, o usuário precisa criar ou acessar uma conta.\n\nO usuário é responsável por manter seu acesso seguro e por usar informações verdadeiras no cadastro.\n\nO TORICO poderá bloquear ou limitar acessos em caso de uso indevido, suspeita de fraude, tentativa de invasão, violação destes Termos ou risco à segurança do serviço.',
                  ),
                  _LegalSection(
                    title: '3. Integrações com plataformas de pagamento',
                    body:
                        'O TORICO pode permitir integração com plataformas de pagamento, como Mercado Pago.\n\nA conexão com o Mercado Pago é feita por autorização oficial OAuth. O TORICO não solicita nem armazena a senha do Mercado Pago do usuário.\n\nO usuário é responsável por conectar apenas contas de pagamento que tem autorização para administrar.',
                  ),
                  _LegalSection(
                    title: '4. Dados exibidos no painel',
                    body:
                        'Os valores exibidos no painel dependem das informações recebidas das plataformas integradas, webhooks, APIs oficiais e processamento técnico do backend.\n\nO TORICO busca apresentar os dados corretamente, mas pode haver atrasos, falhas temporárias, divergências causadas por indisponibilidade de terceiros ou mudanças nas APIs das plataformas.\n\nO usuário deve utilizar os dados como apoio à gestão, e não como único registro financeiro, contábil ou fiscal do negócio.',
                  ),
                  _LegalSection(
                    title: '5. Plano Básico',
                    body:
                        'O plano básico previsto do TORICO é de R\$ 24,90 por mês.\n\nEnquanto a cobrança oficial do plano não estiver habilitada, o acesso poderá ser disponibilizado em fase de teste, validação ou demonstração.\n\nAs condições comerciais poderão ser atualizadas futuramente, e qualquer alteração relevante será informada aos usuários.',
                  ),
                  _LegalSection(
                    title: '6. Uso permitido',
                    body:
                        'O usuário concorda em não tentar acessar dados de outros usuários, explorar falhas de segurança, realizar engenharia reversa do sistema, usar o serviço para fins ilegais, inserir dados falsos ou de terceiros sem autorização, tentar manipular vendas, integrações ou webhooks, ou compartilhar acessos de forma insegura.',
                  ),
                  _LegalSection(
                    title: '7. Disponibilidade do serviço',
                    body:
                        'O TORICO poderá passar por manutenções, atualizações ou indisponibilidades temporárias.\n\nNão garantimos funcionamento ininterrupto, livre de erros ou compatibilidade permanente com todos os dispositivos, navegadores ou serviços de terceiros.',
                  ),
                  _LegalSection(
                    title: '8. Limitação de responsabilidade',
                    body:
                        'O TORICO não substitui sistemas contábeis, fiscais, bancários ou financeiros oficiais.\n\nO usuário é responsável por conferir as informações diretamente nas plataformas de pagamento, bancos, sistemas fiscais e demais fontes oficiais quando necessário.\n\nO TORICO não se responsabiliza por perdas decorrentes de decisões tomadas exclusivamente com base nas informações exibidas no painel.',
                  ),
                  _LegalSection(
                    title: '9. Propriedade intelectual',
                    body:
                        'A marca, identidade visual, telas, textos, código, organização e experiência do TORICO pertencem aos seus responsáveis, salvo elementos de terceiros utilizados conforme suas respectivas licenças.\n\nO usuário não recebe direito de copiar, revender, distribuir ou explorar comercialmente o TORICO sem autorização.',
                  ),
                  _LegalSection(
                    title: '10. Privacidade',
                    body:
                        'O tratamento de dados pessoais é explicado na Política de Privacidade do TORICO.\n\nAo usar o serviço, o usuário também concorda com a Política de Privacidade.',
                  ),
                  _LegalSection(
                    title: '11. Cancelamento e exclusão',
                    body:
                        'O usuário poderá solicitar suporte, cancelamento, revisão de acesso ou informações sobre exclusão de dados pelo e-mail oficial: $_contactEmail',
                  ),
                  _LegalSection(
                    title: '12. Alterações dos Termos',
                    body:
                        'Estes Termos poderão ser atualizados para refletir mudanças no serviço, novas funcionalidades, alterações legais ou ajustes comerciais.\n\nA versão mais recente ficará disponível no app ou site do TORICO.',
                  ),
                  _LegalSection(
                    title: '13. Contato',
                    body:
                        'Para dúvidas, suporte ou solicitações relacionadas ao TORICO: $_contactEmail',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LegalHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 9),
          _LegalParagraph(body),
        ],
      ),
    );
  }
}

class _LegalParagraph extends StatelessWidget {
  final String text;

  const _LegalParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.72),
        fontSize: 14.5,
        height: 1.55,
      ),
    );
  }
}
