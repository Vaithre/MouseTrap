#!/usr/bin/env python3
"""Build an installable KWin Script."""

import argparse
import json
from pathlib import Path
import subprocess
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    version_file = ROOT / 'VERSION'
    if not version_file.is_file():
        parser.error('Missing VERSION file')
    version = version_file.read_text(encoding='utf-8').strip()
    if not version or Path(version).name != version:
        parser.error('Invalid version in VERSION')
    metadata = json.loads((ROOT / 'metadata.json').read_text(encoding='utf-8'))
    if metadata['KPlugin']['Version'] != version:
        parser.error('VERSION and metadata.json version do not match')
    main_script = ROOT / 'contents' / metadata['X-Plasma-MainScript']
    domain = metadata['X-KWin-Config-TranslationDomain']
    if not domain or Path(domain).name != domain:
        parser.error('Invalid translation domain in metadata.json')

    required = [version_file, ROOT / 'metadata.json', ROOT / 'LICENSE', ROOT / 'README.md',
                main_script, ROOT / 'contents/ui/config.ui', ROOT / 'contents/config/main.xml']
    for path in required:
        if not path.is_file():
            parser.error(f'Missing required file: {path}')

    catalogs = sorted((ROOT / 'po').glob('*.po'))
    if not catalogs:
        parser.error('No translation catalogs found in po/')

    # Rebuild translations from their sources.
    files = [version_file, ROOT / 'metadata.json', ROOT / 'LICENSE']
    files += sorted(ROOT.glob('README*.md'))
    files += [p for p in sorted((ROOT / 'contents').rglob('*'))
              if p.is_file() and p.relative_to(ROOT / 'contents').parts[0] != 'locale']
    files += [p for p in sorted((ROOT / 'docs').rglob('*')) if p.is_file()]
    files += [p for name in ('mouse-trap.svg', 'mouse-trap.png')
              if (p := ROOT / name).is_file()]

    output = (args.output or ROOT / 'dist' / f'mouse-trap-{version}.kwinscript').expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix='.mouse-trap-', dir=output.parent) as directory:
        staging = Path(directory)
        compiled = []
        for source in catalogs:
            relative = Path('contents/locale') / source.stem / 'LC_MESSAGES' / f'{domain}.mo'
            target = staging / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(['msgfmt', '--check', str(source), '-o', str(target)], check=True)
            compiled.append((target, relative))

        package = staging / output.name
        with ZipFile(package, 'w', ZIP_DEFLATED) as archive:
            for path in files:
                archive.write(path, path.relative_to(ROOT))
            for path, relative in compiled:
                archive.write(path, relative)
        with ZipFile(package) as archive:
            if archive.testzip() is not None:
                raise RuntimeError('Package integrity check failed')
        package.replace(output)

    print(f'{output} ({len(files) + len(compiled)} files; languages: en, '
          + ', '.join(source.stem for source in catalogs) + ')')


if __name__ == '__main__':
    main()
