const compromisedPasswords = new Set([
  'password123',
  '1234567890',
  'qwertyuiop',
  'letmein123',
  'welcome@123'
]);

export function isBreachedPassword(password: string): boolean {
  return compromisedPasswords.has(password.toLowerCase());
}
