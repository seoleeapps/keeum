class_name CosmeticDraw
extends RefCounted
## 무료 젬 꾸미기 추첨 규칙. 표시와 실제 추첨이 같은 경계를 사용한다.
const PROB_SPECIAL := 0.03
const PROB_RARE := 0.17
const PITY := 40

static func tier_for_roll(roll: float, pity: int) -> String:
	if pity >= PITY or roll < PROB_SPECIAL: return "special"
	if roll < PROB_SPECIAL + PROB_RARE: return "rare"
	return "normal"
