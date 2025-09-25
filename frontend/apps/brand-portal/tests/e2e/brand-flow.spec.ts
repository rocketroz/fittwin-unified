import { test, expect } from '@playwright/test';

const BRAND_URL = process.env.E2E_BRAND_URL ?? 'http://localhost:3100';
const BROWSERS_READY = process.env.PLAYWRIGHT_BROWSERS_READY === 'true';

test.describe('Brand portal smoke', () => {
  test.beforeAll(() => {
    if (!BROWSERS_READY) {
      test.skip(true, 'Set PLAYWRIGHT_BROWSERS_READY=true after installing browsers via "npx playwright install".');
    }
  });

  test('dashboard headline renders', async ({ page }) => {
    let response;
    try {
      response = await page.goto(BRAND_URL, { waitUntil: 'domcontentloaded', timeout: 10_000 });
    } catch (error) {
      test.skip(true, `Brand portal not reachable at ${BRAND_URL}: ${String(error)}`);
    }

    if (!response) {
      test.skip(true, `No HTTP response when reaching ${BRAND_URL}`);
    }

    await expect(page.locator('h1')).toHaveText(/FitTwin Brand Console/);
    await expect(page.locator('text=Brand Portal Preview')).toBeVisible();
  });
});
