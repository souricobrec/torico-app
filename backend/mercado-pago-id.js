const invalid = () => Object.assign(new Error('merchant_id_review_required'), {status:409,code:'merchant_id_review_required'});
export function canonicalMerchantId(value) {
  if (typeof value === 'number') {
    if (!Number.isSafeInteger(value) || value <= 0) throw invalid();
    return String(value);
  }
  if (typeof value !== 'string' || !/^\d{1,64}$/.test(value.trim())) {
    throw invalid();
  }
  const canonical = BigInt(value.trim()).toString();
  if (canonical === '0' || canonical.length > 30) throw invalid();
  return canonical;
}
