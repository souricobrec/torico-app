import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Display-only identity. Deliberately contains no UID, tokens or credentials.
class ToricoAccountIdentity {
  final String? email;
  final String? name;
  final List<String> providerIds;
  const ToricoAccountIdentity({
    this.email,
    this.name,
    this.providerIds = const [],
  });
  factory ToricoAccountIdentity.fromUser(User user) => ToricoAccountIdentity(
    email: user.email,
    name: user.displayName,
    providerIds: user.providerData.map((p) => p.providerId).toList(),
  );
  String get loginMethods {
    final labels = <String>{
      if (providerIds.contains('google.com')) 'Google',
      if (providerIds.contains('password')) 'E-mail e senha',
    };
    return labels.isEmpty ? 'Conta autenticada' : labels.join(' · ');
  }
}

class ToricoAccountIdentityCard extends StatelessWidget {
  final ToricoAccountIdentity? identity;
  const ToricoAccountIdentityCard({super.key, required this.identity});
  @override
  Widget build(BuildContext context) {
    final name = identity?.name?.trim();
    final email = identity?.email?.trim();
    return Container(
      key: const ValueKey('torico-account-identity'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conta TORICO',
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (name != null && name.isNotEmpty)
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          Text(
            email == null || email.isEmpty ? 'E-mail não disponível' : email,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Métodos de login vinculados: ${identity?.loginMethods ?? "Não disponíveis"}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Suas integrações ficam vinculadas a esta conta TORICO.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
