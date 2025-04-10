extends Node3D

@export var player_name: String
@onready var cardBase = preload("res://Cards/card_scene.tscn")
@export var d: deck
@export var height_curve: Curve
var turn = 0
@export var sp = 0
@export var active = false
@export var is_AI = false

func _ready():
	var t = $Trickster.get_children()[0]
	t.c = d.trickster[0]
	t.player = self
	t.enemy = get_node("../../Game Board/Enemy")
	t._ready()
	d.cards.shuffle()
	draw(4)
	if !is_AI:
		turn_start()

func turn_start():
	$"../Label3D".text = player_name + "'s turn"
	turn += 1
	changeSP(turn)
	trigger_turn_start()
	draw(1)
	active = true
	if turn == 4:
		$Trickster.get_children()[0].c = d.trickster[1]
		$Trickster.get_children()[0].set_card()
		$Trickster.get_children()[0].reveal()
	if turn == 7:
		$Trickster.get_children()[0].c = d.trickster[2]
		$Trickster.get_children()[0].set_card()
		$Trickster.get_children()[0].reveal()
	$"../../UI/End Turn".disabled = !$"../../UI/End Turn".disabled
	if is_AI:
		auto_turn()

func auto_turn():
	await get_tree().create_timer(2).timeout
	for i in $Hand.get_children():
		if i.c.cost <= sp:
			i._on_click()
			await get_tree().create_timer(2).timeout
	print(name + " is done summoning.")
	await get_tree().create_timer(1).timeout
	for i in $Field.get_children():
		if !i.has_attacked:
			i._on_click()
			await get_tree().create_timer(2).timeout
	print(name + " is done attacking.")
	await get_tree().create_timer(1).timeout
	active = false
	turn_end()

func turn_end():
	trigger_turn_end()
	$"../../UI/End Turn".disabled = !$"../../UI/End Turn".disabled
	active = false
	if name == "Player":
		$"../../Game Board/Enemy".turn_start()
	else:
		$"../../Game Board/Player".turn_start()

func add_to_hand(crd):
	var scene = cardBase.instantiate()
	scene.c = crd
	scene.player = self
	if self.name == "Player":
		scene.enemy = $"../../Game Board/Enemy"
		scene.set_facedown(false)
	else:
		scene.enemy = $"../../Game Board/Player"
		scene.set_facedown(true)
	$Hand.add_child(scene)
	clean_hand()

func draw(n):
	for i in n:
		if d.cards.size() > 0:
			print(name + " draws " + d.cards[i].name)
			add_to_hand(d.cards[i])
			d.cards.remove_at(i)
			$"Deck/Count".text = str(d.cards.size())
		else:
			pass #Out of cards

func draw_once_from_position(i):
	print(name + " draws " + d.cards[i].name)
	add_to_hand(d.cards[i])
	d.cards.remove_at(i)
	$"Deck/Count".text = str(d.cards.size())

func clean_hand():
	for i in $Hand.get_children():
		var hand_ratio = 0.5
		if $Hand.get_child_count() > 1:
			hand_ratio = float(i.get_index())/float($Hand.get_child_count()-1)
		var size = 1 + (.4 * $Hand.get_child_count())
		i.position.x = -size/2 + (size * hand_ratio)
		i.position.y = 0 - (.2 * height_curve.sample(hand_ratio))
		i.position.z = 0 - (.2 * height_curve.sample(hand_ratio))
		i.rotation_degrees = Vector3(i.rotation.x, 15 - (30*hand_ratio), i.rotation.z)
		i.update_numbers()
	for i in $Field.get_children():
		var field_ratio = 0.5
		if $Field.get_child_count() > 1:
			field_ratio = float(i.get_index())/float($Field.get_child_count()-1)
		var size = ($Field.get_child_count()-1)*2
		i.position.x = -size/2 + (size * field_ratio)
	for i in $"NPC Zone".get_children():
		var field_ratio = 0.5
		if $"NPC Zone".get_child_count() > 1:
			field_ratio = float(i.get_index())/float($"NPC Zone".get_child_count()-1)
		i.position.x = -2 + (4 * field_ratio)

func update_numbers():
	$SP.text = str(sp)

func trigger_turn_start():
	var arr = []
	for i in $Field.get_children():
		arr.append(i)
	for i in $Region.get_children():
		arr.append(i)
	for i in $"NPC Zone".get_children():
		arr.append(i)
	for i in $"Trickster".get_children():
		arr.append(i)
	for i in arr:
		i.passive_used = false
		i.has_attacked = false
		if i.c.passive_trigger == i.c.triggers.turnStart:
			i.activate_passive()
		i.update_numbers()

func trigger_turn_end():
	var arr = []
	for i in $Field.get_children():
		arr.append(i)
	for i in $Region.get_children():
		arr.append(i)
	for i in $"NPC Zone".get_children():
		arr.append(i)
	for i in arr:
		if i.c.passive_trigger == i.c.triggers.turnEnd:
			i.activate_passive()

func _on_end_turn_pressed():
	turn_end()

func changeSP(n):
	sp += n
	update_numbers()
