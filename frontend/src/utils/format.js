/**
 * Safely format geographic coordinates (latitude, longitude)
 * Prevents TypeError when coordinate is passed as Decimal string or null/undefined
 */
export const formatCoord = (val, digits = 4) => {
  if (val === null || val === undefined || val === '') return '-';
  const num = Number(val);
  return isNaN(num) ? String(val) : num.toFixed(digits);
};
