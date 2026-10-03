# Login oficial: composição final

Topo: ícone TORICO local, nome e slogan em duas linhas. Card principal: título,
e-mail/senha, botão dourado “Entrar no TORICO →” e recuperação de senha. Fora do
card: separador OU, botão branco com ícone Google local e “Fazer Login com o
Google”. Depois, card “Ainda não tem conta? / Criar conta grátis” com seta.

`OfficialLoginLayout` contém apenas apresentação/callbacks. `PilotGate` mantém
autenticação e allowlists; cadastro/recuperação chamam os métodos existentes de
`AuthService`, sem mudar Firebase Auth no console. Cadastro exige e-mail/senha
e permanece sujeito à liberação da conta; não cria autorização ou migra dados.
O modo técnico mantém sua tela e limpeza anteriores. Fontes ativas não mudaram.

O layout usa SafeArea, largura máxima e rolagem vertical, inclusive com teclado.
Testes a 320, 390 e 768 px verificam ordem/posição, Google fora do card, slogan,
rolagem e callbacks. A suíte existente verifica o gate oficial/técnico e o UID.

Ícone Google: asset público oficial obtido de
https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png
(servido localmente pelo app, sem requisição externa durante o login).

Validação: `flutter analyze --no-pub`, `flutter test --no-pub`,
`flutter build web --release`. Sem deploy, alterações de backend, integrações,
Scheduler, Cloud Run, Secret Manager, DNS, Hosting ou configuração Firebase Auth.

Resultado local (02/10/2026): análise sem problemas, 19 testes aprovados e build
web release concluído. O build é apenas de validação, sem deploy; as allowlists
do ambiente publicado devem continuar sendo fornecidas na publicação autorizada.
