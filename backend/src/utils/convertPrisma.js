/**
 * Recursively convert Prisma Decimal fields to numbers and Date objects to ISO strings
 * so the result is safe for JSON serialization.
 *
 * Note: We do this manually instead of relying on JSON.stringify's replacer because
 * Decimal.js's toJSON() may be called before the replacer, returning a string.
 */
function convertPrismaToJson(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj instanceof Date) return obj.toISOString();
  if (typeof obj === 'bigint') return Number(obj);
  if (typeof obj === 'object' && typeof obj.toNumber === 'function') {
    return Number(obj);
  }
  if (Array.isArray(obj)) {
    return obj.map(convertPrismaToJson);
  }
  if (typeof obj === 'object') {
    const result = {};
    for (const key of Object.keys(obj)) {
      result[key] = convertPrismaToJson(obj[key]);
    }
    return result;
  }
  return obj;
}

module.exports = { convertPrismaToJson };
