import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';
import assert from 'node:assert/strict';

// Exercise the real handler without starting Express, Firebase, or OAuth.
const source = readFileSync(new URL('../server.js', import.meta.url), 'utf8');
const handler = source.slice(
  source.indexOf('async function processMercadoPagoPaymentWebhook('),
  source.indexOf('async function processMercadoPagoMerchantOrderWebhook('),
);

for (const status of ['rejected', 'cancelled', 'pending', 'refunded', '']) {
  test(`${status || 'missing'} payment is logged and never saved`, async () => {
    const logs = [];
    let saves = 0;
    const context = vm.createContext({
      fetchMercadoPagoPayment: async () => ({ id: '123', status, transaction_amount: 1 }),
      getMercadoPagoUserIdFromPayment: () => 'merchant',
      getMercadoPagoPaymentAmount: (payment) => payment.transaction_amount,
      saveSale: async () => { saves++; throw new Error('must not save'); },
      console: { log: (...args) => logs.push(args) },
    });
    vm.runInContext(handler, context);
    const result = await context.processMercadoPagoPaymentWebhook({
      paymentId: '123', mercadoPagoContext: { mercadoPagoUserId: 'merchant', accessToken: 'test' },
    });
    assert.equal(result.processed, false);
    assert.equal(saves, 0);
    assert.equal(logs[0][0], 'Pagamento Mercado Pago ignorado por status diferente de approved');
    assert.equal(logs[0][1].paymentId, '123');
    assert.equal(logs[0][1].status, status);
    assert.equal(logs[0][1].amount, 1);
  });
}
