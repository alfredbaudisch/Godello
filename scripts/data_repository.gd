extends Node


signal board_created(board)
signal board_updated(board)
signal board_deleted(board)
signal list_created(list)
signal list_updated(list)
signal list_deleted(list)
signal card_created(card)
signal card_updated(card)
signal card_deleted(card)

var active_user : UserModel setget set_active_user
var active_board : BoardModel setget set_active_board,get_active_board
var boards_by_id : Dictionary = {}
var lists_by_id : Dictionary = {}
var cards_by_id : Dictionary = {}
var list_draft_cards : Dictionary = {}


func _ready():
# warning-ignore:return_value_discarded
	Events.connect("card_dropped", self, "_on_card_dropped")
# warning-ignore:return_value_discarded
	Events.connect("order_updated", self, "_on_order_updated")
# warning-ignore:return_value_discarded
	Events.connect("user_logged_in", self, "_on_user_logged_in")
# warning-ignore:return_value_discarded
	Events.connect("user_logged_out", self, "_on_user_logged_out")

	if AppGlobal.backend == AppGlobal.Storage.LOCAL:
		set_active_user(AppGlobal.local_owner)
	elif AppGlobal.backend == AppGlobal.Storage.ELIXIR:
		set_active_user(UserModel.new("1", "Alfred", "R Baudisch", "alfred@alfred"))


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


func add_list(list : ListModel):
	lists_by_id[list.id] = list
	_map_cards_by_id(list.cards)

	var board = boards_by_id[list.board_id]
	board.add_list(list)


func get_list(id: String):
	return lists_by_id[id]


func move_card_to_list(card : CardModel, list : ListModel):
	var from_list = lists_by_id[card.list_id]
	var to_list = lists_by_id[list.id]

	if from_list and to_list:
		to_list.add_card(card)
		from_list.remove_card(card)

	emit_signal("board_updated", active_board)


func create_task(card, title, is_done := false) -> Dictionary:
	var task = TaskModel.new(card.id + str(card.tasks.size()), card.id, title, is_done) # todo: task id
	card.add_task(task)
	return {
		"task": task,
		"card": card
	}


func update_card(card, was_draft := false, was_archived := false):
	var list
	var board

	if active_board != null:
		list = get_list(card.list_id)
		board = get_board(list.board_id)

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


func delete_card(card:CardModel):
	var list = get_list(card.list_id)
	list.remove_card(card)

	if card.is_archived:
		get_board(list.board_id).remove_archived_card(card)
	if !cards_by_id.erase(card.id):
		push_error("[data_repository.delete_card] deleting card with id %s not found!" % card.id)

	emit_signal("card_deleted", card)


func create_list(board, title):
	var list = ListModel.new(UUID.v4(), board.id, title)
	add_list(list)
	emit_signal("list_created", list)


func update_list(list):
	emit_signal("list_updated", list)


func delete_list(list):
	if !lists_by_id.erase(list.id):
		push_error("[data_repository.delete_list] deleting list with id %s not found!" % list.id)
	list.remove_cards()

	var board = boards_by_id[list.board_id]
	board.remove_list(list)

	emit_signal("list_deleted", list)


func create_board(board):
	add_board(board)
	emit_signal("board_created", board)


func update_board(board):
	emit_signal("board_updated", board)


func delete_board(board):
	if !boards_by_id.erase(board.id):
		push_error("[data_repository.delete_board] deleting board with id %s not found!" % board.id)
	emit_signal("board_deleted", board)


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
		if !list_draft_cards.erase(list.id):
			push_error("[data_repository.set_draft_card_for_list] list with id %s not found!" % list.id)


func _on_user_logged_in(user : UserModel):
	set_active_user(user)


func _on_user_logged_out():
	set_active_user(null)


func _on_card_dropped(drop_data, into_list):
	if drop_data["model"].list_id != into_list.id:
		move_card_to_list(drop_data["model"], into_list)


func _on_order_updated(nodes : Array, type) -> void:
# warning-ignore:unassigned_variable
	var new_order : Array
	for node in nodes:
		if "model" in node:
			new_order.append(node.model)

	if type == Model.ModelTypes.LIST:
		active_board.lists.clear()
		active_board.lists = new_order
	elif type == Model.ModelTypes.CARD:
		var list = active_board.lists_by_id[new_order[0].list_id] as ListModel
		list.cards.clear()
		list.cards = new_order

	emit_signal("board_updated", active_board)


func _map_cards_by_id(cards : Array):
	for card in cards:
		cards_by_id[card.id] = card
