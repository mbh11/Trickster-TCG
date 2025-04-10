extends Node3D

@export var c: card
@export var is_facedown: bool = false
var player
var enemy
@export var passive_used: bool = false
@export var has_attacked: bool = false

@export var cost: int = 0
@export var hp: int = 0
@export var attack: int = 0
@export var defense: int = 0
@export var duration: int = 0
@export var status = {"Extra Attack": 0, "Stun": 0}

func _ready():
	init_card()

func init_card():
	cost = c.cost
	hp = c.hp
	attack = c.attack
	duration = c.duration
	set_card()

func _process(_delta):
	if can_play() and player.name == "Player":
		$Front.shaded = false
	else:
		$Front.shaded = true
	
func set_card():
	name = c.name
	$Card/CardFront/Name.text = c.name
	$Card/CardFront/Art.texture = c.art
	var category = str(c.categories.find_key(c.category))
	if category != "none":
		$Card/CardFront/Category.text = str(category).capitalize()
	else:
		$Card/CardFront/Category.text = ""
	match c.element:
		c.elements.power:
			$Card/CardFront/Overlay.texture = load("res://Art/Parts/Overlay Power.png")
			$Card/CardFront/Icon.texture = load("res://Art/Parts/Icons/Power.png")
		c.elements.magic:
			$Card/CardFront/Overlay.texture = load("res://Art/Parts/Overlay Magic.png")
			$Card/CardFront/Icon.texture = load("res://Art/Parts/Icons/Magic.png")
		c.elements.sense:
			$Card/CardFront/Overlay.texture = load("res://Art/Parts/Overlay Sense.png")
			$Card/CardFront/Icon.texture = load("res://Art/Parts/Icons/Sense.png")
		c.elements.charm:
			$Card/CardFront/Overlay.texture = load("res://Art/Parts/Overlay Charm.png")
			$Card/CardFront/Icon.texture = load("res://Art/Parts/Icons/Charm.png")
		c.elements.neutral:
			$Card/CardFront/Overlay.texture = load("res://Art/Parts/Overlay Neutral.png")
		c.elements.none:
			$Card/CardFront/Overlay.texture = load("res://Art/Parts/Overlay Item.png")
	var ref
	match c.set_name:
		c.sets.base:
			ref = "Base"
		c.sets.coralBeach:
			ref = "Coral Beach"
		c.sets.desertBeach:
			ref = "Desert Beach"
	$Card/CardFront/BG.texture = load("res://Art/BG/" + ref + ".png")
	$Card/CardFront/Set.texture = load("res://Art/Parts/Icons/" + ref + ".png")
	$Card/CardFront/Set/SetNumber.text = c.set_number + "/" + str(c.set_count[c.set_name])
	
	if c.type == c.types.trickster:
		$Card/CardFront/Cost.visible = false
	if c.hp == 0:
		$Card/CardFront/HP.visible = false
	if c.attack == 0:
		$Card/CardFront/Damage.visible = false
	if c.duration == 0:
		$Card/CardFront/Duration.visible = false
	
	update_numbers()

func update_numbers():
	$Card/CardFront/Cost.text = str(cost)
	$Card/CardFront/HP.text = str(hp)
	$Card/CardFront/Damage.text = str(attack)
	$Card/CardFront/Duration.text = str(duration)
	
	var t = ""
	if c.passive_name != "":
		t = "[center][b]" + c.passive_name + "[/b]: "
	t += c.passive_description
	$Card/CardFront/DescBox/Description.text = t

func can_play():
	if player.active:
		if get_parent().name == "Hand" and player.sp >= c.cost:
			return true
		if get_parent().name == "Field":
			if !has_attacked:
				return true
	return false

func _on_click():
	if can_play():
		if get_parent().name == "Hand":
			play()
		else:
			if !has_attacked and attack > 0 and status["Stun"] == 0:
				attack_target()

