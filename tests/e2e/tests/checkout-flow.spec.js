/**
 * E2E Test: Complete Checkout Flow
 * 
 * Tests the full user journey from landing page to order confirmation.
 */

const { test, expect } = require('@playwright/test');

test.describe('Checkout Flow', () => {
  test('user can complete full checkout process', async ({ page }) => {
    // Navigate to home page
    await page.goto('/');
    
    // Verify landing page loads
    await expect(page.locator('h1')).toContainText('FitTwin');
    
    // Click "Get Started" or similar CTA
    await page.click('text=Get Started');
    
    // TODO: Add measurement capture simulation
    // This would require mocking camera/LiDAR input
    
    // Navigate to results page (assuming measurements are complete)
    await page.goto('/results');
    
    // Add item to cart
    await page.click('button:has-text("Add to Cart")');
    
    // Verify cart badge updates
    await expect(page.locator('[data-testid="cart-badge"]')).toContainText('1');
    
    // Go to cart
    await page.click('[data-testid="cart-icon"]');
    
    // Verify cart page
    await expect(page).toHaveURL(/.*cart/);
    await expect(page.locator('[data-testid="cart-item"]')).toBeVisible();
    
    // Proceed to checkout
    await page.click('button:has-text("Checkout")');
    
    // Fill in shipping address
    await page.fill('[name="address"]', '123 Main St');
    await page.fill('[name="city"]', 'San Francisco');
    await page.fill('[name="state"]', 'CA');
    await page.fill('[name="zip"]', '94102');
    
    // Fill in payment info (test mode)
    await page.fill('[name="cardNumber"]', '4242424242424242');
    await page.fill('[name="expiry"]', '12/25');
    await page.fill('[name="cvc"]', '123');
    
    // Submit order
    await page.click('button:has-text("Place Order")');
    
    // Verify order confirmation
    await expect(page).toHaveURL(/.*confirmation/);
    await expect(page.locator('h1')).toContainText('Order Confirmed');
    await expect(page.locator('[data-testid="order-number"]')).toBeVisible();
  });

  test('cart persists across page refreshes', async ({ page }) => {
    // Add item to cart
    await page.goto('/results');
    await page.click('button:has-text("Add to Cart")');
    
    // Refresh page
    await page.reload();
    
    // Verify cart still has item
    await expect(page.locator('[data-testid="cart-badge"]')).toContainText('1');
  });

  test('user cannot checkout with empty cart', async ({ page }) => {
    await page.goto('/cart');
    
    // Verify checkout button is disabled
    await expect(page.locator('button:has-text("Checkout")')).toBeDisabled();
  });
});
