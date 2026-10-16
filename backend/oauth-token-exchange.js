import { securityFailure } from './mercado-pago-security.js';

// Deadline covers response headers AND JSON. Late results cannot persist tokens.
export async function exchangeOAuthToken(url, options, { fetchImpl = globalThis.fetch, timeoutMs = 15000 } = {}) {
  const controller = new AbortController();
  let timer;
  const deadline = new Promise((_, reject) => {
    timer = setTimeout(() => { controller.abort(); reject(securityFailure(504, 'oauth_provider_timeout')); }, timeoutMs);
  });
  try {
    return await Promise.race([(async () => {
      const response = await fetchImpl(url, { ...options, signal: controller.signal });
      const body = await response.json();
      if (controller.signal.aborted) throw securityFailure(504, 'oauth_provider_timeout');
      if (!response.ok || !body || typeof body.access_token !== 'string' || !body.access_token) {
        throw securityFailure(502, 'oauth_token_exchange_failed');
      }
      return body;
    })(), deadline]);
  } catch (error) {
    if (error.code === 'oauth_provider_timeout' || controller.signal.aborted) throw securityFailure(504, 'oauth_provider_timeout');
    throw securityFailure(502, 'oauth_token_exchange_failed');
  } finally { clearTimeout(timer); }
}
