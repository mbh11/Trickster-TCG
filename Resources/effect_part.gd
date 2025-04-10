extends Resource
class_name effect_part

enum types {dealDamage, restoreHealth, changeSP, changeDamage, drawCard, drawCategory}

@export var type: types
@export var magnitude: int
