/* Browser-only design prototype checks. Does not validate Flutter/mobile builds.
 * Start repository server: python -m http.server 8765 --bind 127.0.0.1
 * Then: node tool/preview_smoke.cjs
 * Optional: PREVIEW_URL, CHROMIUM_EXECUTABLE, PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
let chromium;
try {
  ({ chromium } = require('playwright'));
} catch {
  ({ chromium } = require('/opt/codex/cua_node/lib/node_modules/playwright'));
}
const url = process.env.PREVIEW_URL || 'http://127.0.0.1:8765/design/';
const executablePath = process.env.CHROMIUM_EXECUTABLE ||
  process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || '/usr/bin/chromium';
const output = path.resolve(__dirname, '../docs/previews');
fs.mkdirSync(output, { recursive: true });
let checks = 0;
function check(name, callback) {
  callback();
  checks++;
  console.log(`PASS ${checks}: ${name}`);
}
async function capture(page, name) {
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);
  await page.screenshot({ path: path.join(output, `${name}.png`), animations: 'disabled' });
}
(async () => {
  const browser = await chromium.launch({ executablePath, headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(url, { waitUntil: 'networkidle' });
    const heading = await page.locator('h1').textContent();
    check('home rendered', () => assert.equal(heading, '好生活，从找到家开始。'));
    await capture(page, 'home-light');
    await page.locator('.header-right .theme-toggle').click();
    let dark = await page.locator('body').evaluate(body => body.classList.contains('dark'));
    check('dark theme toggled', () => assert.equal(dark, true));
    await capture(page, 'home-dark');
    await page.locator('.featured-card .save').click();
    await page.locator('nav [data-page="favorites"]').click();
    let count = await page.locator('.favorites-grid article').count();
    check('listing saved to favorites', () => assert.equal(count, 1));
    await page.reload({ waitUntil: 'networkidle' });
    dark = await page.locator('body').evaluate(body => body.classList.contains('dark'));
    check('theme persisted after reload', () => assert.equal(dark, true));
    await page.locator('nav [data-page="favorites"]').click();
    count = await page.locator('.favorites-grid article').count();
    check('favorite persisted after reload', () => assert.equal(count, 1));
    await page.locator('nav [data-page="home"]').click();
    await page.locator('form[data-search-form] input').fill('Harbour');
    await page.locator('form[data-search-form]').evaluate(form => form.requestSubmit());
    count = await page.locator('.map-marker').count();
    check('address search filtered map', () => assert.equal(count, 1));
    let text = await page.locator('.map-mobile-card').textContent();
    check('search selected correct listing', () => assert.match(text, /88 Harbour/));
    await page.locator('[data-filters]').first().click();
    await page.selectOption('#filterBeds', '4');
    await page.locator('#filterForm button[value="apply"]').click();
    await page.waitForTimeout(50);
    count = await page.locator('.map-marker').count();
    check('bedroom filter yielded zero results', () => assert.equal(count, 0));
    text = await page.locator('.map-mobile-card').textContent();
    check('empty results explained', () => assert.match(text, /没有匹配房源/));
    await page.locator('.map-mobile-card [data-reset]').click();
    count = await page.locator('.map-marker').count();
    check('clear filters restored six listings', () => assert.equal(count, 6));
    await page.locator('[data-marker="yj-04"]').click();
    text = await page.locator('.map-mobile-card').textContent();
    check('map marker changed preview selection', () => assert.match(text, /88 Harbour/));
    await page.locator('.map-mobile-card .card-content').click();
    const detailOpen = await page.locator('#detail').evaluate(dialog => dialog.open);
    check('property detail opened', () => assert.equal(detailOpen, true));
    const firstPhoto = await page.locator('.detail-photo img').getAttribute('src');
    await page.locator('#nextPhoto').click();
    const nextPhoto = await page.locator('.detail-photo img').getAttribute('src');
    check('gallery advanced photo', () => assert.notEqual(nextPhoto, firstPhoto));
    await page.locator('#closeDetail').click();
    await capture(page, 'map-dark');
    await page.locator('.header-right .theme-toggle').click();
    await capture(page, 'map-light');
    await page.locator('[data-list]').click();
    const listMode = await page.locator('.map-layout').evaluate(element => element.classList.contains('list-only'));
    check('map switched to list', () => assert.equal(listMode, true));
    await page.locator('nav [data-page="ai"]').click();
    text = await page.locator('.standalone').textContent();
    check('AI page clearly identifies unavailable integration', () => assert.match(text, /尚未接入/));
    await page.locator('nav [data-page="profile"]').click();
    text = await page.locator('.standalone').textContent();
    check('personal page rendered', () => assert.match(text, /账户与登录/));
    let width = await page.evaluate(() => document.documentElement.scrollWidth);
    check('390px mobile has no horizontal overflow', () => assert.equal(width, 390));
    for (const viewportWidth of [320, 430, 768]) {
      await page.setViewportSize({ width: viewportWidth, height: 844 });
      await page.locator('nav [data-page="home"]').click();
      width = await page.evaluate(() => document.documentElement.scrollWidth);
      check(`${viewportWidth}px home has no horizontal overflow`, () => assert.equal(width, viewportWidth));
      await page.locator('nav [data-page="map"]').click();
      width = await page.evaluate(() => document.documentElement.scrollWidth);
      check(`${viewportWidth}px map has no horizontal overflow`, () => assert.equal(width, viewportWidth));
    }
    await page.setViewportSize({ width: 1440, height: 1000 });
    await page.locator('nav [data-page="home"]').click();
    width = await page.evaluate(() => document.documentElement.scrollWidth);
    check('1440px desktop has no horizontal overflow', () => assert.equal(width, 1440));
    await capture(page, 'desktop-light');
    check('no browser JavaScript errors', () => assert.deepEqual(errors, []));
    console.log(`\n${checks} checks passed. Five screenshots saved in ${output}`);
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
