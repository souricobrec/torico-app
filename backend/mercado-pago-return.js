export function mercadoPagoReturnPage(status) {
  const connected = status === 'connected';
  const url = `https://app.meutorico.com.br/?integration=mercado_pago&status=${connected ? 'connected' : 'error'}`;
  const message = connected
    ? 'Mercado Pago conectado com sucesso.'
    : 'Não foi possível concluir a conexão Mercado Pago.';
  return `<!doctype html><html lang="pt-BR"><head>
    <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    ${connected ? `<meta http-equiv="refresh" content="2;url=${url.replaceAll('&', '&amp;')}">` : ''}
    <title>${message}</title>
    <style>body{margin:0;background:#031226;color:#fff;font-family:Arial,sans-serif;min-height:100vh;display:grid;place-items:center}main{max-width:36rem;padding:24px;text-align:center}a{display:inline-block;background:#ffd54f;color:#031226;padding:16px 24px;border-radius:12px;font-weight:bold}a:focus-visible{outline:3px solid white;outline-offset:4px}</style>
    </head><body><main><h1>${message}</h1>
    <p>${connected ? 'Você será direcionado ao TORICO em instantes. Se não acontecer, use o botão abaixo.' : 'Volte ao TORICO para verificar a conexão ou tentar novamente.'}</p>
    <a href="${url.replaceAll('&', '&amp;')}">Voltar ao TORICO</a>
    </main></body></html>`;
}
