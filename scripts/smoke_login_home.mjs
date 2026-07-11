#!/usr/bin/env node
/**
 * Live smoke: bizagent.sk login → dashboard (home).
 * Usage: SMOKE_EMAIL=... SMOKE_PASSWORD=... node scripts/smoke_login_home.mjs
 */
import { chromium } from 'playwright';

const BASE = process.env.SMOKE_BASE_URL || 'https://bizagent.sk';
const EMAIL = process.env.SMOKE_EMAIL || 'bizagent@bizagent.sk';
const PASSWORD = process.env.SMOKE_PASSWORD;
const TIMEOUT_MS = 120_000;

if (!PASSWORD) {
  console.error('Chýba SMOKE_PASSWORD');
  process.exit(1);
}

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
page.setDefaultTimeout(TIMEOUT_MS);

let failed = false;
const ok = (msg) => console.log(`✅ ${msg}`);
const fail = (msg) => {
  console.error(`❌ ${msg}`);
  failed = true;
};

try {
  console.log(`→ Otváram ${BASE}/#/login`);
  await page.goto(`${BASE}/#/login`, { waitUntil: 'domcontentloaded' });

  // Flutter web boot
  await page.waitForTimeout(8000);

  // Flutter web release často nemá aria labels — skús viac selektorov
  const emailSelectors = [
    () => page.getByLabel('Email', { exact: false }),
    () => page.locator('input[type="email"]'),
    () => page.locator('input').first(),
    () => page.locator('textarea').first(),
  ];
  const passSelectors = [
    () => page.getByLabel('Heslo', { exact: false }),
    () => page.locator('input[type="password"]'),
    () => page.locator('input').nth(1),
  ];

  let emailField = null;
  for (const pick of emailSelectors) {
    const loc = pick();
    if (await loc.isVisible().catch(() => false)) {
      emailField = loc;
      break;
    }
  }
  if (!emailField) {
    await page.waitForTimeout(5000);
    emailField = page.locator('input, textarea').first();
    await emailField.waitFor({ state: 'visible', timeout: 60_000 });
  }

  let passField = null;
  for (const pick of passSelectors) {
    const loc = pick();
    if (await loc.isVisible().catch(() => false)) {
      passField = loc;
      break;
    }
  }
  if (!passField) {
    passField = page.locator('input, textarea').nth(1);
    await passField.waitFor({ state: 'visible', timeout: 30_000 });
  }
  ok('Login obrazovka — input polia nájdené');

  await emailField.fill(EMAIL);
  await passField.fill(PASSWORD);

  const loginBtn = page.getByRole('button', { name: /Prihlásiť sa/i });
  await loginBtn.click();
  ok('Klik na Prihlásiť sa');

  // Po úspechu: hash /dashboard alebo dashboard UI (Vitajte / Prehľad)
  const deadline = Date.now() + 90_000;
  let onDashboard = false;
  while (Date.now() < deadline) {
    const url = page.url();
    if (url.includes('/dashboard') || url.includes('#/dashboard')) {
      onDashboard = true;
      break;
    }
    const dashboardHint = await page
      .getByText(/Vitajte|Prehľad|Dashboard|Faktúry/i)
      .first()
      .isVisible()
      .catch(() => false);
    if (dashboardHint && !url.includes('/login')) {
      onDashboard = true;
      break;
    }
    await page.waitForTimeout(1500);
  }

  const finalUrl = page.url();
  console.log(`→ Finálna URL: ${finalUrl}`);

  if (finalUrl.includes('?code=')) {
    fail('OAuth callback — ?code= stále v URL (session sa nevymenila)');
  }

  if (onDashboard) {
    ok('Presmerované na home / dashboard');
  } else if (finalUrl.includes('/login')) {
    fail('Stále na /login — prihlásenie neprešlo');
    const shot = '/tmp/bizagent_smoke_login_fail.png';
    await page.screenshot({ path: shot, fullPage: true });
    console.error(`Screenshot: ${shot}`);
  } else {
    ok(`Presmerované mimo login (${finalUrl})`);
  }
} catch (e) {
  fail(`Výnimka: ${e.message}`);
  try {
    await page.screenshot({ path: '/tmp/bizagent_smoke_error.png', fullPage: true });
  } catch (_) {}
} finally {
  await browser.close();
}

process.exit(failed ? 1 : 0);