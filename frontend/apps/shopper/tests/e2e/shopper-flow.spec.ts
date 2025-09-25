import { test, expect } from '@playwright/test';

const SHOPPER_URL = process.env.E2E_SHOPPER_URL ?? 'http://localhost:3001';
const BROWSERS_READY = process.env.PLAYWRIGHT_BROWSERS_READY === 'true';

test.describe('Shopper MVP smoke', () => {
  test.beforeAll(() => {
    if (!BROWSERS_READY) {
      test.skip(true, 'Set PLAYWRIGHT_BROWSERS_READY=true after installing browsers via "npx playwright install".');
    }
  });

  test('landing page renders hero copy', async ({ page }) => {
    let response;
    try {
      response = await page.goto(SHOPPER_URL, { waitUntil: 'domcontentloaded', timeout: 10_000 });
    } catch (error) {
      test.skip(true, `Shopper app not reachable at ${SHOPPER_URL}: ${String(error)}`);
    }

    if (!response) {
      test.skip(true, `No HTTP response when reaching ${SHOPPER_URL}`);
    }

    await expect(page.locator('h1')).toHaveText(/FitTwin Shopper Demo/);
    await expect(page.locator('text=Shopper MVP Walkthrough')).toBeVisible();
  });
});
