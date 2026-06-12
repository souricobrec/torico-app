import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import admin from 'firebase-admin';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const PORT = process.env.PORT || 3333;

const ENABLE_TEST_ENDPOINTS =
  String(process.env.ENABLE_TEST_ENDPOINTS || '')
    .toLowerCase()
    .trim() === 'true';

const FIREBASE_SERVICE_ACCOUNT_PATH = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
const FIREBASE_PROJECT_ID =
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.GCLOUD_PROJECT;

const TORICO_DEV_KEY = process.env.TORICO_DEV_KEY;
const TOKEN_ENCRYPTION_KEY = process.env.TOKEN_ENCRYPTION_KEY;

const MERCADO_PAGO_CLIENT_ID = process.env.MERCADO_PAGO_CLIENT_ID;
const MERCADO_PAGO_CLIENT_SECRET = process.env.MERCADO_PAGO_CLIENT_SECRET;
const MERCADO_PAGO_REDIRECT_URI =
  process.env.MERCADO_PAGO_REDIRECT_URI ||
  'https://torico-backend-16783123127.us-central1.run.app/integrations/mercado-pago/callback';

const MERCADO_PAGO_WEBHOOK_SECRET = process.env.MERCADO_PAGO_WEBHOOK_SECRET;
const MERCADO_PAGO_ACCESS_TOKEN = process.env.MERCADO_PAGO_ACCESS_TOKEN;
const MERCADO_PAGO_DEFAULT_USER_ID = process.env.MERCADO_PAGO_DEFAULT_USER_ID;

const MERCADO_PAGO_OAUTH_AUTHORIZE_URL =
  'https://auth.mercadopago.com.br/authorization';

const MERCADO_PAGO_OAUTH_TOKEN_URL =
  'https://api.mercadopago.com/oauth/token';

const MERCADO_PAGO_PAYMENTS_API_URL =
  'https://api.mercadopago.com/v1/payments';

const MERCADO_PAGO_MERCHANT_ORDERS_API_URL =
  'https://api.mercadopago.com/merchant_orders';

const MERCADO_PAGO_PREFERENCES_API_URL =
  'https://api.mercadopago.com/checkout/preferences';

const PUBLIC_BACKEND_URL =
  process.env.PUBLIC_BACKEND_URL ||
  'https://torico-backend-16783123127.us-central1.run.app';

const PUBLIC_APP_URL =
  process.env.PUBLIC_APP_URL || 'https://torico-ca479.web.app';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return;
  }

  if (FIREBASE_SERVICE_ACCOUNT_PATH) {
    admin.initializeApp({
      credential: admin.credential.cert(FIREBASE_SERVICE_ACCOUNT_PATH),
      projectId: FIREBASE_PROJECT_ID || undefined,
    });

    console.log('Firebase Admin inicializado com service account local.');
    return;
  }

  admin.initializeApp({
    projectId: FIREBASE_PROJECT_ID || undefined,
  });

  console.log('Firebase Admin inicializado com credencial padrão do ambiente.');
}

initializeFirebaseAdmin();

const db = admin.firestore();

function normalizePlatformId(platform) {
  const normalized = String(platform || '').trim().toLowerCase();

  if (normalized.includes('mercado')) {
    return 'mercado_pago';
  }

  if (normalized.includes('stone')) {
    return 'stone';
  }

  if (normalized.includes('pagbank') || normalized.includes('pag bank')) {
    return 'pagbank';
  }

  if (!normalized) {
    return 'simulator';
  }

  return normalized
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}

function getBrazilDateKey(date = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Sao_Paulo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });

  return formatter.format(date);
}

function requireDevKey(req, res, next) {
  if (!TORICO_DEV_KEY) {
    console.warn(
      'TORICO_DEV_KEY não configurada. Bloqueando endpoint protegido.'
    );

    return res.status(503).json({
      ok: false,
      message:
        'Endpoint protegido indisponível. Configure TORICO_DEV_KEY no backend.',
    });
  }

  const receivedKey = req.get('x-torico-dev-key');

  if (!receivedKey || receivedKey !== TORICO_DEV_KEY) {
    return res.status(401).json({
      ok: false,
      message: 'Acesso não autorizado.',
    });
  }

  next();
}

function requireTestEndpointsEnabled(req, res, next) {
  if (ENABLE_TEST_ENDPOINTS) {
    return next();
  }

  console.warn(
    'Rota de teste bloqueada porque ENABLE_TEST_ENDPOINTS não está ativo.',
    {
      path: req.originalUrl,
      environment: process.env.NODE_ENV || 'development',
    }
  );

  return res.status(403).json({
    ok: false,
    message: 'Rota de teste desabilitada neste ambiente.',
  });
}

function validateSalePayload(payload) {
  const errors = [];

  if (!payload || typeof payload !== 'object') {
    errors.push('Body JSON inválido.');
    return errors;
  }

  if (!payload.userId || typeof payload.userId !== 'string') {
    errors.push('Campo userId é obrigatório.');
  }

  if (typeof payload.amount !== 'number' || Number.isNaN(payload.amount)) {
    errors.push('Campo amount deve ser um número.');
  }

  if (typeof payload.amount === 'number' && payload.amount <= 0) {
    errors.push('Campo amount deve ser maior que zero.');
  }

  if (!payload.platform || typeof payload.platform !== 'string') {
    errors.push('Campo platform é obrigatório.');
  }

  return errors;
}

