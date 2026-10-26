#!/usr/bin/env python3

import argparse
from pathlib import Path
import subprocess
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/mouse-trap.kwinscript')
    args = parser.parse_args()
    for source in sorted((ROOT / 'po').glob('*.po')):
        target = ROOT / 'contents/locale' / source.stem / 'LC_MESSAGES/mouse-trap-config.mo'
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['msgfmt', '--check', str(source), '-o', str(target)], check=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.output, 'w', ZIP_DEFLATED) as archive:
        files = [ROOT / 'metadata.json', ROOT / 'LICENSE', ROOT / 'README.md']
        files += sorted((ROOT / 'contents').rglob('*'))
        files += sorted((ROOT / 'docs').rglob('*'))
        for path in files:
            if path.is_file():
                archive.write(path, path.relative_to(ROOT))
    print(args.output)


if __name__ == '__main__':
    main()
