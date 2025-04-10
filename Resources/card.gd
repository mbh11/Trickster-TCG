extends Resource
class_name card

enum types {monster, pet, npc, item, skill, region, trickster}
enum sets {base, coralBeach, desertBeach}
enum elements {none, power, magic, sense, charm, neutral}
enum categories {none, monkey, mole, cora, shell, elemental, G, mummy}
enum rarities {normal, special, rare, unique, legend}
enum triggers {onAttack, onSummon, onAttacked, onDeath, turnStart, turnEnd, continuous}
enum targets {user, anyTarget, allyTarget, enemyTarget, allyTeam, enemyTeam, all, allyTrickster, enemyTrickster, attackTarget}
enum filters {choose, random, lowestHP, underSP, overSP, underHP, overHP, underATK, overATK}
enum effects {dealDamage, restoreHealth, changeSP, changeDamage, drawCard, drawRefcard, createRefcard, setExtraAttack, setStun}
var set_count = [33,12,0]

@export var type: types
@export var name: String
@export var art: Texture2D
@export_range(0,9) var cost: int
@export var hp: int
@export var attack: int
@export var duration: int
@export var element: elements
@export var category: categories

@export var passive_name: String
@export_multiline var passive_description: String
@export var passive_trigger: triggers
@export var passive_target: targets
@export var passive_filter: filters
@export var passive_filter_magnitude: int
@export var passive_effect: effects
@export var passive_magnitude: int
@export var refcard: Array[card]

@export var set_name: sets
@export var set_number: String
@export var rarity: rarities