function validateCreatePreferencePayload(payload) {
  const errors = [];

  if (!payload || typeof payload !== 'object') {
    return errors;
  }

  if (
    payload.amount !== undefined &&
    (typeof payload.amount !== 'number' ||
      Number.isNaN(payload.amount) ||
      payload.amount <= 0)
  ) {
    errors.push('Campo amount deve ser um número maior que zero.');
  }

  if (
    payload.quantity !== undefined &&
    (!Number.isInteger(payload.quantity) || payload.quantity <= 0)
  ) {
    errors.push('Campo quantity deve ser um número inteiro maior que zero.');
  }

  return errors;
}

function base64UrlEncode(value) {
  const stringValue =
    typeof value === 'string' ? value : JSON.stringify(value);

  return Buffer.from(stringValue).toString('base64url');
}

function base64UrlDecode(value) {
  return Buffer.from(value, 'base64url').toString('utf8');
}

function getOAuthStateSecret() {
  return MERCADO_PAGO_CLIENT_SECRET || TORICO_DEV_KEY;
}

function createOAuthState({ userId }) {
  const secret = getOAuthStateSecret();

  if (!secret) {
    throw new Error(
      'Não foi possível gerar state OAuth. Configure MERCADO_PAGO_CLIENT_SECRET ou TORICO_DEV_KEY.'
    );
  }

  const payload = {
    userId,
    nonce: crypto.randomUUID(),
    iat: Date.now(),
  };

  const encodedPayload = base64UrlEncode(payload);

  const signature = crypto
    .createHmac('sha256', secret)
    .update(encodedPayload)
    .digest('base64url');

  return `${encodedPayload}.${signature}`;
}

function verifyOAuthState(state) {
  const secret = getOAuthStateSecret();

  if (!secret) {
    throw new Error(
      'Não foi possível validar state OAuth. Configure MERCADO_PAGO_CLIENT_SECRET ou TORICO_DEV_KEY.'
    );
  }

  if (!state || typeof state !== 'string' || !state.includes('.')) {
    throw new Error('State OAuth ausente ou inválido.');
  }

  const [encodedPayload, receivedSignature] = state.split('.');

  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(encodedPayload)
    .digest('base64url');

  if (receivedSignature !== expectedSignature) {
    throw new Error('Assinatura do state OAuth inválida.');
  }

  const payload = JSON.parse(base64UrlDecode(encodedPayload));

  const maxAgeMs = 10 * 60 * 1000;
  const ageMs = Date.now() - Number(payload.iat || 0);

  if (ageMs < 0 || ageMs > maxAgeMs) {
    throw new Error('State OAuth expirado.');
  }

  if (!payload.userId || typeof payload.userId !== 'string') {
    throw new Error('State OAuth sem userId válido.');
  }

  return payload;
}

function getTokenEncryptionKeyBuffer() {
  if (!TOKEN_ENCRYPTION_KEY) {
    return null;
  }

  const key = Buffer.from(TOKEN_ENCRYPTION_KEY, 'hex');

  if (key.length !== 32) {
    throw new Error(
      'TOKEN_ENCRYPTION_KEY deve ser uma chave hexadecimal de 32 bytes, ou seja, 64 caracteres.'
    );
  }

  return key;
}

function encryptSecret(value) {
  if (!value) {
    return null;
  }

  const key = getTokenEncryptionKeyBuffer();

  if (!key) {
    throw new Error(
      'TOKEN_ENCRYPTION_KEY não configurada. O backend não deve salvar tokens sem criptografia.'
    );
  }

  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

  const encrypted = Buffer.concat([
    cipher.update(String(value), 'utf8'),
    cipher.final(),
  ]);

  const authTag = cipher.getAuthTag();

  return {
    algorithm: 'aes-256-gcm',
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex'),
    value: encrypted.toString('hex'),
  };
}

function isMercadoPagoOAuthConfigured() {
  return Boolean(
    MERCADO_PAGO_CLIENT_ID &&
      MERCADO_PAGO_CLIENT_SECRET &&
      MERCADO_PAGO_REDIRECT_URI
  );
}

function isMercadoPagoMvpConfigured() {
  return Boolean(MERCADO_PAGO_ACCESS_TOKEN && MERCADO_PAGO_DEFAULT_USER_ID);
}

function getMissingMercadoPagoOAuthConfig() {
  const missing = [];

  if (!MERCADO_PAGO_CLIENT_ID) {
    missing.push('MERCADO_PAGO_CLIENT_ID');
  }

  if (!MERCADO_PAGO_CLIENT_SECRET) {
    missing.push('MERCADO_PAGO_CLIENT_SECRET');
  }

  if (!MERCADO_PAGO_REDIRECT_URI) {
    missing.push('MERCADO_PAGO_REDIRECT_URI');
  }

  if (!TOKEN_ENCRYPTION_KEY) {
    missing.push('TOKEN_ENCRYPTION_KEY');
  }

  return missing;
}

function parseMercadoPagoSignatureHeader(signatureHeader) {
  const result = {};

  if (!signatureHeader || typeof signatureHeader !== 'string') {
    return result;
  }

  const parts = signatureHeader.split(',');

  for (const part of parts) {
    const [key, value] = part.split('=');

    if (key && value) {
      result[key.trim()] = value.trim();
    }
  }

  return result;
}