func attack_target():
	if status["Extra Attack"] < 1:
		has_attacked = true
	else:
		status["Extra Attack"] -= 1
	
	$AnimationPlayer.play("activate")
	var finalTarget
	var t = enemy.get_node("Field").get_children()
	
	if t.size() > 0:
		finalTarget = t[0] #Add this later (targeting system)
	else:
		finalTarget = enemy.get_node("Trickster").get_children()[0]
		
	finalTarget.take_damage(attack)
	await get_tree().create_timer(1).timeout
	if c.passive_trigger == c.triggers.onAttack:
		activate_passive()
		if c.passive_target == c.targets.attackTarget and !passive_used:
			apply_passive([finalTarget])
		passive_used = true
	
	if finalTarget.c.passive_trigger == finalTarget.c.triggers.onAttacked:
		finalTarget.activate_passive()
		if finalTarget.c.passive_target == c.targets.attackTarget:
			finalTarget.apply_passive(self)

func play():
	var destination
	if c.type == c.types.monster or c.type == c.types.pet:
		destination = "Field"
	if c.type == c.types.npc:
		destination = "NPC Zone"
	if c.type == c.types.region:
		if player.get_node("Region").get_child_count() > 0: 
			$Region.get_child(1).to_graveyard()
		destination = "Region"
	if c.type == c.types.item or c.type == c.types.skill:
		destination = "Markers"
	if c.type == c.types.trickster:
		destination = "Trickster"
	
	reveal()
	await get_tree().create_timer(1).timeout
	summon(player.get_node(destination))

func summon(path):
	move_card(path)
	set_facedown(false)
	has_attacked = true
	if c.passive_trigger == c.triggers.onSummon:
		activate_passive()
		if c.type == c.types.item or c.type == c.types.skill:
			to_graveyard()
	player.changeSP(-c.cost)
	player.clean_hand()
	update_numbers()

func activate_passive():
	var enemySide = func():
		var t = []
		for i in enemy.get_node("Field").get_children():
			t.append(i)
		return t
	var allySide = func():
		var t = []
		for i in player.get_node("Field").get_children():
			t.append(i)
		return t
	
	var targets = []
	var finalTargets = []
	
	var f_lowestHP = func(t):
		if t.size() < 1:
			return
		var lowest = t[0]
		for i in t:
			if i.hp < lowest.hp:
				lowest = i
		return lowest
	var f_underSP = func(n):
		var a = []
		for i in targets:
			if i.cost < n:
				a.append(i)
		return a
	var f_overSP = func(n):
		var a = []
		for i in targets:
			if i.cost > n:
				a.append(i)
		return a
	var f_underHP = func(n):
		var a = []
		for i in targets:
			if i.hp < n:
				a.append(i)
		return a
	var f_overHP = func(n):
		var a = []
		for i in targets:
			if i.hp > n:
				a.append(i)
		return a
	var f_underATK = func(n):
		var a = []
		for i in targets:
			if i.attack < n:
				a.append(i)
		return a
	var f_overATK = func(n):
		var a = []
		for i in targets:
			if i.attack > n:
				a.append(i)
		return a
	
	match c.passive_target: #Pick group of potential targets, or final targets
		c.targets.user:
			finalTargets.append(self)
		c.targets.anyTarget:
			targets += (enemySide.call())
			targets += (allySide.call())
		c.targets.allyTarget:
			targets += (allySide.call())
		c.targets.enemyTarget:
			targets += (enemySide.call())
		c.targets.allyTeam:
			finalTargets += (allySide.call())
		c.targets.enemyTeam:
			finalTargets += (enemySide.call())
		c.targets.all:
			finalTargets += (allySide.call())
			finalTargets += (enemySide.call())
		c.targets.allyTrickster:
			finalTargets.append(player.get_node("Trickster").get_children()[0])
		c.targets.enemyTrickster:
			finalTargets.append(enemy.get_node("Trickster").get_children()[0])
		c.targets.attackTarget:
			return
	
	if targets.size() > 0: #Filter list of potential targets into final targets
		match c.passive_filter:
			c.filters.choose:
				finalTargets += (targets[0])
			c.filters.random:
				finalTargets += (targets[randi() % targets.size()])
			c.filters.lowestHP:
				finalTargets.append(f_lowestHP.call(targets))
			c.filters.underSP:
				finalTargets += (f_underSP.call(c.passive_filter_magnitude))
			c.filters.overSP:
				finalTargets += (f_overSP.call(c.passive_filter_magnitude))
			c.filters.underHP:
				finalTargets += (f_underHP.call(c.passive_filter_magnitude))
			c.filters.overHP:
				finalTargets += (f_overHP.call(c.passive_filter_magnitude))
			c.filters.underATK:
				finalTargets += (f_underATK.call(c.passive_filter_magnitude))
			c.filters.overATK:
				finalTargets += (f_overATK.call(c.passive_filter_magnitude))
	
	apply_passive(finalTargets)
	passive_used = true


