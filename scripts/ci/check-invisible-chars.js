#!/usr/bin/env node
/**
 * Scan tracked text files for dangerous invisible Unicode code points.
 *
 * This repo ships prompts (SKILL.md files) that get installed into
 * ~/.claude/skills/ and executed with user privileges. Invisible characters
 * are the canonical "ASCII smuggling" prompt-injection vector: an attacker
 * hides instructions in a PR that the human reviewer cannot see but the
 * LLM consumes (Unicode Tag block especially).
 *
 * Flagged (adapted from ECC's check-unicode-safety.js, credit affaan-m/ecc):
 *   U+200B..200D  zero-width space / non-joiner / joiner
 *   U+2060        word joiner
 *   U+FEFF        BOM / zero-width no-break space
 *   U+202A..202E  bidi embedding/override controls
 *   U+2066..2069  bidi isolate controls
 *   U+180E        Mongolian vowel separator (zero-width)
 *   U+115F,U+1160 Hangul choseong/jungseong fillers (zero-width)
 *   U+3164        Hangul filler (zero-width)
 *   U+2061..2064  invisible math operators
 *   U+E0000..E007F Unicode Tag block — deprecated, ASCII-smuggling vector
 *
 * Deliberately NOT flagged (differs from ECC):
 *   - Emoji — this repo uses emoji in skill docs as a presentation device
 *     (measured ~670 occurrences, all intentional).
 *   - U+FE00..FE0F variation selectors — legitimate emoji-presentation
 *     selectors (e.g. the FE0F in "⚠️"); flagging them is 100% false
 *     positive here.
 *   - U+E0100..E01EF ideographic variation selectors — same category.
 *
 * Scope: `git ls-files` output filtered to text extensions. Zero deps.
 * Run: node scripts/ci/check-invisible-chars.js
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..');

const TEXT_EXTENSIONS = new Set([
  '.md', '.txt', '.sh', '.bash', '.zsh',
  '.js', '.mjs', '.cjs', '.ts', '.py',
  '.json', '.yml', '.yaml', '.toml', '.html', '.css',
]);

function isDangerous(codePoint) {
  return (
    (codePoint >= 0x200b && codePoint <= 0x200d) ||
    codePoint === 0x2060 ||
    codePoint === 0xfeff ||
    (codePoint >= 0x202a && codePoint <= 0x202e) ||
    (codePoint >= 0x2066 && codePoint <= 0x2069) ||
    codePoint === 0x180e ||
    codePoint === 0x115f ||
    codePoint === 0x1160 ||
    codePoint === 0x3164 ||
    (codePoint >= 0x2061 && codePoint <= 0x2064) ||
    (codePoint >= 0xe0000 && codePoint <= 0xe007f)
  );
}

function lineAndColumn(text, index) {
  const before = text.slice(0, index);
  const line = before.split('\n').length;
  const column = index - before.lastIndexOf('\n');
  return { line, column };
}

function main() {
  const tracked = execFileSync('git', ['ls-files', '-z'], {
    cwd: ROOT,
    encoding: 'utf8',
    maxBuffer: 16 * 1024 * 1024,
  })
    .split('\0')
    .filter(Boolean)
    .filter(f => TEXT_EXTENSIONS.has(path.extname(f).toLowerCase()));

  const findings = [];

  for (const rel of tracked) {
    const abs = path.join(ROOT, rel);
    let text;
    try {
      text = fs.readFileSync(abs, 'utf8');
    } catch {
      continue; // deleted in working tree etc.
    }

    for (let i = 0; i < text.length; i++) {
      const cp = text.codePointAt(i);
      if (isDangerous(cp)) {
        const { line, column } = lineAndColumn(text, i);
        findings.push(`${rel}:${line}:${column} U+${cp.toString(16).toUpperCase().padStart(4, '0')}`);
      }
      if (cp > 0xffff) i++; // surrogate pair
    }
  }

  if (findings.length > 0) {
    console.error(`check-invisible-chars: ${findings.length} dangerous invisible character(s):`);
    for (const f of findings) console.error(`  - ${f}`);
    console.error('Remove them (they are invisible — inspect with a hex editor or `grep -P`).');
    return 1;
  }

  console.log(`check-invisible-chars: OK — ${tracked.length} files clean.`);
  return 0;
}

process.exit(main());
