import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Política de Privacidade',
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
                    title: 'Política de Privacidade — TORICO',
                    subtitle: 'Última atualização: $_updatedAt',
                  ),
                  SizedBox(height: 18),
                  _LegalParagraph(
                    'O TORICO respeita a sua privacidade e se compromete a proteger os dados pessoais dos usuários. Esta Política de Privacidade explica quais dados coletamos, como usamos essas informações e quais são os seus direitos.',
                  ),
                  _LegalSection(
                    title: '1. Quem somos',
                    body:
                        'O TORICO é um aplicativo/PWA criado para ajudar pequenos e médios comerciantes a acompanhar suas vendas em tempo real.\n\nContato oficial para dúvidas sobre privacidade, dados pessoais ou suporte: $_contactEmail',
                  ),
                  _LegalSection(
                    title: '2. Quais dados coletamos',
                    body:
                        'Podemos coletar e tratar os seguintes dados:\n\n• Dados de cadastro, como e-mail de login.\n• Identificador interno do usuário no Firebase Authentication.\n• Informações de conexão com plataformas de pagamento, como status da integração, plataforma conectada e data da conexão.\n• Dados de vendas recebidos por integração oficial, como valor da venda, data, horário, plataforma, status e identificadores técnicos do pagamento.\n• Dados técnicos de segurança e funcionamento, como logs de acesso, eventos de erro e informações necessárias para manter o serviço funcionando.',
                  ),
                  _LegalSection(
                    title: '3. Integração com Mercado Pago',
                    body:
                        'Quando o usuário conecta o Mercado Pago ao TORICO, a autorização é feita por meio do fluxo oficial OAuth do Mercado Pago.\n\nO TORICO não solicita nem armazena a senha do Mercado Pago do usuário.\n\nOs tokens de integração são armazenados somente no backend protegido, com criptografia, e não ficam disponíveis no aplicativo/PWA. O app acessa apenas informações públicas de status da integração, como “connected” e “Mercado Pago”.',
                  ),
                  _LegalSection(
                    title: '4. Para que usamos os dados',
                    body:
                        'Usamos os dados para:\n\n• Autenticar o usuário.\n• Exibir o painel de vendas em tempo real.\n• Calcular o total vendido no dia.\n• Exibir histórico e resumo por plataforma.\n• Manter a segurança da conta e das integrações.\n• Corrigir erros, prevenir abuso e melhorar o funcionamento do serviço.\n• Cumprir obrigações legais, quando aplicável.',
                  ),
                  _LegalSection(
                    title: '5. Compartilhamento de dados',
                    body:
                        'O TORICO utiliza serviços de terceiros necessários para seu funcionamento, incluindo Firebase Authentication, Cloud Firestore, Firebase Hosting, Google Cloud Run e Mercado Pago.\n\nNão vendemos dados pessoais dos usuários.',
                  ),
                  _LegalSection(
                    title: '6. Segurança',
                    body:
                        'Adotamos medidas técnicas para proteger os dados, incluindo autenticação por Firebase, regras de segurança no Firestore, backend protegido no Google Cloud Run, tokens OAuth criptografados, separação entre dados privados de integração e dados públicos de status, além de bloqueio de escrita direta de vendas pelo aplicativo.\n\nApesar dos esforços de segurança, nenhum sistema é totalmente imune a riscos.',
                  ),
                  _LegalSection(
                    title: '7. Retenção dos dados',
                    body:
                        'Os dados são mantidos enquanto forem necessários para fornecer o serviço, cumprir obrigações legais, resolver disputas, prevenir fraudes ou manter registros técnicos de funcionamento.\n\nO usuário pode solicitar informações sobre seus dados ou pedir exclusão quando aplicável, entrando em contato pelo e-mail oficial.',
                  ),
                  _LegalSection(
                    title: '8. Direitos do usuário',
                    body:
                        'O usuário pode entrar em contato para solicitar, quando aplicável: confirmação sobre o tratamento de dados, acesso aos dados, correção de dados incompletos ou desatualizados, informações sobre compartilhamento, exclusão de dados pessoais e revogação de consentimento.\n\nSolicitações devem ser enviadas para: $_contactEmail',
                  ),
                  _LegalSection(
                    title: '9. Menores de idade',
                    body:
                        'O TORICO é destinado ao uso por comerciantes e responsáveis por negócios. O serviço não é direcionado a menores de idade.',
                  ),
                  _LegalSection(
                    title: '10. Alterações nesta Política',
                    body:
                        'Esta Política de Privacidade poderá ser atualizada para refletir melhorias no serviço, mudanças legais ou alterações operacionais. A versão mais recente ficará disponível no app ou site do TORICO.',
                  ),
                  _LegalSection(
                    title: '11. Contato',
                    body: 'Para dúvidas, solicitações ou informações sobre privacidade: $_contactEmail',
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
