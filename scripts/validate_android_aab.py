#!/usr/bin/env python3
"""AAB의 실제 ELF LOAD 정렬과 원본 에셋 제외를 확인한다."""
import struct
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as bundle:
    libs = [n for n in bundle.namelist() if n.endswith('.so')]
    if not libs:
        raise SystemExit('AAB 안에 네이티브 라이브러리가 없습니다')
    for name in bundle.namelist():
        if any(part in name for part in ['assets/art/raw/', 'assets/audio/raw/', 'tools/e2e/']):
            raise SystemExit('테스트 또는 재생성 원본이 AAB에 포함됐습니다: ' + name)
    for name in libs:
        data = bundle.read(name)
        if data[:4] != b'\x7fELF' or data[4] != 2 or data[5] != 1:
            raise SystemExit('지원하지 않는 네이티브 라이브러리: ' + name)
        offset = struct.unpack_from('<Q', data, 32)[0]
        entry_size, count = struct.unpack_from('<HH', data, 54)
        loads = 0
        for index in range(count):
            base = offset + index * entry_size
            kind = struct.unpack_from('<I', data, base)[0]
            if kind == 1:
                loads += 1
                alignment = struct.unpack_from('<Q', data, base + 48)[0]
                if alignment < 16384:
                    raise SystemExit('16KB ELF 정렬 미충족: ' + name)
        if not loads:
            raise SystemExit('ELF LOAD 세그먼트 없음: ' + name)
print(f'16KB ELF 정렬 통과: {len(libs)}개 라이브러리. package, API와 서명은 중앙 AAB readback으로 별도 확인합니다.')
