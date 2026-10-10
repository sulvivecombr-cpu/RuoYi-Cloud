// White-label the admin console (RuoYi-Cloud-Vue3): Brazilian Portuguese, no upstream credits.
//
// The console is a separate project cloned into ./ruoyi-ui; its copy and branding are
// hardcoded Chinese/upstream. This runs at UI startup, after the clone, and is idempotent, so
// the result survives a fresh checkout. It does four things:
//
//   1. Element Plus locale: src/main.js hardcodes zh-cn -> pt-br (date pickers, month/week
//      names, pagination, tables, dialogs, uploads).
//   2. Copy: every Chinese text unit found in the source is replaced with the Portuguese
//      translation from ./ui-ptbr.copy.mjs (longest key first).
//   3. Credits: drops the navbar's "source code" / "documentation" links to the vendor's
//      repository and docs site, empties the copyright footer, removes those link components
//      and the vendor's donation image, and neutralises the package metadata.
//   4. Home page: src/views/index.vue is the upstream project's promotional/credits page, so
//      it is replaced with ./dashboard.vue.
//
// Usage: node /usr/local/bin/ui-ptbr.mjs [ui-dir]      (default: current directory)

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import copy from './ui-ptbr.copy.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(process.argv[2] || process.cwd())

if (!fs.existsSync(path.join(root, 'src', 'main.js'))) {
  console.log('ui-ptbr: src/main.js not found - is the UI cloned yet? nothing to do')
  process.exit(0)
}

const hits = { files: 0, strings: 0, credits: 0, home: false }

// Longest key first, so '的文件' wins over '的' plus '文件'.
const keys = Object.keys(copy).sort((a, b) => b.length - a.length)

// Keys that translate to nothing are suffixes and particles ('的', '的数据项', '个'). Deleting one
// from the middle of a Chinese run would silently eat a phrase that simply is not in the map yet,
// so such a key is applied only where the run is already delimited by non-Chinese characters.
// Longest key first throughout, so '的文件' is handled before '的' plus '文件', and a spaced label
// ('注 册') before the single characters inside it.
const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
const rules = keys.map((key) =>
  copy[key] === ''
    ? { re: new RegExp(`(?<!\\p{Script=Han})${escapeRe(key)}(?!\\p{Script=Han})`, 'gu') }
    : { key, value: copy[key] },
)

function translate(file) {
  const before = fs.readFileSync(file, 'utf8')
  let after = before
  for (const rule of rules) {
    if (rule.re) after = after.replace(rule.re, '')
    else if (after.includes(rule.key)) after = after.split(rule.key).join(rule.value)
  }
  if (after !== before) {
    fs.writeFileSync(file, after)
    hits.files++
    hits.strings += keys.filter((k) => before.includes(k)).length
  }
}

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name)
    if (entry.isDirectory()) walk(p)
    else if (/\.(vue|js)$/.test(entry.name)) translate(p)
  }
}

// --- 1. Element Plus locale ---------------------------------------------------------
const mainJs = path.join(root, 'src', 'main.js')
const mainSrc = fs.readFileSync(mainJs, 'utf8')
if (mainSrc.includes('element-plus/es/locale/lang/zh-cn')) {
  fs.writeFileSync(mainJs, mainSrc.replace(/element-plus\/es\/locale\/lang\/zh-cn/g, 'element-plus/es/locale/lang/pt-br'))
  console.log('ui-ptbr: Element Plus locale -> pt-br')
}

// --- 3. Credits (before the copy pass, which matches on the Chinese markers) ---------
function dropTooltipBlock(file, marker) {
  if (!fs.existsSync(file)) return false
  const lines = fs.readFileSync(file, 'utf8').split('\n')
  const start = lines.findIndex((l) => l.includes(`content="${marker}"`))
  if (start === -1) return false
  let end = start
  while (end < lines.length && !lines[end].includes('</el-tooltip>')) end++
  if (end >= lines.length) return false
  lines.splice(start, end - start + 1)
  fs.writeFileSync(file, lines.join('\n'))
  hits.credits++
  return true
}

const navbar = path.join(root, 'src', 'layout', 'components', 'Navbar.vue')
dropTooltipBlock(navbar, '源码地址') // links to the vendor's repository
dropTooltipBlock(navbar, '文档地址') // links to the vendor's documentation site
if (fs.existsSync(navbar)) {
  // Line-based on purpose: the UI project's files end their lines with CRLF, which a `$`-anchored
  // regex misses.
  const nav = fs.readFileSync(navbar, 'utf8')
    .split('\n')
    .filter((l) => !l.includes('components/RuoYi/Git') && !l.includes('components/RuoYi/Doc'))
    .join('\n')
  fs.writeFileSync(navbar, nav)
}

// The link components themselves (they only carry the vendor's URLs).
fs.rmSync(path.join(root, 'src', 'components', 'RuoYi'), { recursive: true, force: true })

// Copyright footer on the login page.
const settingsJs = path.join(root, 'src', 'settings.js')
if (fs.existsSync(settingsJs)) {
  const s = fs.readFileSync(settingsJs, 'utf8')
  const cleaned = s.replace(/footerContent:\s*'[^']*'/, "footerContent: ''")
  if (cleaned !== s) {
    fs.writeFileSync(settingsJs, cleaned)
    hits.credits++
  }
}

// Package metadata (author, description, repository).
const pkgFile = path.join(root, 'package.json')
if (fs.existsSync(pkgFile)) {
  const pkg = fs.readFileSync(pkgFile, 'utf8')
  const cleaned = pkg
    .replace(/("description"\s*:\s*)"[^"]*"/, '$1"Painel administrativo"')
    .replace(/("author"\s*:\s*)"[^"]*"/, '$1""')
    .replace(/("url"\s*:\s*)"[^"]*"/, '$1""')
  if (cleaned !== pkg) {
    fs.writeFileSync(pkgFile, cleaned)
    hits.credits++
  }
}

// --- 2. Copy ------------------------------------------------------------------------
translate(path.join(root, 'index.html'))
walk(path.join(root, 'src'))

// --- 4. Home page -------------------------------------------------------------------
const tpl = path.join(here, 'dashboard.vue')
const home = path.join(root, 'src', 'views', 'index.vue')
if (fs.existsSync(tpl)) {
  fs.writeFileSync(home, fs.readFileSync(tpl, 'utf8'))
  hits.home = true
}

// The vendor's donation QR image is only used by the replaced home page.
const pay = path.join(root, 'src', 'assets', 'images', 'pay.png')
if (fs.existsSync(pay)) {
  const stillUsed = []
  ;(function scan(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, entry.name)
      if (entry.isDirectory()) scan(p)
      else if (/\.(vue|js|html)$/.test(entry.name) && fs.readFileSync(p, 'utf8').includes('pay.png')) stillUsed.push(p)
    }
  })(path.join(root, 'src'))
  if (stillUsed.length === 0) {
    fs.rmSync(pay)
    hits.credits++
  }
}

const summary = []
if (hits.strings) summary.push(`${hits.strings} strings in ${hits.files} files`)
if (hits.credits) summary.push(`${hits.credits} credits removed`)
if (hits.home) summary.push('home page replaced')
console.log(summary.length ? `ui-ptbr: Brazilian Portuguese console (${summary.join(', ')})` : 'ui-ptbr: console already localized - nothing to do')
