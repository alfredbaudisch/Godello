extends Node

var boards_by_id : Dictionary = {}
var lists_by_id : Dictionary = {}
var cards_by_id : Dictionary = {}
var list_draft_cards : Dictionary = {}

var board_nodes : Dictionary = {}
var list_nodes : Dictionary = {}
var card_nodes : Dictionary = {}

signal list_created(list)
signal list_updated(list)
signal list_deleted(list)
signal card_created(card)
signal card_updated(card)
signal card_deleted(card)

func _ready():
	Events.connect("card_dropped", self, "_on_card_dropped")
	
func add_board(board : BoardModel, node : Control):
	boards_by_id[board.id] = board
	board_nodes[board.id] = board

func get_board(id: String):
	return boards_by_id[id]

func get_list(id: String):
	return lists_by_id[id]
	
func add_list(list : ListModel, node : Control):
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
		
func delete_card(card):
	var node = card_nodes[card.id]
	node.queue_free()
	card_nodes.erase(card.id)
	
	var list = get_list(card.list_id)
	list.remove_card(card)
		
	get_board(list.board_id).remove_archived_card(card)
	
	card.free()

func update_card(card, was_draft := false, was_archived := false):
	var list = get_list(card.list_id)
	var board = get_board(list.board_id)
	
	if was_draft and not card.is_draft:		
		list.add_card(card)
		_set_draft_card_for_list(list)
		emit_signal("card_created", card)
		return		
	elif was_archived and not card.is_archived:
		board.remove_archived_card(card)
	elif not was_archived and card.is_archived:
		board.add_archived_card(card)
		
	emit_signal("card_updated", card)
	
func update_list(list):
	emit_signal("list_updated", list)
	
func create_task(card, title, is_done := false) -> Dictionary:
	var task = TaskModel.new(card.id + str(card.tasks.size()), card.id, title, is_done) # todo: task id
	card.add_task(task)
	return {
		"task": task,
		"card": card
	}

func get_draft_card(list):
	var draft_card = _find_draft_card_for_list(list)
	
	if not draft_card:	
		draft_card = CardModel.new(UUID.v4(), list.id)
		draft_card.set_draft()
		
	_set_draft_card_for_list(list, draft_card)
	return draft_card

# TODO: refactor to dict[list_id][draft_card_id] = foo
func _find_draft_card_for_list(list):	
	var draft_card = list_draft_cards.get(list.id)
	if draft_card:
		return draft_card
	
# TODO: refactor to dict[list_id][draft_card_id] = foo
func _set_draft_card_for_list(list, draft_card = null):
	if draft_card:
		list_draft_cards[list.id] = draft_card
	else:
		list_draft_cards.erase(list.id)
