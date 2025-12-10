import { expect, test } from '@playwright/test'

test('homepage shows Hello HQ', async ({ page }) => {
	await page.goto('/')
	await expect(page.getByRole('heading', { name: 'Hello HQ' })).toBeVisible()
})