function getMercadoPagoDataId(req) {
  const queryDataId =
    req.query?.['data.id'] ||
    req.query?.data_id ||
    req.query?.id;

  const bodyDataId =
    req.body?.data?.id ||
    req.body?.id;

  const dataId = queryDataId || bodyDataId;

  if (!dataId) {
    return '';
  }

  return String(dataId).toLowerCase();
}

function safeTimingEqual(a, b) {
  const bufferA = Buffer.from(String(a));
  const bufferB = Buffer.from(String(b));

  if (bufferA.length !== bufferB.length) {
    return false;
  }

  return crypto.timingSafeEqual(bufferA, bufferB);
}

function validateMercadoPagoWebhookSignature(req) {
  if (!MERCADO_PAGO_WEBHOOK_SECRET) {
    return {
      ok: true,
      skipped: true,
      reason: 'MERCADO_PAGO_WEBHOOK_SECRET não configurado.',
    };
  }

  const xSignature = req.get('x-signature');
  const xRequestId = req.get('x-request-id');

  if (!xSignature || !xRequestId) {
    return {
      ok: false,
      skipped: false,
      reason: 'Headers x-signature ou x-request-id ausentes.',
    };
  }

  const { ts, v1 } = parseMercadoPagoSignatureHeader(xSignature);

  if (!ts || !v1) {
    return {
      ok: false,
      skipped: false,
      reason: 'Header x-signature sem ts ou v1.',
    };
  }

  const dataId = getMercadoPagoDataId(req);

  const templateParts = [];

  if (dataId) {
    templateParts.push(`id:${dataId};`);
  }

  templateParts.push(`request-id:${xRequestId};`);
  templateParts.push(`ts:${ts};`);

  const signatureTemplate = templateParts.join('');

  const expectedSignature = crypto
    .createHmac('sha256', MERCADO_PAGO_WEBHOOK_SECRET)
    .update(signatureTemplate)
    .digest('hex');

  return {
    ok: safeTimingEqual(expectedSignature, v1),
    skipped: false,
    reason: 'Assinatura calculada e comparada.',
  };
}

function getMercadoPagoPaymentIdFromWebhook(req) {
  const fromQuery =
    req.query?.['data.id'] ||
    req.query?.data_id ||
    req.query?.id;

  const fromBody =
    req.body?.data?.id ||
    req.body?.resource ||
    req.body?.id;

  const value = fromQuery || fromBody;

  if (!value) {
    return '';
  }

  return String(value);
}

function getMercadoPagoEventTopic(req) {
  const values = [
    req.body?.type,
    req.body?.topic,
    req.query?.topic,
    req.query?.type,
  ]
    .map((value) => String(value || '').toLowerCase().trim())
    .filter(Boolean);

  if (values.includes('payment')) {
    return 'payment';
  }

  if (
    values.includes('merchant_order') ||
    values.includes('topic_merchant_order_wh') ||
    values.some((value) => value.includes('merchant_order'))
  ) {
    return 'merchant_order';
  }

  return values[0] || '';
}

function getMercadoPagoEventAction(req) {
  return String(req.body?.action || req.query?.action || '').toLowerCase();
}

function isMercadoPagoPaymentEvent(req) {
  const topic = getMercadoPagoEventTopic(req);
  const action = getMercadoPagoEventAction(req);

  if (topic === 'payment') {
    return true;
  }

  if (action.startsWith('payment.')) {
    return true;
  }

  return false;
}

function isMercadoPagoMerchantOrderEvent(req) {
  const topic = getMercadoPagoEventTopic(req);
  const action = getMercadoPagoEventAction(req);

  if (topic === 'merchant_order') {
    return true;
  }

  if (action.startsWith('merchant_order.')) {
    return true;
  }

  return false;
}

function isMercadoPagoLegacyMerchantOrderNotification(req) {
  const queryId = String(req.query?.id || '').trim();
  const queryDataId = String(
    req.query?.['data.id'] || req.query?.data_id || ''
  ).trim();

  const queryTopic = String(req.query?.topic || '').toLowerCase().trim();
  const queryType = String(req.query?.type || '').toLowerCase().trim();

  const hasMerchantOrderId = Boolean(queryId || queryDataId);

  const isMerchantOrder =
    queryTopic === 'merchant_order' ||
    queryType === 'merchant_order' ||
    queryType === 'topic_merchant_order_wh' ||
    queryTopic.includes('merchant_order') ||
    queryType.includes('merchant_order');

  return hasMerchantOrderId && isMerchantOrder;
}

function isMercadoPagoLegacyPaymentNotification(req) {
  const queryId = String(req.query?.id || '').trim();
  const queryDataId = String(
    req.query?.['data.id'] || req.query?.data_id || ''
  ).trim();

  const queryTopic = String(req.query?.topic || '').toLowerCase().trim();
  const queryType = String(req.query?.type || '').toLowerCase().trim();

  const hasPaymentId = Boolean(queryId || queryDataId);

  const isPayment =
    queryTopic === 'payment' ||
    queryType === 'payment' ||
    queryTopic.includes('payment') ||
    queryType.includes('payment');

  return hasPaymentId && isPayment;
}

