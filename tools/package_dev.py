#!/usr/bin/env python3
"""Build a separate Mouse Trap package for testing alongside the installed release.

This package is virtually identical to the original, it just has different
metadata so it can be installed alongside the real package. Technically, you can use it if you really, really want to.
"""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent


def replace_exactly(text, old, new, count=1):
    actual = text.count(old)
    if actual != count:
        raise ValueError(f'Expected {count} occurrence(s) of {old!r}, found {actual}')
    return text.replace(old, new)


def update_text(path, replacements):
    text = path.read_text(encoding='utf-8')
    for old, new, count in replacements:
        text = replace_exactly(text, old, new, count)
    path.write_text(text, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/mouse-trap-dev.kwinscript')
    args = parser.parse_args()
    output = args.output.expanduser().resolve()
    release_output = (ROOT / 'dist/mouse-trap.kwinscript').resolve()
    if output == release_output:
        parser.error('The dev package cannot replace the release package')

    with tempfile.TemporaryDirectory(prefix='mouse-trap-dev-') as directory:
        staging = Path(directory) / 'source'
        shutil.copytree(ROOT, staging, ignore=shutil.ignore_patterns('.git', 'dist', '__pycache__'))

        metadata_path = staging / 'metadata.json'
        metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
        plugin = metadata['KPlugin']
        plugin['Id'] = 'mouse-trap-dev'
        plugin['Name'] = 'Mouse Trap (Dev)'
        metadata['X-KWin-Config-TranslationDomain'] = 'mouse-trap-dev-config'
        for key in ('Description', 'Description[es]', 'Description[pt]', 'Description[pt_BR]'):
            if key in plugin:
                plugin[key] += ' (Dev)'
        metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

        update_text(staging / 'contents/ui/main.qml', [
            ('name: "mouse-trap-toggle"', 'name: "mouse-trap-dev-toggle"', 1),
            ('text: root.shortcutLabel()', 'text: root.shortcutLabel() + " (Dev)"', 1),
        ])
        update_text(staging / 'contents/ui/config.ui', [
            ('"Toggle Mouse Trap" under KWin.', '"Toggle Mouse Trap (Dev)" under KWin.', 1),
        ])
        for language in ('es', 'pt', 'pt_BR'):
            update_text(staging / 'po' / f'{language}.po', [
                ('Mouse Trap\\"', 'Mouse Trap (Dev)\\"', 2),
            ])

        subprocess.run([sys.executable, str(staging / 'tools/package.py'),
                        '--output', str(output)], check=True)


if __name__ == '__main__':
    main()
