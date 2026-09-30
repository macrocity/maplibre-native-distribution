"""Combine identical per-ABI publications, checking contents and refreshing Maven hashes.

Also packs the unstripped libmaplibre.so of every ABI, from the same builds, into android-native-symbols.zip.
The SDK ships its libraries stripped; a crash reporter reads files and lines from these (Crashlytics:
`unstrippedNativeLibsDir`). Each is checked against the stripped library in the SDK by its GNU build ID.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import sys
import zipfile

architectures, output = map(Path, sys.argv[1:])


def elf_sections(data):
    """The sections of a 64- or 32-bit little-endian ELF file, by name: (offset, size)."""
    assert data[:4] == b'\x7fELF' and data[5] == 1, 'not a little-endian ELF file'
    wide = data[4] == 2
    if wide:
        shoff, = struct.unpack_from('<Q', data, 0x28)
        shentsize, shnum, shstrndx = struct.unpack_from('<HHH', data, 0x3A)
    else:
        shoff, = struct.unpack_from('<I', data, 0x20)
        shentsize, shnum, shstrndx = struct.unpack_from('<HHH', data, 0x2E)
    headers = []
    for index in range(shnum):
        base = shoff + index * shentsize
        if wide:
            name, = struct.unpack_from('<I', data, base)
            offset, size = struct.unpack_from('<QQ', data, base + 0x18)
        else:
            name, = struct.unpack_from('<I', data, base)
            offset, size = struct.unpack_from('<II', data, base + 0x10)
        headers.append((name, offset, size))
    strings_offset = headers[shstrndx][1]
    sections = {}
    for name, offset, size in headers:
        end = data.index(b'\0', strings_offset + name)
        sections[data[strings_offset + name:end].decode()] = (offset, size)
    return sections


def build_id(data):
    """The GNU build ID of an ELF library, as hex."""
    offset, size = elf_sections(data)['.note.gnu.build-id']
    namesz, descsz, kind = struct.unpack_from('<III', data, offset)
    assert kind == 3, 'not a GNU build ID note'
    start = offset + 12 + (namesz + 3) // 4 * 4
    return data[start:start + descsz].hex()

abis = ('arm64-v8a', 'x86_64', 'armeabi-v7a', 'x86')
repository = output / 'maven'
shutil.copytree(architectures / 'android-arm64-v8a', repository)
aars = list(repository.rglob('*.aar'))
assert len(aars) == 1
aar = aars[0]
entries = {}
symbols = {}
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
    unstripped = (architectures / f'android-symbols-{abi}' / abi / 'libmaplibre.so').read_bytes()
    assert '.debug_info' in elf_sections(unstripped), f'The unstripped libmaplibre.so of {abi} has no debug info'
    shipped = files[f'jni/{abi}/libmaplibre.so']
    assert build_id(unstripped) == build_id(shipped), f'The unstripped libmaplibre.so of {abi} is not the one in the SDK'
    symbols[abi] = unstripped
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
symbols_archive = output / 'android-native-symbols.zip'
with zipfile.ZipFile(symbols_archive, 'w', zipfile.ZIP_DEFLATED) as target:
    for abi, data in sorted(symbols.items()):
        target.writestr(f'{abi}/libmaplibre.so', data)
    target.writestr('SOURCE.json', (repository / 'SOURCE.json').read_text())
print(json.dumps([
    {'file': archive.name, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest()},
    {'file': symbols_archive.name, 'sha256': hashlib.sha256(symbols_archive.read_bytes()).hexdigest()},
], indent=2))