function getMercadoPagoMerchantOrderIdFromWebhook(req) {
  const fromQuery =
    req.query?.['data.id'] ||
    req.query?.data_id ||
    req.query?.id;

  const fromBody =
    req.body?.data?.id ||
    req.body?.resource ||
    req.body?.id;

  const value = fromQuery || fromBody;

  if (!value) {
    return '';
  }

  return String(value);
}

async function fetchMercadoPagoPayment(paymentId) {
  if (!MERCADO_PAGO_ACCESS_TOKEN) {
    const error = new Error(
      'MERCADO_PAGO_ACCESS_TOKEN não configurado no backend.'
    );
    error.status = 503;
    throw error;
  }

  const response = await fetch(
    `${MERCADO_PAGO_PAYMENTS_API_URL}/${encodeURIComponent(paymentId)}`,
    {
      method: 'GET',
      headers: {
        accept: 'application/json',
        authorization: `Bearer ${MERCADO_PAGO_ACCESS_TOKEN}`,
      },
    }
  );

  const responseBody = await response.json().catch(() => null);

  if (!response.ok) {
    const error = new Error('Erro ao consultar pagamento no Mercado Pago.');
    error.status = response.status;
    error.responseBody = responseBody;
    throw error;
  }

  return responseBody;
}

async function fetchMercadoPagoMerchantOrder(merchantOrderId) {
  if (!MERCADO_PAGO_ACCESS_TOKEN) {
    const error = new Error(
      'MERCADO_PAGO_ACCESS_TOKEN não configurado no backend.'
    );
    error.status = 503;
    throw error;
  }

  const response = await fetch(
    `${MERCADO_PAGO_MERCHANT_ORDERS_API_URL}/${encodeURIComponent(
      merchantOrderId
    )}`,
    {
      method: 'GET',
      headers: {
        accept: 'application/json',
        authorization: `Bearer ${MERCADO_PAGO_ACCESS_TOKEN}`,
      },
    }
  );

  const responseBody = await response.json().catch(() => null);

  if (!response.ok) {
    const error = new Error(
      'Erro ao consultar pedido comercial no Mercado Pago.'
    );
    error.status = response.status;
    error.responseBody = responseBody;
    throw error;
  }

  return responseBody;
}

function getMercadoPagoPaymentIdsFromMerchantOrder(merchantOrder) {
  const payments = Array.isArray(merchantOrder?.payments)
    ? merchantOrder.payments
    : [];

  return payments
    .map((payment) => payment?.id)
    .filter((paymentId) => paymentId !== undefined && paymentId !== null)
    .map((paymentId) => String(paymentId));
}

async function createMercadoPagoPreference({
  title,
  amount,
  quantity,
  externalReference,
}) {
  if (!MERCADO_PAGO_ACCESS_TOKEN) {
    const error = new Error(
      'MERCADO_PAGO_ACCESS_TOKEN não configurado no backend.'
    );
    error.status = 503;
    throw error;
  }

  const preferencePayload = {
    items: [
      {
        title,
        quantity,
        currency_id: 'BRL',
        unit_price: amount,
      },
    ],
    external_reference: externalReference,
    notification_url: `${PUBLIC_BACKEND_URL}/webhooks/mercado-pago`,
    back_urls: {
      success: PUBLIC_APP_URL,
      pending: PUBLIC_APP_URL,
      failure: PUBLIC_APP_URL,
    },
    auto_return: 'approved',
    metadata: {
      app: 'TORICO',
      source: 'torico_test_preference',
    },
  };

  const response = await fetch(MERCADO_PAGO_PREFERENCES_API_URL, {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      authorization: `Bearer ${MERCADO_PAGO_ACCESS_TOKEN}`,
    },
    body: JSON.stringify(preferencePayload),
  });

  const responseBody = await response.json().catch(() => null);

  if (!response.ok) {
    const error = new Error('Erro ao criar preferência no Mercado Pago.');
    error.status = response.status;
    error.responseBody = responseBody;
    throw error;
  }

  return responseBody;
}

function getMercadoPagoPaymentAmount(payment) {
  const amount =
    payment?.transaction_amount ||
    payment?.transaction_details?.total_paid_amount ||
    payment?.transaction_details?.net_received_amount;

  const parsed = Number(amount);

  if (Number.isNaN(parsed)) {
    return 0;
  }

  return parsed;
}

function getMercadoPagoPaymentDate(payment) {
  const dateValue =
    payment?.date_approved ||
    payment?.money_release_date ||
    payment?.date_created;

  if (!dateValue) {
    return new Date();
  }

  const parsedDate = new Date(dateValue);

  if (Number.isNaN(parsedDate.getTime())) {
    return new Date();
  }

  return parsedDate;
}

