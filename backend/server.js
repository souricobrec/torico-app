import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import admin from 'firebase-admin';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const PORT = process.env.PORT || 3333;
const FIREBASE_SERVICE_ACCOUNT_PATH = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return;
  }

  if (FIREBASE_SERVICE_ACCOUNT_PATH) {
    admin.initializeApp({
      credential: admin.credential.cert(FIREBASE_SERVICE_ACCOUNT_PATH),
    });
    return;
  }

  if (FIREBASE_PROJECT_ID) {
    admin.initializeApp({
      projectId: FIREBASE_PROJECT_ID,
    });
    return;
  }

  throw new Error(
    'Configure FIREBASE_SERVICE_ACCOUNT_PATH ou FIREBASE_PROJECT_ID no arquivo .env.'
  );
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

  const saleRef = db
    .collection('users')
    .doc(userId)
    .collection('sales')
    .doc(safeExternalId);

  await saleRef.set(saleData, { merge: false });

  return {
    id: saleRef.id,
    ...saleData,
  };
}

app.get('/', (req, res) => {
  res.redirect('/test-client');
});

app.get('/test-client', (req, res) => {
  res.sendFile(path.join(__dirname, 'test-client.html'));
});

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    app: 'TORICO Backend',
    mode: 'simulado',
    timestamp: new Date().toISOString(),
  });
});

app.post('/simulate-sale', async (req, res) => {
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

app.post('/webhooks/mercado-pago', async (req, res) => {
  try {
    /*
      Este endpoint ainda é apenas estrutural.

      Na integração real, este fluxo deverá:
      1. Receber a notificação oficial do Mercado Pago.
      2. Validar assinatura/origem conforme documentação oficial.
      3. Buscar o pagamento na API do Mercado Pago usando token seguro do backend.
      4. Identificar a qual usuário TORICO a venda pertence.
      5. Evitar duplicidade usando o ID externo do pagamento.
      6. Gravar em users/{uid}/sales.
    */

    console.log('Webhook Mercado Pago recebido:', req.body);

    return res.status(200).json({
      ok: true,
      message: 'Webhook Mercado Pago recebido em modo estrutural.',
    });
  } catch (error) {
    console.error('Erro no webhook Mercado Pago:', error);

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

app.listen(PORT, () => {
  console.log(`TORICO Backend rodando em http://localhost:${PORT}`);
  console.log(`Cliente de teste disponível em http://localhost:${PORT}/test-client`);
});