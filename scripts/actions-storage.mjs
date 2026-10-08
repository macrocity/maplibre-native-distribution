#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';

const managedName = /^(ios-sdk|android-maven|android-native-symbols|android-(symbols-)?(arm64-v8a|x86_64|armeabi-v7a|x86))$/;
const workflows = new Set(['.github/workflows/android-sdk.yml', '.github/workflows/ios-sdk.yml']);
export const graceMs = 24 * 60 * 60 * 1000;

export function cleanupPlan(artifacts, runs, now = Date.now()) {
  const keep = [], remove = [];
  for (const artifact of artifacts) {
    if (artifact.expired) continue;
    const run = runs.get(artifact.workflow_run?.id);
    const updated = Date.parse(run?.updated_at);
    const eligible = managedName.test(artifact.name) && workflows.has(run?.path?.split('@')[0]) &&
      run.status === 'completed' && Number.isFinite(updated) && now - updated >= graceMs;
    (eligible ? remove : keep).push(artifact);
  }
  return { keep, remove };
}

export class GitHubStorage {
  constructor({ repository, token, archiveRepository, archiveToken, apiUrl = 'https://api.github.com', request = fetch }) {
    if (!repository || !token) throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required');
    this.repository = repository;
    this.base = `${apiUrl}/repos/${repository}`;
    this.token = token;
    this.request = request;
    this.releases = new Map();
    this.archiveStorage = archiveRepository
      ? new GitHubStorage({ repository: archiveRepository, token: archiveToken, apiUrl, request }) : this;
  }

  async api(method, route, body, { binary = false, missing = false, accept } = {}) {
    const response = await this.request(route.startsWith('http') ? route : `${this.base}${route}`, {
      method,
      headers: {
        authorization: `Bearer ${this.token}`,
        accept: accept ?? (binary ? 'application/octet-stream' : 'application/vnd.github+json'),
        ...(body ? { 'content-type': Buffer.isBuffer(body) ? 'application/octet-stream' : 'application/json' } : {}),
        'X-GitHub-Api-Version': '2022-11-28',
      },
      ...(body ? { body: Buffer.isBuffer(body) ? body : JSON.stringify(body) } : {}),
      signal: AbortSignal.timeout(120000),
    });
    if (missing && response.status === 404) return null;
    if (!response.ok) throw new Error(`GitHub ${method} ${route}: HTTP ${response.status}: ${await response.text()}`);
    if (response.status === 204) return null;
    return binary ? Buffer.from(await response.arrayBuffer()) : response.json();
  }

  async pages(route, field) {
    const all = [];
    for (let page = 1; ; page++) {
      const result = await this.api('GET', `${route}${route.includes('?') ? '&' : '?'}per_page=100&page=${page}`);
      const items = field ? result[field] : result;
      all.push(...items);
      if (items.length < 100) return all;
    }
  }

  async release(tag) {
    let release = this.releases.get(tag);
    if (!release) {
      release = await this.api('GET', `/releases/tags/${encodeURIComponent(tag)}`, null, { missing: true });
      if (!release) {
        try {
          release = await this.api('POST', '/releases', {
            tag_name: tag,
            // Default-branch tags work with GITHUB_TOKEN; historical commits with different
            // workflow files require a separate workflow-write token. CI tags index files.
            name: tag,
            body: 'Original SDK workflow artifacts. Each ZIP has a verified SHA-256 receipt. See README.md for recovery.',
            prerelease: true,
            make_latest: 'false',
          });
        } catch (error) {
          // Parallel iOS and Android jobs can create the same archive group together.
          release = await this.api('GET', `/releases/tags/${encodeURIComponent(tag)}`, null, { missing: true });
          if (!release) throw error;
        }
      }
      release.assets = await this.pages(`/releases/${release.id}/assets`);
      this.releases.set(tag, release);
    }
    return release;
  }

