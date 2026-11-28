#!/usr/bin/env node
// GameHub tekshiruvi. Ishlatish:
//   node tools/check.js            -> tuzilma va sintaksis tekshiruvi (tez, tarmoqsiz)
//   node tools/check.js --links    -> bundan tashqari har bir o'yin havolasini tekshiradi
const fs = require("fs");
const vm = require("vm");
const path = require("path");

const file = path.join(__dirname, "..", "index.html");
const html = fs.readFileSync(file, "utf8");
const errors = [];
const warnings = [];

// 1) Sahifadagi JavaScript sintaksisi
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
scripts.forEach((code, i) => {
  try {
    new vm.Script(code, { filename: `index.html#script${i + 1}` });
  } catch (e) {
    errors.push(`Sintaksis xatosi (script ${i + 1}): ${e.message}`);
  }
});

// 2) GAMES_DB ni ajratib olish
const start = html.indexOf("const GAMES_DB = {");
const end = html.indexOf("\n    };", start);
if (start === -1 || end === -1) {
  errors.push("GAMES_DB topilmadi");
  report();
}
let games = {};
try {
  games = vm.runInNewContext("(" + html.slice(start + "const GAMES_DB = ".length, end + 6) + ")");
} catch (e) {
  errors.push("GAMES_DB o'qib bo'lmadi: " + e.message);
  report();
}

const ids = new Set();
for (const [key, g] of Object.entries(games)) {
  const where = `GAMES_DB.${key}`;
  if (g.id !== key) errors.push(`${where}: id ("${g.id}") kalit bilan bir xil emas`);
  if (ids.has(g.id)) errors.push(`${where}: id takrorlangan`);
  ids.add(g.id);
  for (const f of ["title", "cat", "tag", "glow", "grad"]) {
    if (!g[f]) errors.push(`${where}: "${f}" yo'q`);
  }
  if (!["racing", "action", "sport"].includes(g.cat)) errors.push(`${where}: noma'lum cat "${g.cat}"`);
  if (g.tag) {
    for (const l of ["ru", "uz", "en"]) if (!g.tag[l]) errors.push(`${where}: tag.${l} yo'q`);
  }
  if (g.url) {
    if (!/^https:\/\//.test(g.url)) errors.push(`${where}: url https bilan boshlanishi kerak`);
  } else {
    warnings.push(`${where}: url yo'q (kartada "Play" bosilganda hech narsa bo'lmaydi)`);
  }
  if (g.img && !/^https:\/\//.test(g.img) && !fs.existsSync(path.join(__dirname, "..", g.img))) {
    errors.push(`${where}: img topilmadi`);
  }
}

// 3) WELCOME_GAMES / HUB_GAMES faqat mavjud kalitlarga murojaat qilsin
for (const m of html.matchAll(/GAMES_DB\.(\w+)/g)) {
  if (!(m[1] in games)) errors.push(`GAMES_DB.${m[1]} ishlatilgan, lekin e'lon qilinmagan`);
}

// 4) Havolalar (ixtiyoriy)
async function checkLinks() {
  for (const [key, g] of Object.entries(games)) {
    if (!g.url) continue;
    try {
      const ctl = new AbortController();
      const t = setTimeout(() => ctl.abort(), 15000);
      const res = await fetch(g.url, { method: "GET", redirect: "follow", signal: ctl.signal });
      clearTimeout(t);
      if (res.status >= 400) errors.push(`${key}: ${g.url} -> HTTP ${res.status}`);
      const xfo = (res.headers.get("x-frame-options") || "").toLowerCase();
      const csp = (res.headers.get("content-security-policy") || "").toLowerCase();
      const blocksFrame = xfo.includes("deny") || xfo.includes("sameorigin") || /frame-ancestors\s+('none'|'self')/.test(csp);
      if (blocksFrame && !g.external) {
        errors.push(`${key}: sayt iframe'ni taqiqlaydi, o'yinga external: true qo'shing`);
      }
    } catch (e) {
      errors.push(`${key}: ${g.url} ochilmadi (${e.name === "AbortError" ? "vaqt tugadi" : e.message})`);
    }
  }
}

function report() {
  warnings.forEach((w) => console.log("OGOHLANTIRISH:", w));
  errors.forEach((e) => console.error("XATO:", e));
  console.log(errors.length ? `\n${errors.length} ta xato` : "\nHammasi joyida");
  process.exit(errors.length ? 1 : 0);
}

(async () => {
  if (process.argv.includes("--links")) await checkLinks();
  report();
})();
