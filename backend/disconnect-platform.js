// Only the authenticated Firebase UID owns this operation. No OAuth revocation:
// a merchant may still use the same authorization elsewhere.
export function disconnectPlatformHandler({ auth, db, fieldValue }) {
  return async (req, res) => {
    res.set('Cache-Control', 'no-store');
    const match = /^Bearer (\S+)$/i.exec(req.headers.authorization || '');
    if (!match) return res.status(401).json({ ok: false, message: 'Autenticacao obrigatoria.' });
    let uid;
    try {
      uid = (await auth.verifyIdToken(match[1], true)).uid;
      if (!uid) throw new Error('Missing UID');
    } catch {
      return res.status(401).json({ ok: false, message: 'Sessao invalida. Entre novamente.' });
    }
    if (req.params.platform !== 'mercado_pago') {
      return res.status(400).json({ ok: false, message: 'Plataforma indisponivel.' });
    }
    try {
      const user = db.collection('users').doc(uid);
      const privateRef = user.collection('integrations').doc('mercado_pago');
      const publicRef = user.collection('integration_status').doc('mercado_pago');
      await db.runTransaction(async (tx) => {
        await tx.get(privateRef);
        tx.set(privateRef, {
          platformId: 'mercado_pago', status: 'disconnected',
          accessTokenEncrypted: fieldValue.delete(),
          refreshTokenEncrypted: fieldValue.delete(),
          disconnectedAt: fieldValue.serverTimestamp(),
          updatedAt: fieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(publicRef, {
          platform: 'Mercado Pago', platformId: 'mercado_pago',
          status: 'disconnected', updatedAt: fieldValue.serverTimestamp(),
        });
      });
      return res.status(200).json({ ok: true, platformId: 'mercado_pago', status: 'disconnected' });
    } catch {
      return res.status(503).json({ ok: false, message: 'Nao foi possivel desconectar. Tente novamente.' });
    }
  };
}
