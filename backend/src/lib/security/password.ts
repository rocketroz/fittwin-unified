import { createHash, randomBytes } from 'crypto';

export interface PasswordValidationResult {
  valid: boolean;
  errors: string[];
}

export function validatePasswordStrength(password: string): PasswordValidationResult {
  const errors: string[] = [];
  if (password.length < 12) {
    errors.push('Password must be at least 12 characters long.');
  }
  if (!/[A-Z]/.test(password)) {
    errors.push('Password must include an uppercase letter.');
  }
  if (!/[a-z]/.test(password)) {
    errors.push('Password must include a lowercase letter.');
  }
  if (!/[0-9]/.test(password)) {
    errors.push('Password must include a digit.');
  }
  if (!/[^A-Za-z0-9]/.test(password)) {
    errors.push('Password must include a special character.');
  }
  return { valid: errors.length === 0, errors };
}

export interface HashedPassword {
  hash: string;
  salt: string;
}

export function hashPassword(password: string, salt: string = randomBytes(16).toString('hex')): HashedPassword {
  const hash = createHash('sha256').update(`${salt}:${password}`).digest('hex');
  return { hash, salt };
}

export function verifyPassword(password: string, hashed: HashedPassword): boolean {
  const comparison = hashPassword(password, hashed.salt);
  return comparison.hash === hashed.hash;
}
