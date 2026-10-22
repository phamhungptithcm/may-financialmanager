/** Capture actual HTML states with Playwright. Requires project-local `playwright` dependency and browsers.
 * Usage: node scripts/capture_mockup.mjs --out docs/qa/evidence/home.png --viewport 390x844
 *        node scripts/capture_mockup.mjs --actions docs/qa/capture-actions.example.json
 * Each action is {"type":"click|fill|wait|screenshot|press","selector":"...","value":"...","ms":...,"name":"..."}.
 * This is only a capture helper; it does not assert UI correctness or discover every route automatically.
 */
import http from 'node:http';
import fs from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docs = path.join(root, 'docs');
const file = path.join(docs, 'FamilyClanMockupFullFlow.html');
const args = process.argv.slice(2);
function option(name, fallback) { const i=args.indexOf(name); return i>=0 ? args[i+1] : fallback; }
const name = option('--out','docs/qa/evidence/mockup-home.png');
const dims = option('--viewport','390x844').split('x').map(Number);
const actionsFile = option('--actions', null);
if (!existsSync(file)) { console.error('BLOCKED: original mockup missing'); process.exit(2); }
const target = path.resolve(root, name);
if (!target.startsWith(path.join(root,'docs','qa') + path.sep)) {
  console.error('BLOCKED: output must be under docs/qa/'); process.exit(2);
}
let chromium;
try { ({ chromium } = await import('playwright')); }
catch (e) { console.error('BLOCKED: install Playwright locally and download required browser (not auto-installed).'); process.exit(3); }
const mime = ext => ({'.html':'text/html; charset=utf-8','.css':'text/css','.js':'application/javascript','.png':'image/png','.jpg':'image/jpeg','.svg':'image/svg+xml','.json':'application/json'})[ext] || 'application/octet-stream';
const server = http.createServer(async(req,res) => {
  const requestPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const local = path.resolve(docs, '.' + requestPath);
  if (!local.startsWith(docs + path.sep) || !existsSync(local)) { res.writeHead(404); res.end('Not found'); return; }
  try { const data = await fs.readFile(local); res.writeHead(200, {'Content-Type':mime(path.extname(local))}); res.end(data); }
  catch {res.writeHead(500);res.end('Server error');}
});
await new Promise(resolve => server.listen(0, '127.0.0.1',resolve));
const browser = await chromium.launch({headless:true});
try {
  const page = await browser.newPage({viewport:{width:dims[0],height:dims[1]},deviceScaleFactor:1, reducedMotion:'no-preference'});
  const errors = [];
  page.on('pageerror', err => errors.push(err.message));
  const url = `http://127.0.0.1:${server.address().port}/FamilyClanMockupFullFlow.html`;
  await page.goto(url,{waitUntil:'domcontentloaded'});
  await page.waitForTimeout(400);
  await fs.mkdir(path.dirname(target),{recursive:true});
  if (actionsFile) {
    const actions = JSON.parse(await fs.readFile(path.resolve(root,actionsFile),'utf8'));
    for (let idx = 0; idx < actions.length; idx++) {
      const a = actions[idx];
      if(a.type==='click') await page.locator(a.selector).click();
      else if(a.type==='fill') await page.locator(a.selector).fill(a.value);
      else if(a.type==='wait') await page.waitForTimeout(a.ms);
      else if(a.type==='press') await page.locator(a.selector).press(a.value);
      else if(a.type==='screenshot') {
        const location=path.resolve(root,'docs/qa/evidence',a.name || `state-${idx}.png`);
        if(!location.startsWith(path.resolve(root,'docs/qa/evidence') + path.sep)) throw Error('Invalid screenshot filename');
        await fs.mkdir(path.dirname(location),{recursive:true});
        await page.screenshot({path:location,fullPage:true});
      } else throw Error(`Unsupported action: ${a.type}`);
    }
  }
  await page.screenshot({path:target,fullPage:true});
  console.log(JSON.stringify({url,viewport:dims,screenshot:path.relative(root,target),pageErrors:errors},null,2));
  if(errors.length) process.exitCode=1;
} finally { await browser.close(); await new Promise(resolve=>server.close(resolve)); }
