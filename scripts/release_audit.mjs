#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');
const publicDir = path.join(repoRoot, 'public');

const failures = [];
const warnings = [];
let passed = 0;

function ok(label) {
  passed += 1;
  console.log(`PASS ${label}`);
}

function fail(label, detail) {
  failures.push({ label, detail });
  console.log(`FAIL ${label}${detail ? ` - ${detail}` : ''}`);
}

function warn(label, detail) {
  warnings.push({ label, detail });
  console.log(`WARN ${label}${detail ? ` - ${detail}` : ''}`);
}

function check(label, condition, detail) {
  if (condition) ok(label);
  else fail(label, detail);
}

function readFile(relPath) {
  const absPath = path.join(repoRoot, relPath);
  return fs.readFileSync(absPath, 'utf8');
}

function exists(relPath) {
  return fs.existsSync(path.join(repoRoot, relPath));
}

function resolvePublicPath(rawUrl) {
  const stripped = rawUrl.split('#')[0].split('?')[0];
  if (!stripped.startsWith('/')) return null;
  if (stripped === '/') return path.join(publicDir, 'index.html');

  const absolute = path.join(publicDir, stripped.replace(/^\/+/, ''));
  if (stripped.endsWith('/')) return path.join(absolute, 'index.html');

  return absolute;
}

function collectLocalReferences(html) {
  const refs = new Set();
  const attrRegex = /\b(?:href|src|data-src)=["']([^"']+)["']/g;
  let match;

  while ((match = attrRegex.exec(html))) {
    const value = match[1].trim();
    if (!value) continue;
    if (value.startsWith('http://') || value.startsWith('https://')) continue;
    if (value.startsWith('mailto:') || value.startsWith('tel:')) continue;
    if (value.startsWith('javascript:') || value.startsWith('data:')) continue;
    if (!value.startsWith('/')) continue;
    refs.add(value);
  }

  return Array.from(refs).sort();
}

const requiredFiles = [
  'public/index.html',
  'public/main.css',
  'public/sw.js',
  'public/robots.txt',
  'public/sitemap.xml',
  'public/llms.txt',
  'public/favicon.svg',
  'public/og-image.png',
];

console.log('== D.O.T.S AI release audit ==');

for (const relPath of requiredFiles) {
  check(`file exists: ${relPath}`, exists(relPath), `${relPath} is missing`);
}

const html = readFile('public/index.html');
const sw = readFile('public/sw.js');

check('viewport meta present', /<meta name="viewport" content="width=device-width,\s*initial-scale=1\.0">/i.test(html), 'Missing responsive viewport tag');
check('canonical points to dotsai.in', /<link rel="canonical" href="https:\/\/dotsai\.in">/i.test(html), 'Canonical URL is missing or incorrect');
check('service worker registration present', /navigator\.serviceWorker\.register\(\s*'\/sw\.js(?:\?v=[^']+)?'/.test(html), 'Missing service worker registration');
check('service worker updateViaCache none', /updateViaCache:\s*'none'/.test(html), 'Service worker should bypass HTTP cache on update checks');
check('performance tier detection present', /navigator\.hardwareConcurrency|navigator\.deviceMemory/.test(html), 'Expected perf tier detection for mobile/device capability');
check('hero section present', /<section id="hero">/.test(html), 'Missing hero section');
check('proof section present', /<section id="proof"/.test(html), 'Missing proof section');
check('contact section present', /<section id="contact">/.test(html), 'Missing contact section');
check('WhatsApp CTA present', /https:\/\/wa\.me\/918320065658/.test(html), 'Missing WhatsApp CTA');
check('Cal.com CTA present', /https:\/\/cal\.com\/meetdeshani/.test(html), 'Missing Cal.com CTA');
check('Business address present', /South City 2, Sec 50, Gurugram/i.test(html), 'Homepage should expose the Gurugram address');
check('Maps link present', /https:\/\/maps\.app\.goo\.gl\/GozMfyCHnXWkMrWA7/.test(html), 'Homepage should expose the Google Maps location link');
check('LocalBusiness schema present', /"LocalBusiness"/.test(html), 'Homepage should include LocalBusiness schema');
check('inline calendar iframe lazy-loads', /<iframe[\s\S]*?loading="lazy"/.test(html), 'Calendar iframe should lazy-load');
check('mobile-first stylesheet linked', /<link rel="stylesheet" href="\/main\.css\?v=/.test(html), 'Missing main stylesheet link');

check('service worker precaches index', /['"]\/index\.html['"]/.test(sw), 'sw.js should precache /index.html');
check('service worker precaches CSS', /['"]\/main\.css(?:\?v=[^'"]+)?['"]/.test(sw), 'sw.js should precache /main.css');
check('service worker handles fetch events', /self\.addEventListener\('fetch'/.test(sw), 'sw.js is missing fetch handler');

const localRefs = collectLocalReferences(html);
for (const ref of localRefs) {
  const resolved = resolvePublicPath(ref);
  if (!resolved) continue;
  check(`local ref resolves: ${ref}`, fs.existsSync(resolved), `${ref} does not resolve to a file under public/`);
}

if (!/id="btn-read-testimony"/.test(html)) {
  warn('testimony CTA missing', 'The site no longer exposes the current testimony overlay trigger');
}

if (!/<meta name="description"/i.test(html)) {
  warn('meta description missing', 'Search snippets and sharing quality may suffer');
}

const llms = readFile('public/llms.txt');
check('LLMS address present', /South City 2, Sec 50, Gurugram/i.test(llms), 'llms.txt should contain the full business address');
check('LLMS map link present', /https:\/\/maps\.app\.goo\.gl\/GozMfyCHnXWkMrWA7/.test(llms), 'llms.txt should contain the map link');

for (const relPath of [
  'public/private-ai/index.html',
  'public/ai-automation/index.html',
  'public/platform-engineering/index.html',
  'public/geo-ai/index.html',
  'public/case-studies/index.html',
  'public/insights/index.html',
  'public/web-ai-experiences/index.html',
]) {
  const page = readFile(relPath);
  check(`support page address present: ${relPath}`, /South City 2, Sec 50, Gurugram/i.test(page), `${relPath} should reinforce the local business address`);
  check(`support page map link present: ${relPath}`, /https:\/\/maps\.app\.goo\.gl\/GozMfyCHnXWkMrWA7/.test(page), `${relPath} should include the map link`);
}

console.log('');
console.log(`Summary: ${passed} passed, ${warnings.length} warnings, ${failures.length} failed`);

if (failures.length) {
  process.exitCode = 1;
}
