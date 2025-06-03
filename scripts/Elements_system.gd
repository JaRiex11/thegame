extends Node
class_name ElementsSystem

enum ELEMENT { NONE, PHYSIC, FIRE, WATER, STEAM }
enum STATUS_EFFECT { NONE, BURNING, WET }

# Реакции как массив [атакующий, защитник, результат]
const _REACTIONS = [
	[ELEMENT.FIRE, ELEMENT.WATER, ELEMENT.STEAM],
	[ELEMENT.FIRE, STATUS_EFFECT.WET, ELEMENT.STEAM],
	[ELEMENT.WATER, ELEMENT.FIRE, ELEMENT.STEAM],
	[ELEMENT.WATER, STATUS_EFFECT.BURNING, ELEMENT.STEAM]
]

# Множители урона [атакующий, защитник, множитель]
const _DAMAGE_MULTIPLIERS = [
	[ELEMENT.FIRE, ELEMENT.FIRE, 0.0],
	[ELEMENT.FIRE, ELEMENT.WATER, 2.0],
	[ELEMENT.WATER, ELEMENT.WATER, 0.0],
	[ELEMENT.WATER, ELEMENT.FIRE, 2.0]
]

static func get_reaction(attacker: ELEMENT, defender: Variant) -> ELEMENT:
	for reaction in _REACTIONS:
		if reaction[0] == attacker and reaction[1] == defender:
			return reaction[2]
	return ELEMENT.NONE

static func get_damage_multiplier(attacker: ELEMENT, defender: ELEMENT) -> float:
	for multiplier in _DAMAGE_MULTIPLIERS:
		if multiplier[0] == attacker and multiplier[1] == defender:
			return multiplier[2]
	return 1.0

static func element_to_string(element: ELEMENT) -> String:
	return ELEMENT.keys()[element]
