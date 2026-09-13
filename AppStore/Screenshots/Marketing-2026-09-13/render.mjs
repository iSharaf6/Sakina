// Deterministic export of native HTML marketing layouts with original app screenshots.
// No app UI, Arabic text, or numerical values are redrawn.
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';
const require=createRequire(import.meta.url);
const modulePath=process.env.PLAYWRIGHT_MODULE || '/Users/IslamSharaf_1/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright';
const {chromium}=require(modulePath);
const here=path.dirname(fileURLToPath(import.meta.url));
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH || '/Users/IslamSharaf_1/Library/Caches/ms-playwright/chromium_headless_shell-1234/chrome-headless-shell-mac-arm64/chrome-headless-shell'});
const page=await browser.newPage({viewport:{width:414,height:896},deviceScaleFactor:3});
const names=['01-daily-companion','02-quran','03-feelings','04-dhikr','05-prayer','06-widgets'];
try{
for(let id=1;id<=6;id++){
await page.goto(pathToFileURL(path.join(here,'poster.html')).href+'?id='+id);
await page.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(i=>i.decode().catch(()=>{})))});
const missing=await page.evaluate(()=>[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.getAttribute('src')));
if(missing.length)throw new Error(`Poster ${id}: missing images: ${missing.join(', ')}`);
await page.screenshot({path:path.join(here,'exports',names[id-1]+'.png'),type:'png',omitBackground:false});
console.log('Rendered '+names[id-1]+' at 1242 × 2688');
}
const review=await browser.newPage({viewport:{width:1200,height:900},deviceScaleFactor:1});
await review.goto(pathToFileURL(path.join(here,'index.html')).href);
await review.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].filter(i=>i.hasAttribute('src')).map(i=>i.decode()))});
await review.screenshot({path:path.join(here,'overview.png'),fullPage:true,type:'png'});
await review.getByRole('button',{name:'Review screenshot 1: Daily companion',exact:true}).click();
if(!await review.locator('#viewer').evaluate(el=>el.open))throw new Error('Review viewer did not open');
await review.getByRole('button',{name:'Next screenshot',exact:true}).click();
if(!await review.locator('#caption').textContent().then(t=>t.includes('2 / 6')))throw new Error('Gallery next did not advance');
await review.getByRole('button',{name:'Close',exact:true}).click();
console.log('Created overview and verified review gallery controls.');
}finally{await browser.close()}
