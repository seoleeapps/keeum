#!/usr/bin/env python3
"""중앙 태그 빌드에 실제 광고 ID만 주입한다. 서명과 업로드는 중앙 workflow가 소유한다."""
import json
import os
import re
from pathlib import Path

app_id = os.environ.get('ADMOB_APP_ID', '')
rewarded = os.environ.get('ADMOB_REWARDED_AD_UNIT_ID', '')
interstitial = os.environ.get('ADMOB_INTERSTITIAL_AD_UNIT_ID', '')
for name, value, separator in [('app', app_id, '~'), ('rewarded', rewarded, '/'), ('interstitial', interstitial, '/')]:
    if not re.fullmatch(r'ca-app-pub-[0-9]{16}' + re.escape(separator) + r'[0-9]{10}', value):
        raise SystemExit(f'실제 AdMob {name} ID가 필요합니다')
    if '3940256099942544' in value:
        raise SystemExit('출시 빌드에는 Google 데모 광고 ID를 사용할 수 없습니다')
if rewarded == interstitial:
    raise SystemExit('보상형과 전면 광고 단위는 달라야 합니다')
p = Path('data/monetization/ads.json')
d = json.loads(p.read_text())
d['android'] = {'rewarded_unit_id': rewarded, 'interstitial_unit_id': interstitial}
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
p = Path('project.godot')
s = p.read_text()
s, count = re.subn(r'^general/android/app_id=.*$', f'general/android/app_id="{app_id}"', s, flags=re.MULTILINE)
if count != 1:
    raise SystemExit('AdMob app_id 설정이 유일하지 않습니다')
p.write_text(s)
print('실제 Android 광고 ID 주입 완료')
