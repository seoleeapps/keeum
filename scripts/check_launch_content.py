#!/usr/bin/env python3
"""콘텐츠 수, 조건 문법과 실제 CG 파일을 확인한다. 플레이 경로는 launch_checks.gd가 검증한다."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
stats = ['academic', 'emotion', 'stress', 'talent', 'bonding', 'stamina', 'temptation']
allowed = {'applied', 'exposed', 'temperament'} | {s + suffix for s in stats for suffix in ['_min', '_max']}
for name, count in [('activities', 24), ('events', 48), ('endings', 40)]:
    items = json.loads((root / 'data' / (name + '.json')).read_text())[name]
    assert len(items) == count, (name, len(items))
    assert len({i['id'] for i in items}) == count, name + ' duplicate IDs'
    if name == 'events':
        assert all(i.get('choices') and i.get('body') for i in items)
    if name == 'endings':
        assert len({i['priority'] for i in items}) == count, 'priority must be unique'
        for item in items:
            assert set(item['requires']) <= allowed, item['id'] + ' unknown condition'
            for stat in stats:
                assert int(item['requires'].get(stat + '_min', 0)) <= int(item['requires'].get(stat + '_max', 100)), item['id']
        cg = [i for i in items if i['cg']]
        assert len(cg) == 12
        assert all((root / 'assets' / 'art' / ('cg_' + i['id'] + '.png')).is_file() for i in cg)
print('콘텐츠 검증 통과: 활동 24, 이벤트 48, 엔딩 40, CG 12')
