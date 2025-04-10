extends Node

func _ready():
	$"../BGM".stop()

func _input(event):
	if event.is_action_pressed("Tab"):
		$"../Game Board/Player".add_to_hand(load("res://Cards/Unit/Bad Fury.tres"))
		$"../Game Board/Player".changeSP(2)
		$sound.play()
