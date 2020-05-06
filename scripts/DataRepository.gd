extends Node

var lists : Array = [] setget ,get_lists
var lists_by_id : Dictionary = {}
var cards_by_id : Dictionary = {}

var list_nodes : Dictionary = {}
var card_nodes : Dictionary = {}

func _ready():
	Events.connect("card_dropped", self, "_on_card_dropped")

func get_lists():
	return lists

func get_list(id: String):
	return lists_by_id[id]
	
func add_list(list : ListModel, node : Control):
	lists.append(list)
	lists_by_id[list.id] = list
	list_nodes[list.id] = node
	_map_cards_by_id(list.cards)
	
func set_card_node(card : CardModel, node : Control):
	card_nodes[card.id] = node
	
func move_card_to_list(card : CardModel, list : ListModel):
	var from_list = lists_by_id[card.list_id]
	var to_list = lists_by_id[list.id]
	
	if from_list and to_list:
		to_list.add_card(card)
		from_list.remove_card(card)

func _on_card_dropped(drop_data, into_list):
	if drop_data["model"].list_id != into_list.id:
		move_card_to_list(drop_data["model"], into_list)

func _map_cards_by_id(cards : Array):
	for card in cards:
		cards_by_id[card.id] = card

func card_updated(card):
	print("CARD ", card.id, " UPDATED! ")
	print(cards_by_id[card.id])
