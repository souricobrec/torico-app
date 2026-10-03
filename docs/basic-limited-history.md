# Histórico limitado no plano Básico

A navegação passa a conter Painel, Histórico, Plano e Conta em ambos os planos.
No Básico, o Histórico consulta apenas dez documentos da coleção de vendas do
mesmo UID, ordenados por createdAtClient decrescente, sem restringir ao dia atual.
A tela também limita a lista e exibe somente registros approved. Não há consulta
de totais por período, paginação, exportação ou filtros ativos no Básico.

O controle de filtros mostra “Recurso disponível no TORICO Plus.”. “Ver planos”
abre a aba Plano dentro da navegação ou a tela Plano no acesso direto.
Mudanças de plano substituem a tela limitada pela tela Plus existente e vice-versa.

O Plus mantém seus filtros atuais. Relatórios semanais/mensais, exportação e
outros relatórios completos continuam como evolução do Plus; esta mudança não
implementa recursos inexistentes. Preços permanecem iguais.

Este limite é de interface/consulta; não altera regras Firestore nem constitui
uma nova barreira de autorização no servidor. Não houve deploy ou alteração de
dados, áudio, backend, integrações ou infraestrutura.

Validação: flutter analyze, flutter test, flutter build web --release.
Esta decisão substitui a restrição de Histórico inteiro registrada em
basic-plan-ux-cleanup.md.
