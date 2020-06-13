extends Node

var active_user : UserModel setget set_active_user
var active_board : BoardModel setget set_active_board,get_active_board
var boards_by_id : Dictionary = {}
var lists_by_id : Dictionary = {}
var cards_by_id : Dictionary = {}
var list_draft_cards : Dictionary = {}

signal board_created(board)
signal board_updated(board)
signal board_deleted(board)
signal list_created(list)
signal list_updated(list)
signal list_deleted(list)
signal card_created(card)
signal card_updated(card)
signal card_deleted(card)

func _ready():
	Events.connect("card_dropped", self, "_on_card_dropped")
	Events.connect("user_logged_in", self, "_on_user_logged_in")
	Events.connect("user_logged_out", self, "_on_user_logged_out")
	
	set_active_user(UserModel.new("1", "Alfred", "R Baudisch", "alfred@alfred"))

func _on_user_logged_in(user : UserModel):
	set_active_user(user)
	
func _on_user_logged_out():
	set_active_user(null)

func set_active_user(value : UserModel):
	active_user = value
	
func add_board_member(email : String, board : BoardModel):
	# TODO: check if member exists
	var user_found = UserModel.new(UUID.v4(), "Member", "Name", email)
	board.add_member(user_found)
	
func set_active_board(value : BoardModel):
	active_board = value

func get_active_board() -> BoardModel:
	return active_board
	
func add_board(board : BoardModel):
	boards_by_id[board.id] = board

func get_board(id: String):
	return boards_by_id[id]

func get_list(id: String):
	return lists_by_id[id]
	
func add_list(list : ListModel):
	lists_by_id[list.id] = list	
	_map_cards_by_id(list.cards)

	var board = boards_by_id[list.board_id]
	board.add_list(list)

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
	var list = get_list(card.list_id)
	list.remove_card(card)
		
	get_board(list.board_id).remove_archived_card(card)
	cards_by_id.erase(card.id)
	
	emit_signal("card_deleted", card)

func update_card(card, was_draft := false, was_archived := false):
	var list = get_list(card.list_id)
	var board = get_board(list.board_id)
	
	if was_draft and not card.is_draft:		
		list.add_card(card)
		_set_draft_card_for_list(list)
		cards_by_id[card.id] = card
		emit_signal("card_created", card)
		return		
	elif was_archived and not card.is_archived:
		board.remove_archived_card(card)
	elif not was_archived and card.is_archived:
		board.add_archived_card(card)
		
	emit_signal("card_updated", card)
	
func delete_list(list):
	lists_by_id.erase(list.id)
	list.remove_cards()

	var board = boards_by_id[list.board_id]
	board.remove_list(list)

	emit_signal("list_deleted", list)
	
func update_list(list):
	emit_signal("list_updated", list)
	
func update_board(board):
	emit_signal("board_updated", board)
	
func delete_board(board):
	boards_by_id.erase(board.id)
	emit_signal("board_deleted", board)
	
func create_task(card, title, is_done := false) -> Dictionary:
	var task = TaskModel.new(card.id + str(card.tasks.size()), card.id, title, is_done) # todo: task id
	card.add_task(task)
	return {
		"task": task,
		"card": card
	}

func create_list(board, title):
	var list = ListModel.new(UUID.v4(), board.id, title)
	add_list(list)
	emit_signal("list_created", list)
	
func create_board(board):
	add_board(board)
	emit_signal("board_created", board)
	
func get_draft_board(is_public : bool) -> BoardModel:
	return BoardModel.new(UUID.v4(), active_user, is_public)

func get_draft_card(list):
	var draft_card = _find_draft_card_for_list(list)
	
	if not draft_card:	
		draft_card = CardModel.new(UUID.v4(), list.id)
		draft_card.set_draft()
		
	_set_draft_card_for_list(list, draft_card)
	cards_by_id[draft_card.id] = draft_card
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
