extends Resource
class_name deck

@export var trickster: Array[card]
@export var cards: Array[card]

func search_name(n):
	var r = []
	for i in cards.size():
		if cards[i].name == n:
			r.append(i)
	return r
