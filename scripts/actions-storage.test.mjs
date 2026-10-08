import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cleanupPlan, graceMs, GitHubStorage } from './actions-storage.mjs';

const now = Date.parse('2026-10-09T12:00:00Z');
const artifact = (id, name = 'android-native-symbols') => ({ id, name, size_in_bytes: 40,
  expired: false, workflow_run: { id, head_sha: 'a'.repeat(40) } });
const run = (id, overrides = {}) => ({ id, status: 'completed',
  path: '.github/workflows/android-sdk.yml', updated_at: new Date(now - graceMs).toISOString(), ...overrides });

test('only completed SDK workflow files older than 24 hours enter the archive plan', () => {
  const files = Array.from({ length: 10 }, (_, i) => artifact(i + 1));
  files[1].name = 'ios-sdk';
  files[7].name = 'unmanaged';
  files[8].expired = true;
  const runs = new Map(files.map(a => [a.id, run(a.id)]));
  runs.set(2, run(2, { path: '.github/workflows/ios-sdk.yml@main' }));
  runs.set(3, run(3, { status: 'in_progress' }));
  runs.set(4, run(4, { status: 'queued' }));
  runs.set(5, run(5, { updated_at: new Date(now - graceMs + 1).toISOString() }));
  runs.set(6, run(6, { path: '.github/workflows/unrelated.yml' }));
  runs.delete(7);
  runs.set(10, run(10, { updated_at: 'invalid' }));
  const plan = cleanupPlan(files, runs, now);
  assert.deepEqual(plan.remove.map(a => a.id), [1, 2]);
  assert.deepEqual(plan.keep.map(a => a.id), [3, 4, 5, 6, 7, 8, 10]);
});

function fixture({ corrupt = false, failUpload = false, failReceipt = false, rerun = false, existing = false, publicArchive = false, extraArtifact = false, failFirstUpload = false } = {}) {
  const files = [artifact(1), artifact(2, extraArtifact ? 'android-maven' : 'unmanaged')];
  const calls = [];
  const assets = new Map();
  const original = Buffer.from('original exact SDK ZIP bytes');
  if (existing) assets.set('1-android-native-symbols.zip', original);
  let reads = 0;
  const info = name => ({ id: name, name, size: assets.get(name).length, browser_download_url: `https://example.invalid/${name}` });
  const client = new GitHubStorage({ repository: 'test/sdk', token: 'test-only', request: async (url, options) => {
    const parsed = new URL(url);
    const route = decodeURIComponent(parsed.pathname.replace('/repos/test/sdk', ''));
    calls.push({ route, method: options.method });
    assert.equal(options.headers.authorization, 'Bearer test-only');
    if (route === '') return Response.json({ private: !publicArchive });
    if (route === '/actions/artifacts') return Response.json({ artifacts: files });
    if (route === '/actions/runs/2') return Response.json(run(2));
    if (route === '/actions/runs/1') {
      reads++;
      return Response.json(run(1, rerun && reads >= 3 ? { status: 'in_progress' } : {}));
    }
    if (route.startsWith('/releases/tags/')) return existing ? Response.json({ id: 5, upload_url: 'https://api.github.com/upload{?name,label}' }) : Response.json({}, { status: 404 });
    if (route === '/releases') {
      const body = JSON.parse(options.body);
      assert.match(body.tag_name, /^ci-sdk-artifacts\/sdk\/run-[12]$/);
      assert.equal(body.make_latest, 'false');
      assert.equal(body.target_commitish, undefined);
      return Response.json({ id: 5, upload_url: 'https://api.github.com/upload{?name,label}' });
    }
    if (route === '/releases/5/assets') return Response.json([...assets.keys()].map(info));
    if (/^\/actions\/artifacts\/[12]\/zip$/.test(route)) {
      assert.equal(options.headers.accept, 'application/vnd.github+json');
      return new Response(original);
    }
    if (route === '/upload') {
      const name = parsed.searchParams.get('name');
      if (failUpload || (failFirstUpload && name.startsWith('1-')) || (failReceipt && name.endsWith('.json'))) return new Response('unavailable', { status: 503 });
      assets.set(name, options.body);
      return Response.json(info(name));
    }
    if (route.startsWith('/releases/assets/')) {
      const name = route.slice('/releases/assets/'.length);
      return new Response(corrupt ? Buffer.alloc(assets.get(name).length, 'x') : assets.get(name));
    }
    if (/^\/actions\/artifacts\/[12]$/.test(route) && options.method === 'DELETE') {
      files.splice(files.findIndex(a => a.id === Number(route.split('/').at(-1))), 1);
      return new Response(null, { status: 204 });
    }
    throw new Error(`Unexpected ${options.method} ${url}`);
  } });
  return { client, files, calls, assets, original };
}