func apply_passive(t):
	for i in t:
		match c.passive_effect:
			c.effects.dealDamage:
				i.take_damage(c.passive_magnitude)
			c.effects.restoreHealth:
				i.restore_hp(c.passive_magnitude)
			c.effects.changeSP:
				i.player.changeSP(c.passive_magnitude)
			c.effects.changeDamage:
				i.attack += c.passive_magnitude
				print(i.name+"'s attack increased by "+str(c.passive_magnitude))
				i.update_numbers()
			c.effects.drawCard:
				print("Drawing Card")
				player.draw(c.passive_magnitude)
			c.effects.drawRefcard:
				for x in range(1, c.passive_magnitude):
					var pool = []
					for j in c.refcard:
						pool + player.deck.search_name(j.name)
					print("Adding " + c.refcard[0].name + " to Hand")
					player.add_to_hand(c.refcard[0])
			c.effects.createRefcard:
				for x in range(1, c.passive_magnitude):
					print("Adding " + c.refcard[0].name + " to Hand")
					player.add_to_hand(c.refcard[0])
			c.effects.setExtraAttack:
				i.status["Extra Attack"] = c.passive_magnitude
			c.effects.setStun:
				i.status["Stun"] = c.passive_magnitude

func reveal():
	$"../../../../UI/Reveal/Card".texture = $Card.get_texture()
	$"../../../../UI/Reveal/AnimationPlayer".play("reveal")

func move_card(path):
	$AnimationPlayer.play("RESET")
	self.reparent(path)
	position = Vector3(0,0,0)
	rotation = Vector3(0,0,0)
	player.clean_hand()
	$AnimationPlayer.play("play")
	await get_tree().create_timer(1).timeout

func take_damage(n):
	hp -= n
	if hp <= 0:
		await get_tree().create_timer(0.4).timeout
		$AnimationPlayer.play("die")
	else:
		await get_tree().create_timer(0.4).timeout
		$AnimationPlayer.play("take_damage")
	show_damage(n)
	update_numbers()

func show_damage(n):
	$Damage/Label.text = str(n)
	$DamagePlayer.play("show_damage")

func show_healing(n):
	$Heal/Label.text = "+" + str(n)
	$HealPlayer.play("show_healing")

func restore_hp(n):
	var overheal = 0
	hp += n
	if hp > c.hp:
		overheal = hp - c.hp
		hp = c.hp
	$AnimationPlayer.play("heal")
	show_healing(str(n-overheal))
	update_numbers()

func to_graveyard():
	move_card(player.get_node("Graveyard"))
	$AnimationPlayer.play("flip_down")

func set_facedown(f):
	if f == true:
		is_facedown = true
		rotation_degrees = Vector3(rotation.x,rotation.y,180)
	else:
		is_facedown = false
		rotation_degrees = Vector3(rotation.x,rotation.y,0)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "die":
		to_graveyard()

func _on_mouse_entered():
	if $"../..".name == "Player" or $"../..".name == "Enemy":
		$"../../../../UI/Preview".texture = $Card.get_texture()
	if get_parent().name == "Hand":
		$AnimationPlayer.play("hover_in")

func _on_mouse_exited():
	if $"../..".name == "Player" or $"../..".name == "Enemy":
		$"../../../../UI/Preview".texture = null
	if get_parent().name == "Hand":
		$AnimationPlayer.play("hover_out")

func _on_hitbox_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Click Detected!")
			_on_click()
