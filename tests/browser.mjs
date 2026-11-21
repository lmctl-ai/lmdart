import assert from 'node:assert/strict';
import { readFile } from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const repository = fileURLToPath(new URL('../', import.meta.url));
const root = path.join(repository, 'target/site');
const types = { '.css': 'text/css', '.html': 'text/html', '.js': 'text/javascript', '.svg': 'image/svg+xml', '.json': 'application/json' };
const server = http.createServer((request, response) => {
  const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  const file = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
  if (!file.startsWith(root + path.sep)) {
    response.writeHead(403).end();
    return;
  }
  readFile(file, (error, content) => {
    if (error) {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    response.end(content);
  });
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const base = process.env.DEMO_URL ?? `http://127.0.0.1:${server.address().port}/index.html`;
const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE || undefined,
  args: ['--enable-webgl', '--use-angle=swiftshader']
});
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
const errors = [];
const requests = [];
page.on('pageerror', error => errors.push(`pageerror: ${error.message}`));
page.on('console', message => {
  if (message.type() === 'error') errors.push(`console: ${message.text()}`);
});
page.on('response', response => {
  if (response.status() >= 400) errors.push(`HTTP ${response.status()}: ${response.url()}`);
});
page.on('request', request => requests.push(request.url()));

const chapterUrl = slug => new URL(`demo-${slug}.html`, base).href;
async function open(slug, ready = 'Ready:') {
  await page.goto(chapterUrl(slug));
  await page.waitForFunction(text => document.querySelector('#status')?.textContent.startsWith(text), ready);
  assert.equal(await page.locator('select').count(), 0);
  assert.deepEqual(await page.locator('script[src]').evaluateAll(scripts => scripts.map(script => script.getAttribute('src'))), ['lmdart.js', 'boot.js']);
  assert.equal(await page.locator('.book-nav a').count(), 8);
  assert.equal(await page.locator('.book-nav a[aria-current="page"]').count(), 1);
}
async function canvasImage(selector = '#scene-canvas') {
  return page.locator(selector).evaluate(canvas => canvas.toDataURL());
}
async function canvasColors(selector = '#scene-canvas') {
  return page.locator(selector).evaluate(canvas => {
    const pixels = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data;
    const colors = new Set();
    for (let i = 0; i < pixels.length; i += 400) colors.add(`${pixels[i]},${pixels[i + 1]},${pixels[i + 2]}`);
    return colors.size;
  });
}

await page.goto(base);
await page.waitForFunction(() => window.LMDart?.version === '0.1.0');
assert.equal(await page.locator('.chapter-grid a').count(), 8);
assert.equal(await page.locator('select').count(), 0);
await page.screenshot({ path: path.join(repository, 'target/lmdart-cover.png'), fullPage: true });

await open('hydration');
assert.equal(await page.locator('[data-hydrate="title"]').innerText(), 'This began as static HTML');
assert.equal(await page.locator('#hydration-card').getAttribute('data-hydrated'), 'true');
assert.equal(await page.locator('#action').innerText(), 'Run the JavaScript handler');
await page.locator('#action').click();
assert.equal(await page.locator('#hydration-result').innerText(), 'Dart received hydration click 1; JavaScript updated this static card.');
assert.equal(await page.locator('#hydration-card').getAttribute('data-state'), 'active');
await page.screenshot({ path: path.join(repository, 'target/lmdart-hydration.png'), fullPage: true });

await open('table');
assert.equal(await page.locator('#data-table').getAttribute('data-bound'), 'true');
assert.equal(await page.locator('#data-table tbody tr').count(), 5);
assert.equal(await page.locator('#data-table th').count(), 3);
await page.locator('#data-table tr[data-row="2"]').click();
assert.equal(await page.locator('#table-result').innerText(), 'Selected Charts; row 3 from the JSON model.');
assert.equal(await page.locator('#data-table tr[data-row="2"]').getAttribute('data-selected'), 'true');
await page.locator('#data-table tr[data-row="1"]').focus();
await page.keyboard.press('Enter');
assert.match(await page.locator('#table-result').innerText(), /Selected Drawing/);

await open('svg');
assert.equal(await page.locator('#scene svg').count(), 1);
assert.equal(await page.locator('#scene svg circle').count(), 2);
assert.equal(await page.locator('#scene svg polyline').count(), 1);
await page.locator('#action').click();
assert.match(await page.locator('#status').innerText(), /#ffcb6b/);
assert.equal(await page.locator('#scene svg circle').first().getAttribute('fill'), '#ffcb6b');

await open('canvas');
assert.ok(await canvasColors() > 15);
await page.locator('#scene-canvas').click({ position: { x: 300, y: 180 } });
assert.match(await page.locator('#status').innerText(), /1 JavaScript-approved pointer mark/);
await page.locator('#scene-canvas').click({ position: { x: 360, y: 220 } });
assert.match(await page.locator('#status').innerText(), /2 JavaScript-approved pointer mark/);
await page.locator('#action').click();
assert.match(await page.locator('#status').innerText(), /cleared/);

await open('chart');
assert.equal(await page.locator('#bar-chart svg rect').count(), 6);
assert.equal(await page.locator('#pie-chart svg path').count(), 4);
assert.equal(await page.locator('#pie-chart svg text').filter({ hasText: '38%' }).count(), 1);
assert.equal(await page.locator('#bar-chart svg text').filter({ hasText: 'Weekly activity' }).count(), 1);
await page.screenshot({ path: path.join(repository, 'target/lmdart-charts.png'), fullPage: true });

await open('plot');
assert.ok(await canvasColors('#line-plot') > 15);
assert.ok(await canvasColors('#scatter-plot') > 15);
assert.notEqual(await canvasImage('#line-plot'), await canvasImage('#scatter-plot'));

await open('animation');
const transform1 = await page.locator('#tween-group').getAttribute('transform');
const radius1 = await page.locator('#tween-dot').getAttribute('r');
await page.waitForTimeout(250);
assert.notEqual(await page.locator('#tween-group').getAttribute('transform'), transform1);
assert.notEqual(await page.locator('#tween-dot').getAttribute('r'), radius1);
await page.locator('#action').click();
assert.equal(await page.locator('#action').innerText(), 'Resume animation');
await page.waitForTimeout(60);
const stoppedTransform = await page.locator('#tween-group').getAttribute('transform');
const stoppedRadius = await page.locator('#tween-dot').getAttribute('r');
const stoppedCanvas = await canvasImage('#particle-canvas');
await page.waitForTimeout(180);
assert.equal(await page.locator('#tween-group').getAttribute('transform'), stoppedTransform);
assert.equal(await page.locator('#tween-dot').getAttribute('r'), stoppedRadius);
assert.equal(await canvasImage('#particle-canvas'), stoppedCanvas);
await page.locator('#reset').click();
assert.equal(await page.locator('#tween-group').getAttribute('transform'), 'translate(90 100)');
assert.equal(await page.locator('#tween-dot').getAttribute('r'), '22');
await page.locator('#action').press('Space');
assert.equal(await page.locator('#action').innerText(), 'Pause animation');
await page.screenshot({ path: path.join(repository, 'target/lmdart-animation.png'), fullPage: true });

await open('webgl');
const webgl1 = await canvasImage();
await page.waitForTimeout(180);
assert.notEqual(await canvasImage(), webgl1);
const webgl = await page.locator('#scene-canvas').evaluate(canvas => {
  const gl = canvas.getContext('webgl');
  const pixels = new Uint8Array(canvas.width * canvas.height * 4);
  gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
  const background = [pixels[0], pixels[1], pixels[2]];
  let colored = 0;
  for (let i = 0; i < pixels.length; i += 4) {
    if (pixels[i] !== background[0] || pixels[i + 1] !== background[1] || pixels[i + 2] !== background[2]) colored++;
  }
  return { colored, error: gl.getError(), version: gl.getParameter(gl.VERSION) };
});
assert.ok(webgl.colored > 30000);
assert.equal(webgl.error, 0);
assert.match(webgl.version, /WebGL/);
await page.locator('#action').click();
await page.waitForTimeout(60);
const stopped = await canvasImage();
await page.waitForTimeout(180);
assert.equal(await canvasImage(), stopped);
await page.locator('#reset').click();
assert.match(await page.locator('#status').innerText(), /reset/);
await page.screenshot({ path: path.join(repository, 'target/lmdart-webgl.png'), fullPage: true });

await page.goto(base);
await page.setViewportSize({ width: 390, height: 844 });
assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
await open('animation');
assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
await page.screenshot({ path: path.join(repository, 'target/lmdart-mobile.png'), fullPage: true });

assert.deepEqual(errors, []);
const allowedOrigins = new Set([new URL(base).origin, new URL(page.url()).origin]);
assert.deepEqual(requests.filter(url => !allowedOrigins.has(new URL(url).origin)), []);
console.log(JSON.stringify({ pages: 9, runtime: 'Dart 3.14.1 + registered JavaScript handlers', hydration: 'static HTML + JSON + JavaScript to Dart call', table: '5 rows, pointer and keyboard', drawing: 'JSON SVG and Canvas', charts: 'bar, pie, line, scatter', tween: 'position, radius, opacity, Canvas particles', webgl, controls: 'pause, reset, keyboard', mobile: 'no overflow', errors }, null, 2));
await browser.close();
server.close();