async function saveSale({
  userId,
  amount,
  platform,
  status = 'approved',
  source = 'webhook_simulator',
  externalId,
  rawPayload = {},
  createdAt = new Date(),
}) {
  const platformId = normalizePlatformId(platform);
  const saleDate = createdAt instanceof Date ? createdAt : new Date(createdAt);
  const dateKey = getBrazilDateKey(saleDate);

  const safeExternalId =
    externalId ||
    `${source}_${platformId}_${Date.now()}_${Math.floor(
      Math.random() * 100000
    )}`;

  const saleRef = db
    .collection('users')
    .doc(userId)
    .collection('sales')
    .doc(safeExternalId);

  const existingSale = await saleRef.get();

  if (existingSale.exists) {
    return {
      id: saleRef.id,
      duplicated: true,
      ...existingSale.data(),
    };
  }

  const saleData = {
    amount,
    platform,
    platformId,
    status,
    source,
    externalId: safeExternalId,
    rawPayload,
    dateKey,
    createdAtClient: admin.firestore.Timestamp.fromDate(saleDate),
    createdAtServer: admin.firestore.FieldValue.serverTimestamp(),
  };

  await saleRef.set(saleData, { merge: false });

  return {
    id: saleRef.id,
    duplicated: false,
    ...saleData,
  };
}

async function processMercadoPagoPaymentWebhook({
  paymentId,
  originalWebhookPayload,
  originalMerchantOrder = null,
}) {
  const payment = await fetchMercadoPagoPayment(paymentId);

  const status = String(payment?.status || '').toLowerCase();
  const amount = getMercadoPagoPaymentAmount(payment);

  if (status !== 'approved') {
    return {
      processed: false,
      reason: `Pagamento ignorado porque status atual é "${
        status || 'desconhecido'
      }".`,
      paymentId,
      status,
    };
  }

  if (amount <= 0) {
    return {
      processed: false,
      reason: 'Pagamento aprovado ignorado porque valor não foi identificado.',
      paymentId,
      status,
    };
  }

  const externalId = `mercado_pago_payment_${payment.id}`;
  const createdAt = getMercadoPagoPaymentDate(payment);

  const sale = await saveSale({
    userId: MERCADO_PAGO_DEFAULT_USER_ID,
    amount,
    platform: 'Mercado Pago',
    status,
    source: 'webhook',
    externalId,
    createdAt,
    rawPayload: {
      receivedFrom: 'Mercado Pago webhook',
      webhook: originalWebhookPayload,
      merchantOrder: originalMerchantOrder
        ? {
            id: originalMerchantOrder.id,
            status: originalMerchantOrder.status,
            preference_id: originalMerchantOrder.preference_id,
            external_reference: originalMerchantOrder.external_reference,
            payments: originalMerchantOrder.payments || [],
          }
        : null,
      payment: {
        id: payment.id,
        status: payment.status,
        status_detail: payment.status_detail,
        transaction_amount: payment.transaction_amount,
        currency_id: payment.currency_id,
        payment_method_id: payment.payment_method_id,
        payment_type_id: payment.payment_type_id,
        date_created: payment.date_created,
        date_approved: payment.date_approved,
        live_mode: payment.live_mode,
        collector_id: payment.collector_id,
        payer_id: payment.payer?.id || null,
      },
    },
  });

  return {
    processed: true,
    paymentId,
    status,
    amount,
    duplicated: sale.duplicated,
    sale: {
      id: sale.id,
      amount: sale.amount,
      platform: sale.platform,
      platformId: sale.platformId,
      status: sale.status,
      source: sale.source,
      externalId: sale.externalId,
      dateKey: sale.dateKey,
      duplicated: sale.duplicated,
    },
  };
}

async function processMercadoPagoMerchantOrderWebhook({
  merchantOrderId,
  originalWebhookPayload,
}) {
  const merchantOrder = await fetchMercadoPagoMerchantOrder(merchantOrderId);
  const paymentIds = getMercadoPagoPaymentIdsFromMerchantOrder(merchantOrder);

  if (paymentIds.length === 0) {
    return {
      processed: false,
      reason: 'Pedido comercial recebido, mas sem pagamentos vinculados ainda.',
      merchantOrderId,
      results: [],
    };
  }

  const results = [];

  for (const paymentId of paymentIds) {
    const result = await processMercadoPagoPaymentWebhook({
      paymentId,
      originalWebhookPayload,
      originalMerchantOrder: merchantOrder,
    });

    results.push(result);
  }

  const processedResults = results.filter((result) => result.processed);

  if (processedResults.length === 0) {
    return {
      processed: false,
      reason:
        'Pedido comercial consultado, mas nenhum pagamento aprovado foi processado.',
      merchantOrderId,
      results,
    };
  }

  return {
    processed: true,
    merchantOrderId,
    results,
    sales: processedResults.map((result) => result.sale),
  };
}

