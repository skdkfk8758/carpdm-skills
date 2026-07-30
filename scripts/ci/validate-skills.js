#!/usr/bin/env node
/**
 * Validate skill directories (skills/<name>/SKILL.md).
 *
 * Checks (all errors — exit 1 on any violation):
 *   1. Every subdirectory of skills/ contains a non-empty SKILL.md.
 *   2. SKILL.md starts with YAML frontmatter (---).
 *   3. Frontmatter declares `name:` and its value equals the directory name.
 *      (craft-core resolves skills by hardcoded ~/.claude/skills/<name> paths,
 *      so a name/dir mismatch silently breaks the pipeline — see
 *      rules/project.md §1.)
 *   4. `name:` value is ASCII kebab-case ([a-z0-9-]). Korean or other
 *      non-ASCII identifiers break install/sync/invocation per the repo's
 *      authoring language policy (rules/project.md — "번역·한글화 금지").
 *   5. Frontmatter declares `description:` with non-empty content.
 *      Block scalars (`>-`, `|`) are ALLOWED — Claude Code loads them fine
 *      (measured: forge/hunt trigger correctly with `>-`). We only require
 *      that some description text exists.
 *
 * Zero dependencies (fs/path only). Run: node scripts/ci/validate-skills.js
 */

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const SKILLS_DIR = path.join(ROOT, 'skills');

function extractFrontmatter(content) {
  // Tolerate UTF-8 BOM and CRLF.
  const clean = content.replace(/^\uFEFF/, '');
  const match = clean.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if (!match) return null;
  return match[1].split(/\r?\n/);
}

function main() {
  if (!fs.existsSync(SKILLS_DIR)) {
    console.log('validate-skills: skills/ not found — nothing to validate.');
    return 0;
  }

  const dirs = fs
    .readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => e.name)
    .sort();

  const errors = [];

  for (const dir of dirs) {
    const skillPath = path.join(SKILLS_DIR, dir, 'SKILL.md');
    const rel = `skills/${dir}/SKILL.md`;

    if (!fs.existsSync(skillPath)) {
      errors.push(`${rel}: missing SKILL.md`);
      continue;
    }

    const content = fs.readFileSync(skillPath, 'utf8');
    if (content.trim().length === 0) {
      errors.push(`${rel}: SKILL.md is empty`);
      continue;
    }

    const fmLines = extractFrontmatter(content);
    if (!fmLines) {
      errors.push(`${rel}: missing YAML frontmatter`);
      continue;
    }

    // Top-level keys only (no indentation).
    const nameLine = fmLines.find(l => /^name:/.test(l));
    const descIndex = fmLines.findIndex(l => /^description:/.test(l));

    if (!nameLine) {
      errors.push(`${rel}: frontmatter missing 'name:'`);
    } else {
      const name = nameLine.replace(/^name:/, '').trim().replace(/^["']|["']$/g, '');
      if (name !== dir) {
        errors.push(`${rel}: name '${name}' != directory '${dir}' (craft-core path coupling breaks)`);
      }
      if (!/^[a-z0-9-]+$/.test(name)) {
        errors.push(`${rel}: name '${name}' must be ASCII kebab-case [a-z0-9-]`);
      }
    }

    if (descIndex === -1) {
      errors.push(`${rel}: frontmatter missing 'description:'`);
    } else {
      const inline = fmLines[descIndex].replace(/^description:/, '').trim();
      const isBlockScalar = /^[|>][+-]?$/.test(inline);
      if (isBlockScalar) {
        // Content must follow as indented lines.
        const hasBody = fmLines
          .slice(descIndex + 1)
          .some(l => /^\s+\S/.test(l));
        if (!hasBody) {
          errors.push(`${rel}: 'description:' block scalar has no content`);
        }
      } else if (inline.replace(/^["']|["']$/g, '').length === 0) {
        errors.push(`${rel}: 'description:' is empty`);
      }
    }
  }

  if (errors.length > 0) {
    console.error(`validate-skills: ${errors.length} violation(s) in ${dirs.length} skill(s):`);
    for (const e of errors) console.error(`  - ${e}`);
    return 1;
  }

  console.log(`validate-skills: OK — ${dirs.length} skills valid.`);
  return 0;
}

process.exit(main());
