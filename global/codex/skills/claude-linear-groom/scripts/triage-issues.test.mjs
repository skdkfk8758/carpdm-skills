// node --test scripts/triage-issues.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { isOpen, proseLength, enrichTier, needsGrouping, triage } from './triage-issues.mjs';

test('isOpen excludes Done/Canceled', () => {
  assert.equal(isOpen({ statusType: 'backlog' }), true);
  assert.equal(isOpen({ statusType: 'started' }), true);
  assert.equal(isOpen({ statusType: 'completed' }), false);
  assert.equal(isOpen({ statusType: 'canceled' }), false);
});

test('proseLength: image-only and embeds count as ~zero prose', () => {
  assert.equal(proseLength('![](https://uploads.linear.app/a/b?signature=x)'), 0);
  assert.equal(proseLength(''), 0);
  assert.ok(proseLength('## 배경\n실제 본문이 충분히 길게 있는 경우입니다 여기에') > 20);
});

test('proseLength: truncation marker means long body (Infinity)', () => {
  assert.equal(proseLength('## 배경 ... (truncated, use `get_issue` for full description)'), Infinity);
});

test('enrichTier tiers', () => {
  assert.equal(enrichTier({ description: '' }), 'empty');
  assert.equal(enrichTier({ description: '![](https://x/y?signature=z)' }), 'empty');
  assert.equal(
    enrichTier({
      description:
        'sso_audience 컬럼 분리(ADR-038 amend, PR #299) 후속 작업입니다. 배포 후 마이그레이션 apply, bus consumer backfill 수동 실행, consumer origin(ADMap FE 도메인) 등록까지 남아 있습니다.',
    }),
    'shallow',
  );
  assert.equal(enrichTier({ description: '## 배경\n' + 'a'.repeat(250) }), null);
  assert.equal(enrichTier({ description: 'x ... (truncated, use `get_issue`)' }), null);
});

test('needsGrouping is project-attachment', () => {
  assert.equal(needsGrouping({ project: null }), true);
  assert.equal(needsGrouping({ projectId: 'abc' }), false);
  assert.equal(needsGrouping({ project: '지도·분석' }), false);
});

test('triage buckets an issue into both gaps when it is orphan AND empty', () => {
  const r = triage([
    { id: 'A-1', title: 'orphan empty', description: '![](u)', statusType: 'backlog' },
    { id: 'A-2', title: 'done', description: '', statusType: 'completed' },
    { id: 'A-3', title: 'healthy', description: '## 배경\n' + 'b'.repeat(250), statusType: 'backlog', project: 'P' },
  ]);
  assert.deepEqual(r.groupingGaps.map((x) => x.id), ['A-1']);
  assert.deepEqual(r.enrichmentGaps.map((x) => x.id), ['A-1']);
  assert.deepEqual(r.healthy.map((x) => x.id), ['A-3']);
  assert.deepEqual(r.skippedClosed.map((x) => x.id), ['A-2']);
});