async function saveMercadoPagoIntegration({ userId, tokenResponse }) {
  const expiresInSeconds = Number(tokenResponse.expires_in || 0);
  const now = new Date();

  const expiresAt =
    expiresInSeconds > 0
      ? new Date(now.getTime() + expiresInSeconds * 1000)
      : null;

  const integrationRef = db
    .collection('users')
    .doc(userId)
    .collection('integrations')
    .doc('mercado_pago');

  const integrationData = {
    platform: 'Mercado Pago',
    platformId: 'mercado_pago',
    status: 'connected',
    tokenType: tokenResponse.token_type || null,
    scope: tokenResponse.scope || null,
    mercadoPagoUserId: tokenResponse.user_id
      ? String(tokenResponse.user_id)
      : null,
    publicKey: tokenResponse.public_key || null,
    liveMode: Boolean(tokenResponse.live_mode),
    accessTokenEncrypted: encryptSecret(tokenResponse.access_token),
    refreshTokenEncrypted: encryptSecret(tokenResponse.refresh_token),
    expiresAt: expiresAt
      ? admin.firestore.Timestamp.fromDate(expiresAt)
      : null,
    connectedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await integrationRef.set(integrationData, { merge: true });

  return {
    userId,
    platformId: integrationData.platformId,
    status: integrationData.status,
    mercadoPagoUserId: integrationData.mercadoPagoUserId,
    liveMode: integrationData.liveMode,
    expiresAt,
  };
}

app.get('/', (req, res) => {
  if (ENABLE_TEST_ENDPOINTS) {
    return res.redirect('/test-client');
  }

  return res.status(200).json({
    ok: true,
    app: 'TORICO Backend',
    message: 'TORICO Backend ativo.',
    health: '/health',
  });
});

app.get('/test-client', requireTestEndpointsEnabled, (req, res) => {
  res.sendFile(path.join(__dirname, 'test-client.html'));
});

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    app: 'TORICO Backend',
    mode: 'simulado',
    environment: process.env.NODE_ENV || 'development',
    projectId: FIREBASE_PROJECT_ID || 'default',
    protectedSimulation: Boolean(TORICO_DEV_KEY),
    testEndpointsEnabled: ENABLE_TEST_ENDPOINTS,
    publicBackendUrl: PUBLIC_BACKEND_URL,
    publicAppUrl: PUBLIC_APP_URL,
    mercadoPago: {
      oauthConfigured: isMercadoPagoOAuthConfigured(),
      webhookSignatureConfigured: Boolean(MERCADO_PAGO_WEBHOOK_SECRET),
      tokenEncryptionConfigured: Boolean(TOKEN_ENCRYPTION_KEY),
      accessTokenConfigured: Boolean(MERCADO_PAGO_ACCESS_TOKEN),
      defaultUserIdConfigured: Boolean(MERCADO_PAGO_DEFAULT_USER_ID),
      mvpConfigured: isMercadoPagoMvpConfigured(),
      redirectUri: MERCADO_PAGO_REDIRECT_URI,
    },
    timestamp: new Date().toISOString(),
  });
});

app.get('/integrations/mercado-pago/connect', (req, res) => {
  try {
    const userId = String(req.query.userId || '').trim();

    if (!userId) {
      return res.status(400).json({
        ok: false,
        message:
          'Informe o userId do usuário TORICO para iniciar a conexão Mercado Pago.',
      });
    }

    const missingConfig = getMissingMercadoPagoOAuthConfig();

    if (missingConfig.length > 0) {
      return res.status(503).json({
        ok: false,
        message:
          'Integração Mercado Pago ainda não configurada completamente no backend.',
        missingConfig,
      });
    }

    const state = createOAuthState({ userId });

    const authorizationUrl = new URL(MERCADO_PAGO_OAUTH_AUTHORIZE_URL);

    authorizationUrl.searchParams.set('client_id', MERCADO_PAGO_CLIENT_ID);
    authorizationUrl.searchParams.set('response_type', 'code');
    authorizationUrl.searchParams.set('platform_id', 'mp');
    authorizationUrl.searchParams.set(
      'redirect_uri',
      MERCADO_PAGO_REDIRECT_URI
    );
    authorizationUrl.searchParams.set('state', state);

    return res.redirect(authorizationUrl.toString());
  } catch (error) {
    console.error('Erro ao iniciar OAuth Mercado Pago:', error.message);

    return res.status(500).json({
      ok: false,
      message: 'Erro interno ao iniciar conexão Mercado Pago.',
    });
  }
});

