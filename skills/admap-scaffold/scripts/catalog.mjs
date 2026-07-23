#!/usr/bin/env node
// Fetch ADMap v1 persona-segment taxonomy + layer catalog, emit interview choices.
// Output shape: { mapId, segments: [{id,name,items:[{id,name,description,layerIds}]}],
//                 unassigned: [{id,name,displayName,category,geometryType}] }
// The catalog is fetched WITHOUT ?include=system on purpose: basemap layers must never
// be selectable, so they can never be switched off (REQ-F-004).

const BASE = process.env.ADMAP_API_BASE ?? 'https://map.adtype.work/api/v1';
const MAP_ID = process.env.ADMAP_MAP_ID ?? 'main';
const KEY = process.env.ADMAP_API_KEY;

if (!KEY) {
  console.error(
    'ADMAP_API_KEY 가 설정되지 않았습니다. 셸에서 `export ADMAP_API_KEY=admap_...` 후 다시 실행하세요.',
  );
  process.exit(1);
}

async function get(path) {
  let res;
  try {
    res = await fetch(`${BASE}${path}`, { headers: { 'X-API-Key': KEY } });
  } catch (err) {
    console.error(`GET ${path} 실패 — 네트워크 오류: ${err.message}`);
    process.exit(1);
  }
  if (!res.ok) {
    const hint =
      res.status === 401
        ? ' (ADMAP_API_KEY 가 무효하거나 만료됐습니다)'
        : res.status === 403
          ? ' (이 키에 허용되지 않은 브랜드/스코프입니다)'
          : '';
    console.error(`GET ${path} -> HTTP ${res.status}${hint}`);
    process.exit(1);
  }
  return res.json();
}

const [taxonomy, catalog] = await Promise.all([
  get(`/maps/${MAP_ID}/layer-taxonomy`),
  get(`/maps/${MAP_ID}/layers`),
]);

const segments = (taxonomy.segments ?? []).map((s) => ({
  id: s.id,
  name: s.name,
  items: (s.items ?? []).map((i) => ({
    id: i.id,
    name: i.name,
    description: i.description ?? null,
    layerIds: i.layerIds ?? [],
  })),
}));

const assigned = new Set(segments.flatMap((s) => s.items.flatMap((i) => i.layerIds)));

const unassigned = (catalog.layers ?? [])
  .filter((l) => !assigned.has(l.id))
  .map((l) => ({
    id: l.id,
    name: l.name,
    displayName: l.displayName ?? null,
    category: l.category ?? null,
    geometryType: l.geometryType ?? null,
  }));

console.log(
  JSON.stringify(
    {
      mapId: taxonomy.mapId ?? MAP_ID,
      segments,
      unassigned,
      counts: {
        segments: segments.length,
        catalogLayers: (catalog.layers ?? []).length,
        assigned: assigned.size,
        unassigned: unassigned.length,
      },
    },
    null,
    2,
  ),
);
