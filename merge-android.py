"""Combine identical per-ABI publications, checking contents and refreshing Maven hashes."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import zipfile

architectures, output = map(Path, sys.argv[1:])
abis = ('arm64-v8a', 'x86_64', 'armeabi-v7a', 'x86')
repository = output / 'maven'
shutil.copytree(architectures / 'android-arm64-v8a', repository)
aars = list(repository.rglob('*.aar'))
assert len(aars) == 1
aar = aars[0]
entries = {}
common = None
for abi in abis:
    candidates = list((architectures / f'android-{abi}').rglob('*.aar'))
    assert len(candidates) == 1
    with zipfile.ZipFile(candidates[0]) as source:
        files = {name: source.read(name) for name in source.namelist() if not name.endswith('/')}
    portable = {name: data for name, data in files.items() if not name.startswith('jni/')}
    if common is None:
        common = portable
    assert portable == common, f'Non-native SDK contents differ for {abi}'
    assert f'jni/{abi}/libmaplibre.so' in files
    assert all(name.split('/')[1] == abi for name in files if name.startswith('jni/'))
    entries.update(files)
with zipfile.ZipFile(aar, 'w', zipfile.ZIP_DEFLATED) as target:
    for name, data in sorted(entries.items()):
        target.writestr(name, data)
for module in repository.rglob('*.module'):
    metadata = json.loads(module.read_text())
    for variant in metadata['variants']:
        for entry in variant.get('files', []):
            data = (module.parent / entry['url']).read_bytes()
            entry['size'] = len(data)
            for algorithm in ('sha512', 'sha256', 'sha1', 'md5'):
                entry[algorithm] = hashlib.new(algorithm, data).hexdigest()
    module.write_text(json.dumps(metadata, indent=2) + '\n')
for file in list(repository.rglob('*')):
    if file.is_file() and file.suffix in ('.sha512', '.sha256', '.sha1', '.md5'):
        original = file.with_suffix('')
        file.write_text(hashlib.new(file.suffix[1:], original.read_bytes()).hexdigest())
(repository / 'SOURCE.json').write_text(json.dumps({
    'repository': 'https://github.com/macrocity/maplibre-native',
    'sourceRevision': os.environ['SOURCE_REVISION'],
    'build': f"https://github.com/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
}, indent=2) + '\n')
archive = output / 'android-maven.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as target:
    for file in sorted(repository.rglob('*')):
        if file.is_file():
            target.write(file, file.relative_to(repository))
print(json.dumps({'file': archive.name, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest()}, indent=2))