  async publishFile(tag, name, original) {
    if (!original.length || original.length >= 2 * 1024 ** 3) throw new Error('Release files must be nonempty and below 2 GiB');
    const release = await this.release(tag);
    let asset = release.assets.find((candidate) => candidate.name === name);
    if (!asset) {
      const upload = `${release.upload_url.replace(/\{.*$/, '')}?name=${encodeURIComponent(name)}`;
      try {
        asset = await this.api('POST', upload, original);
      } catch (error) {
        asset = (await this.pages(`/releases/${release.id}/assets`)).find((candidate) => candidate.name === name);
        if (!asset) throw error;
      }
      release.assets.push(asset);
    }
    if (asset.size !== original.length) throw new Error(`Release file size differs: ${name}`);
    const archived = await this.api('GET', `/releases/assets/${asset.id}`, null, { binary: true });
    const digest = (bytes) => createHash('sha256').update(bytes).digest('hex');
    if (digest(original) !== digest(archived)) throw new Error(`Release file checksum differs: ${name}`);
    return { url: asset.browser_download_url, sha256: digest(original), size: original.length };
  }

  async archive(artifact) {
    const tag = `ci-sdk-artifacts/${this.repository.split("/")[1]}/run-${artifact.workflow_run.id}`;
    const name = `${artifact.id}-${artifact.name}.zip`;
    const original = await this.api('GET', `/actions/artifacts/${artifact.id}/zip`, null,
      { binary: true, accept: 'application/vnd.github+json' });
    const copy = await this.archiveStorage.publishFile(tag, name, original);
    const receipt = Buffer.from(JSON.stringify({ schema: 1, artifact, archive: copy }, null, 2) + '\n');
    await this.archiveStorage.publishFile(tag, `${name}.json`, receipt);
    return copy;
  }

  async clean({ apply = false, log = console.log, now = Date.now() } = {}) {
    if (apply) {
      const archiveRepo = await this.archiveStorage.api('GET', '');
      if (archiveRepo.private !== true) throw new Error('Archive repository must be private');
    }
    const artifacts = await this.pages('/actions/artifacts', 'artifacts');
    const runs = new Map();
    for (const artifact of artifacts.filter(a => !a.expired && managedName.test(a.name))) {
      const id = artifact.workflow_run?.id;
      if (id && !runs.has(id)) runs.set(id, await this.api('GET', `/actions/runs/${id}`));
    }
    const plan = cleanupPlan(artifacts, runs, now);
    const size = items => items.reduce((sum, a) => sum + a.size_in_bytes, 0);
    const report = { apply, keep_count: plan.keep.length, archive_count: plan.remove.length,
      before_bytes: size([...plan.keep, ...plan.remove]), planned_remaining_bytes: size(plan.keep),
      deleted_count: 0, deleted_bytes: 0, failed_count: 0 };
    log(JSON.stringify(report));
    if (apply) {
      for (const artifact of plan.remove) {
        try {
          // A completed run can be restarted while an archive is being uploaded.
          let run = await this.api('GET', `/actions/runs/${artifact.workflow_run.id}`);
          if (!cleanupPlan([artifact], new Map([[run.id, run]]), now).remove.length) {
            log(`Protected ${artifact.name}: workflow ${run.id} changed`);
            continue;
          }
          const copy = await this.archive(artifact);
          log(`Verified ${artifact.name}: ${copy.url} sha256=${copy.sha256}`);
          run = await this.api('GET', `/actions/runs/${artifact.workflow_run.id}`);
          if (!cleanupPlan([artifact], new Map([[run.id, run]]), now).remove.length) {
            log(`Protected ${artifact.name}: workflow ${run.id} changed`);
            continue;
          }
          await this.api('DELETE', `/actions/artifacts/${artifact.id}`);
          report.deleted_count++;
          report.deleted_bytes += artifact.size_in_bytes;
          log(`Deleted ${artifact.id} ${artifact.name} (${artifact.size_in_bytes} bytes)`);
        } catch (error) {
          report.failed_count++;
          log(`Kept ${artifact.id} ${artifact.name}: ${error.message}`);
        }
      }
      log(JSON.stringify(report));
      if (report.failed_count) throw new Error(`${report.failed_count} artifacts retained after archive or delete failures`);
    }
    return report;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  if (args.length > 1 || args.some(arg => !['--apply', '--dry-run'].includes(arg))) {
    console.error('usage: actions-storage.mjs [--dry-run|--apply]');
    process.exit(2);
  }
  try {
    await new GitHubStorage({ repository: process.env.GITHUB_REPOSITORY,
      token: process.env.GITHUB_TOKEN || process.env.GH_TOKEN,
      archiveRepository: process.env.ARTIFACT_ARCHIVE_REPOSITORY,
      archiveToken: process.env.ARTIFACT_ARCHIVE_TOKEN,
      apiUrl: process.env.GITHUB_API_URL }).clean({ apply: args[0] === '--apply' });
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
