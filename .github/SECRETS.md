# GitHub Secrets Configuration

**Repository**: `rocketroz/fittwin-unified`  
**Last Updated**: 2025-11-09

---

## 📋 Overview

This document describes the GitHub Secrets required for CI/CD workflows in the FitTwin unified repository.

---

## 🔐 Required Secrets

### **For iOS POC CI** (`ios-poc.yml`)

| Secret Name | Required | Default | Description |
|-------------|----------|---------|-------------|
| `FITWIN_API_KEY` | No | `staging-secret-key` | Python measurement API authentication key |
| `JWT_SECRET` | No | `test-jwt-secret` | JWT signing secret for authentication |
| `SUPABASE_URL` | No | `http://localhost:54321` | Supabase project URL |
| `SUPABASE_ANON_KEY` | No | `test-anon-key` | Supabase anonymous key |
| `SUPABASE_SERVICE_ROLE_KEY` | No | `test-service-key` | Supabase service role key |

**Note**: All secrets have defaults for testing. Production deployments should set actual values.

---

## 🔧 How to Add Secrets

### **Step 1: Navigate to Repository Settings**

1. Go to https://github.com/rocketroz/fittwin-unified
2. Click **Settings** (top right)
3. In left sidebar, click **Secrets and variables** → **Actions**

### **Step 2: Add New Secret**

1. Click **New repository secret**
2. Enter **Name** (e.g., `FITWIN_API_KEY`)
3. Enter **Value** (the actual secret)
4. Click **Add secret**

### **Step 3: Repeat for All Secrets**

Add each secret from the table above.

---

## 🎯 Secret Values

### **Development/Staging**

```bash
FITWIN_API_KEY=staging-secret-key
JWT_SECRET=your-development-jwt-secret-min-32-chars
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
```

### **Production**

```bash
FITWIN_API_KEY=prod-secret-key-xyz-change-this
JWT_SECRET=your-production-jwt-secret-min-32-chars-very-secure
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=your-production-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-production-supabase-service-role-key
```

---

## 📊 Secrets Usage

### **iOS POC Workflow** (`.github/workflows/ios-poc.yml`)

**Python Service Job**:
```yaml
env:
  API_KEY: ${{ secrets.FITWIN_API_KEY || 'staging-secret-key' }}
  JWT_SECRET: ${{ secrets.JWT_SECRET || 'test-jwt-secret' }}
  SUPABASE_URL: ${{ secrets.SUPABASE_URL || 'http://localhost:54321' }}
  SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY || 'test-anon-key' }}
  SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY || 'test-service-key' }}
```

**Fallback Logic**:
- If secret is set → use secret value
- If secret is not set → use default value
- This allows CI to run even without secrets configured

---

## 🔍 Verifying Secrets

### **Check if Secrets are Set**

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. You should see a list of configured secrets
3. You cannot view secret values (security feature)

### **Test in Workflow**

Secrets are automatically injected into workflow environment variables. Check workflow logs:

```
✅ All required env vars present
```

Or:

```
⚠️ Missing env vars: ['JWT_SECRET']
```

---

## 🔐 Security Best Practices

### **Secret Management**

1. ✅ **Never commit secrets** to Git
2. ✅ **Use different secrets** for dev/staging/prod
3. ✅ **Rotate secrets regularly** (every 90 days)
4. ✅ **Use strong, random values** (min 32 characters)
5. ✅ **Limit secret access** to necessary workflows only

### **JWT Secret Requirements**

- **Minimum length**: 32 characters
- **Recommended**: 64+ characters
- **Format**: Random alphanumeric + special chars
- **Example**: `a8f5f167f44f4964e6c998dee827110c3e6f9f8b8a8f5f167f44f4964e6c998d`

**Generate secure JWT secret**:
```bash
# Using OpenSSL
openssl rand -hex 32

# Using Python
python -c "import secrets; print(secrets.token_hex(32))"

# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### **API Key Requirements**

- **Format**: `staging-secret-key` (dev) or `prod-secret-key-xyz` (prod)
- **Length**: 20+ characters
- **Uniqueness**: Different for each environment

---

## 🚨 If Secrets are Compromised

### **Immediate Actions**

1. **Revoke compromised secrets** immediately
2. **Generate new secrets** using secure methods
3. **Update GitHub Secrets** with new values
4. **Update local `.env` files** (if applicable)
5. **Notify team members**
6. **Review access logs** for unauthorized usage

### **Prevention**

- ✅ Never log secret values
- ✅ Never expose secrets in error messages
- ✅ Use `.gitignore` for `.env` files
- ✅ Review PRs for accidental secret commits
- ✅ Use secret scanning tools (GitHub Advanced Security)

---

## 📝 Secrets Checklist

### **Before Production Deployment**

- [ ] All secrets configured in GitHub
- [ ] Secrets are production-grade (strong, unique)
- [ ] JWT secret is 32+ characters
- [ ] API keys are different from staging
- [ ] Supabase keys are from production project
- [ ] Secrets are documented (this file)
- [ ] Team members know how to rotate secrets
- [ ] Backup secrets stored securely (password manager)

### **Regular Maintenance**

- [ ] Rotate secrets every 90 days
- [ ] Review secret usage in workflows
- [ ] Remove unused secrets
- [ ] Update documentation when secrets change
- [ ] Test workflows after secret rotation

---

## 🔗 Related Documentation

- **GitHub Actions Workflows**: `.github/workflows/`
- **Python Service Config**: `services/python/measurement/backend/app/core/config.py`
- **iOS POC Config**: `mobile/ios/FitTwinMeasurePOC/FitTwinMeasure/Info.plist`
- **Environment Variables**: `services/python/measurement/.env.example`

---

## 📚 References

### **GitHub Documentation**

- [Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Using secrets in workflows](https://docs.github.com/en/actions/security-guides/encrypted-secrets#using-encrypted-secrets-in-a-workflow)
- [Secret scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)

### **Security Best Practices**

- [OWASP Secret Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

## 💡 Tips

1. **Use environment-specific secrets**: Create separate secrets for `dev`, `staging`, `prod`
2. **Test with defaults first**: Workflows use defaults if secrets aren't set
3. **Document secret rotation**: Keep a log of when secrets were last rotated
4. **Use secret scanning**: Enable GitHub Advanced Security for automatic detection
5. **Backup secrets securely**: Use a password manager (1Password, LastPass, etc.)

---

## 🆘 Troubleshooting

### **Issue: Workflow fails with "Missing env vars"**

**Solution**: Add the missing secret in GitHub repository settings.

### **Issue: "Invalid API key" in workflow logs**

**Solution**: 
1. Verify secret name matches exactly (case-sensitive)
2. Check secret value is correct
3. Ensure no extra whitespace in secret value

### **Issue: Cannot see secret value**

**Solution**: This is expected. GitHub never displays secret values after creation. If you need to verify, delete and recreate the secret.

---

**Last Updated**: 2025-11-09  
**Maintained By**: FitTwin Development Team  
**Contact**: Repository administrators