app.get('/integrations/mercado-pago/callback', async (req, res) => {
  try {
    const { code, state, error, error_description: errorDescription } =
      req.query;

    if (error) {
      console.warn('OAuth Mercado Pago recusado:', {
        error,
        errorDescription,
      });

      return res.status(400).send(`
        <html>
          <body style="font-family: Arial; background: #031226; color: white; padding: 24px;">
            <h2>Conexão Mercado Pago não concluída</h2>
            <p>O Mercado Pago retornou uma recusa ou erro de autorização.</p>
            <p>Você pode fechar esta janela e tentar novamente pelo TORICO.</p>
          </body>
        </html>
      `);
    }

    if (!code || !state) {
      return res.status(400).send(`
        <html>
          <body style="font-family: Arial; background: #031226; color: white; padding: 24px;">
            <h2>Callback inválido</h2>
            <p>Parâmetros obrigatórios ausentes.</p>
          </body>
        </html>
      `);
    }

    const missingConfig = getMissingMercadoPagoOAuthConfig();

    if (missingConfig.length > 0) {
      console.warn('Configuração OAuth Mercado Pago incompleta:', missingConfig);

      return res.status(503).send(`
        <html>
          <body style="font-family: Arial; background: #031226; color: white; padding: 24px;">
            <h2>Integração não configurada</h2>
            <p>O backend ainda não está com todas as variáveis do Mercado Pago configuradas.</p>
          </body>
        </html>
      `);
    }

    const statePayload = verifyOAuthState(String(state));

    const tokenParams = new URLSearchParams();
    tokenParams.set('grant_type', 'authorization_code');
    tokenParams.set('client_id', MERCADO_PAGO_CLIENT_ID);
    tokenParams.set('client_secret', MERCADO_PAGO_CLIENT_SECRET);
    tokenParams.set('code', String(code));
    tokenParams.set('redirect_uri', MERCADO_PAGO_REDIRECT_URI);

    const tokenResponse = await fetch(MERCADO_PAGO_OAUTH_TOKEN_URL, {
      method: 'POST',
      headers: {
        accept: 'application/json',
        'content-type': 'application/x-www-form-urlencoded',
      },
      body: tokenParams,
    });

    const tokenResponseBody = await tokenResponse.json().catch(() => null);

    if (!tokenResponse.ok) {
      console.error('Erro ao trocar code por token Mercado Pago:', {
        status: tokenResponse.status,
        body: tokenResponseBody,
      });

      return res.status(502).send(`
        <html>
          <body style="font-family: Arial; background: #031226; color: white; padding: 24px;">
            <h2>Falha ao conectar Mercado Pago</h2>
            <p>Não foi possível concluir a troca do código de autorização.</p>
          </body>
        </html>
      `);
    }

    const integration = await saveMercadoPagoIntegration({
      userId: statePayload.userId,
      tokenResponse: tokenResponseBody,
    });

    console.log('Integração Mercado Pago conectada:', {
      userId: integration.userId,
      mercadoPagoUserId: integration.mercadoPagoUserId,
      liveMode: integration.liveMode,
      status: integration.status,
    });

    return res.status(200).send(`
      <html>
        <body style="font-family: Arial; background: #031226; color: white; padding: 24px;">
          <h2>Mercado Pago conectado com sucesso</h2>
          <p>A integração foi autorizada e registrada no backend do TORICO.</p>
          <p>Você já pode fechar esta janela e voltar para o app.</p>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('Erro no callback Mercado Pago:', error.message);

    return res.status(500).send(`
      <html>
        <body style="font-family: Arial; background: #031226; color: white; padding: 24px;">
          <h2>Erro interno</h2>
          <p>Não foi possível concluir a conexão Mercado Pago neste momento.</p>
        </body>
      </html>
    `);
  }
});

app.post(
  '/simulate-sale',
  requireTestEndpointsEnabled,
  requireDevKey,
  async (req, res) => {
  try {
    const errors = validateSalePayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        ok: false,
        errors,
      });
    }

    const {
      userId,
      amount,
      platform,
      status = 'approved',
      externalId,
    } = req.body;

    const sale = await saveSale({
      userId,
      amount,
      platform,
      status,
      source: 'webhook_simulator',
      externalId,
      rawPayload: {
        receivedFrom: 'TORICO backend simulator',
        originalBody: req.body,
      },
    });

    return res.status(201).json({
      ok: true,
      message: 'Venda simulada gravada no Firestore.',
      sale: {
        id: sale.id,
        amount: sale.amount,
        platform: sale.platform,
        platformId: sale.platformId,
        status: sale.status,
        source: sale.source,
        externalId: sale.externalId,
        dateKey: sale.dateKey,
        duplicated: sale.duplicated,
      },
    });
  } catch (error) {
    console.error('Erro ao simular venda:', error);

    return res.status(500).json({
      ok: false,
      message: 'Erro interno ao simular venda.',
    });
  }
});

app.post(
  '/mercado-pago/create-test-preference',
  requireTestEndpointsEnabled,
  requireDevKey,
  async (req, res) => {
  try {
    if (!isMercadoPagoMvpConfigured()) {
      return res.status(503).json({
        ok: false,
        message:
          'MVP Mercado Pago não configurado. Configure MERCADO_PAGO_ACCESS_TOKEN e MERCADO_PAGO_DEFAULT_USER_ID no backend.',
      });
    }

    const errors = validateCreatePreferencePayload(req.body);

    if (errors.length > 0) {
      return res.status(400).json({
        ok: false,
        errors,
      });
    }

    const title =
      typeof req.body?.title === 'string' && req.body.title.trim()
        ? req.body.title.trim()
        : 'Venda de teste TORICO';

    const amount =
      typeof req.body?.amount === 'number' && req.body.amount > 0
        ? req.body.amount
        : 10.0;

    const quantity =
      Number.isInteger(req.body?.quantity) && req.body.quantity > 0
        ? req.body.quantity
        : 1;

    const externalReference =
      typeof req.body?.externalReference === 'string' &&
      req.body.externalReference.trim()
        ? req.body.externalReference.trim()
        : `torico_test_${Date.now()}_${crypto.randomUUID()}`;

    const preference = await createMercadoPagoPreference({
      title,
      amount,
      quantity,
      externalReference,
    });

    return res.status(201).json({
      ok: true,
      message: 'Preferência de pagamento criada no Mercado Pago.',
      preference: {
        id: preference.id,
        externalReference,
        title,
        amount,
        quantity,
        initPoint: preference.init_point,
        sandboxInitPoint: preference.sandbox_init_point,
        notificationUrl: `${PUBLIC_BACKEND_URL}/webhooks/mercado-pago`,
      },
    });
  } catch (error) {
    console.error('Erro ao criar preferência Mercado Pago:', {
      message: error.message,
      status: error.status,
      responseBody: error.responseBody,
    });

    return res.status(500).json({
      ok: false,
      message: 'Erro interno ao criar preferência Mercado Pago.',
      details: error.responseBody || undefined,
    });
  }
});

app.post('/webhooks/mercado-pago', async (req, res) => {
  try {
    const signatureValidation = validateMercadoPagoWebhookSignature(req);

    const isLegacyMerchantOrderNotification =
      isMercadoPagoLegacyMerchantOrderNotification(req);

    const isLegacyPaymentNotification =
      isMercadoPagoLegacyPaymentNotification(req);

    const shouldAcceptWithApiVerification =
      isLegacyMerchantOrderNotification || isLegacyPaymentNotification;

    if (!signatureValidation.ok && !shouldAcceptWithApiVerification) {
      console.warn('Webhook Mercado Pago com assinatura inválida:', {
        reason: signatureValidation.reason,
        query: req.query,
      });

      return res.status(401).json({
        ok: false,
        message: 'Assinatura do webhook inválida.',
      });
    }

    if (!signatureValidation.ok && isLegacyMerchantOrderNotification) {
      console.warn(
        'Webhook Mercado Pago merchant_order em formato legado/data.id recebido sem assinatura moderna válida. O backend seguirá consultando a API oficial antes de processar.',
        {
          reason: signatureValidation.reason,
          query: req.query,
        }
      );
    }

    if (!signatureValidation.ok && isLegacyPaymentNotification) {
      console.warn(
        'Webhook Mercado Pago payment em formato legado/data.id recebido sem assinatura moderna valida. O backend seguira consultando a API oficial antes de processar.',
        {
          reason: signatureValidation.reason,
          query: req.query,
        }
      );
    }

    const eventId = getMercadoPagoDataId(req);
    const paymentId = getMercadoPagoPaymentIdFromWebhook(req);
    const merchantOrderId = getMercadoPagoMerchantOrderIdFromWebhook(req);
    const eventType = getMercadoPagoEventTopic(req) || null;
    const eventAction = getMercadoPagoEventAction(req) || null;

    console.log('Webhook Mercado Pago recebido:', {
      eventId,
      paymentId,
      merchantOrderId,
      eventType,
      eventAction,
      query: req.query,
      signatureSkipped:
        signatureValidation.skipped ||
        (!signatureValidation.ok && shouldAcceptWithApiVerification),
      legacyMerchantOrderNotification: isLegacyMerchantOrderNotification,
      legacyPaymentNotification: isLegacyPaymentNotification,
    });

    if (!isMercadoPagoMvpConfigured()) {
      return res.status(503).json({
        ok: false,
        message:
          'MVP Mercado Pago não configurado. Configure MERCADO_PAGO_ACCESS_TOKEN e MERCADO_PAGO_DEFAULT_USER_ID no backend.',
      });
    }

    if (isMercadoPagoMerchantOrderEvent(req)) {
      if (!merchantOrderId) {
        return res.status(400).json({
          ok: false,
          message: 'Webhook de pedido comercial sem ID de merchant_order.',
        });
      }

      const result = await processMercadoPagoMerchantOrderWebhook({
        merchantOrderId,
        originalWebhookPayload: {
          query: req.query,
          body: req.body,
        },
      });

      if (!result.processed) {
        return res.status(200).json({
          ok: true,
          message: result.reason,
          processed: false,
          merchantOrderId: result.merchantOrderId,
          results: result.results,
        });
      }

      return res.status(201).json({
        ok: true,
        message: 'Pedido comercial Mercado Pago processado.',
        processed: true,
        merchantOrderId: result.merchantOrderId,
        sales: result.sales,
        results: result.results,
      });
    }

    if (isMercadoPagoPaymentEvent(req)) {
      if (!paymentId) {
        return res.status(400).json({
          ok: false,
          message: 'Webhook de pagamento sem ID de pagamento.',
        });
      }

      const result = await processMercadoPagoPaymentWebhook({
        paymentId,
        originalWebhookPayload: {
          query: req.query,
          body: req.body,
        },
      });

      if (!result.processed) {
        return res.status(200).json({
          ok: true,
          message: result.reason,
          processed: false,
          paymentId: result.paymentId,
          status: result.status,
        });
      }

      return res.status(201).json({
        ok: true,
        message: result.duplicated
          ? 'Pagamento Mercado Pago já havia sido processado anteriormente.'
          : 'Pagamento Mercado Pago processado e venda gravada no Firestore.',
        processed: true,
        duplicated: result.duplicated,
        sale: result.sale,
      });
    }

    return res.status(200).json({
      ok: true,
      message:
        'Webhook Mercado Pago recebido, mas evento não é payment nem merchant_order.',
      ignored: true,
      eventType,
      eventAction,
    });
  } catch (error) {
    console.error('Erro no webhook Mercado Pago:', {
      message: error.message,
      status: error.status,
      responseBody: error.responseBody,
    });

    if (error.status === 404) {
      return res.status(200).json({
        ok: true,
        processed: false,
        message:
          'Webhook recebido, mas o pagamento ou pedido comercial não foi encontrado no Mercado Pago.',
        mercadoPagoStatus: error.status,
        details: error.responseBody || undefined,
      });
    }

    return res.status(500).json({
      ok: false,
      message: 'Erro interno no webhook Mercado Pago.',
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    message: 'Rota não encontrada.',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TORICO Backend rodando na porta ${PORT}`);
  console.log(`Cliente de teste disponível em /test-client`);
});