test('dry run never writes or deletes', async () => {
  const f = fixture();
  const report = await f.client.clean({ now, log() {} });
  assert.equal(report.archive_count, 1);
  assert.equal(report.deleted_count, 0);
  assert.ok(f.calls.every(c => c.method === 'GET'));
});

for (const existing of [false, true]) test(`delete only after ZIP and receipt verification, existing=${existing}`, async () => {
  const f = fixture({ existing });
  const report = await f.client.clean({ apply: true, now, log() {} });
  assert.equal(report.deleted_count, 1);
  const deletion = f.calls.findIndex(c => c.method === 'DELETE');
  const checks = f.calls.map((c, i) => c.route.startsWith('/releases/assets/') ? i : -1).filter(i => i >= 0);
  assert.equal(checks.length, 2);
  assert.ok(checks.every(i => i < deletion));
  const receipt = JSON.parse(f.assets.get('1-android-native-symbols.zip.json'));
  assert.equal(receipt.artifact.workflow_run.head_sha, 'a'.repeat(40));
  assert.equal(receipt.archive.sha256.length, 64);
  assert.deepEqual(f.assets.get('1-android-native-symbols.zip'), f.original);
  assert.deepEqual(f.files.map(a => a.id), [2]);
});

for (const options of [{ corrupt: true }, { failUpload: true }, { failReceipt: true }, { existing: true, corrupt: true }]) {
  test(`archive failure preserves original ${JSON.stringify(options)}`, async () => {
    const f = fixture(options);
    await assert.rejects(f.client.clean({ apply: true, now, log() {} }), /1 artifacts retained/);
    assert.ok(f.calls.every(c => c.method !== 'DELETE'));
    assert.equal(f.files.length, 2);
  });
}

test('rerun after archive keeps the artifact', async () => {
  const f = fixture({ rerun: true });
  await f.client.clean({ apply: true, now, log() {} });
  assert.ok(f.calls.every(c => c.method !== 'DELETE'));
  assert.equal(f.files.length, 2);
});

test('pagination includes artifacts after the first 100', async () => {
  let requests = 0;
  const client = new GitHubStorage({ repository: 'test/sdk', token: 'test-only', request: async url => {
    requests++;
    const count = new URL(url).searchParams.get('page') === '1' ? 100 : 1;
    return Response.json({ artifacts: Array.from({ length: count }, (_, i) => artifact(i + 1, 'unmanaged')) });
  } });
  const report = await client.clean({ now, log() {} });
  assert.equal(report.keep_count, 101);
  assert.equal(requests, 2);
});

test('public archive repository is rejected before any write or deletion', async () => {
  const f = fixture({ publicArchive: true });
  await assert.rejects(f.client.clean({ apply: true, now, log() {} }), /must be private/);
  assert.ok(f.calls.every(c => c.method === 'GET'));
  assert.equal(f.files.length, 2);
});

test('one failed archive does not block cleanup of another artifact', async () => {
  const f = fixture({ extraArtifact: true, failFirstUpload: true });
  await assert.rejects(f.client.clean({ apply: true, now, log() {} }), /1 artifacts retained/);
  assert.deepEqual(f.files.map(a => a.id), [1]);
  assert.ok(f.assets.has('2-android-maven.zip.json'));
});

test('source and private archive APIs use separate credentials', async () => {
  const client = new GitHubStorage({ repository: 'test/sdk', token: 'source-only',
    archiveRepository: 'test/private', archiveToken: 'archive-only', request: async (url, options) => {
      if (url === 'https://api.github.com/repos/test/private') {
        assert.equal(options.headers.authorization, 'Bearer archive-only');
        return Response.json({ private: true });
      }
      assert.ok(url.startsWith('https://api.github.com/repos/test/sdk/actions/artifacts?'));
      assert.equal(options.headers.authorization, 'Bearer source-only');
      return Response.json({ artifacts: [] });
    } });
  const report = await client.clean({ apply: true, now, log() {} });
  assert.equal(report.deleted_count, 0);
});
