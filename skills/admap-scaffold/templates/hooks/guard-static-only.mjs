#!/usr/bin/env node
// PreToolUse guard — keeps this folder a static, build-step-free HTML project.
// Blocks framework/bundler/package-manager entry points and edits to files that
// must not exist (framework configs, component sources) or must not change (style.js).
// Exit 2 = block with stderr message shown to the model. Anything unexpected → allow.

let raw = '';
for await (const chunk of process.stdin) raw += chunk;

let input;
try {
  input = JSON.parse(raw);
} catch {
  process.exit(0);
}

function block(reason) {
  console.error(
    `[guard-static-only] 차단: ${reason}\n` +
      '이 폴더는 admap-scaffold 산출 정적 HTML 프로젝트다 — 프레임워크·번들러·패키지 도입 금지, ' +
      'style.js 편집 금지. 규칙: CLAUDE.md / OVERLAY-RULES.md',
  );
  process.exit(2);
}

const tool = input.tool_name ?? '';

if (tool === 'Bash') {
  const cmd = String(input.tool_input?.command ?? '');
  const patterns = [
    [/\b(create-next-app|create-react-app|create-vite|create-remix|create-astro|create-svelte|nuxi)\b/, '프레임워크 스캐폴더 실행'],
    [/\b(npm|pnpm|yarn|bun)\s+(create|init)\b/, '패키지 프로젝트 초기화'],
    [/\b(npm|pnpm|bun)\s+(install|i|ci|add)\b/, '패키지 설치'],
    [/\byarn\s+(add|install)\b/, '패키지 설치'],
    [/\bnpx\s+(vite|next|nuxt|astro|webpack|parcel|rollup|esbuild|tsc)\b/, '번들러/컴파일러 실행'],
    [/(^|&&|\|\||;)\s*(vite|next|nuxt|astro|webpack|tsc)\s/, '번들러/컴파일러 실행'],
  ];
  for (const [re, why] of patterns) {
    if (re.test(cmd)) block(`${why} (${cmd.slice(0, 120)})`);
  }
  process.exit(0);
}

if (tool === 'Write' || tool === 'Edit' || tool === 'MultiEdit' || tool === 'NotebookEdit') {
  const fp = String(input.tool_input?.file_path ?? input.tool_input?.notebook_path ?? '');
  if (!fp) process.exit(0);
  const base = fp.split('/').pop();

  if (base === 'style.js') block('style.js 편집 — ADMap 스냅샷은 스캐폴드 재실행으로만 갱신');
  if (/^(package(-lock)?\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb|tsconfig\.json)$/.test(base))
    block(`패키지/컴파일 설정 파일 생성 (${base})`);
  if (/^(vite|next|nuxt|astro|svelte|webpack|rollup|babel|postcss|tailwind)\.config\./.test(base))
    block(`프레임워크 설정 파일 생성 (${base})`);
  if (/\.(jsx|tsx|ts|mts|cts|vue|svelte)$/.test(base) && !/\.d\.ts$/.test(base))
    block(`컴파일 필요 소스 생성 (${base}) — 정적 폴더는 plain js/html/css 만`);
  if (fp.includes('/node_modules/')) block('node_modules 접근');
  process.exit(0);
}

process.exit(0);
