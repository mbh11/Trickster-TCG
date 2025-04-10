extends Node
@export var cheatCard: card

func _ready():
	$"../BGM".stop()

func _input(event):
	if event.is_action_pressed("Tab"):
		$"../Game Board/Player".add_to_hand(cheatCard)
		$"../Game Board/Player".changeSP(cheatCard.cost)
		$sound.play()
