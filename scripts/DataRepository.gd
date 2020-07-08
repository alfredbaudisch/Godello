extends Node

var active_user : UserModel setget set_active_user
var active_board : BoardModel setget set_active_board,get_active_board
var boards_by_id : Dictionary = {} setget ,get_boards
var lists_by_id : Dictionary = {}
var cards_by_id : Dictionary = {}
var list_draft_cards : Dictionary = {}
var users_by_id : Dictionary = {}

var boards_loaded := false

const DRAFT_ITEM_TEMP_ID := -1
const PERSISTED_USER_FILE_NAME := "user://user_data.json"

signal boards_loaded()
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
	Events.connect("user_logged_out", self, "_on_user_logged_out")
	
	call_deferred("_load_persisted_user")
	
	Events.connect("backend_response", self, "_on_backend_response")

func _reset():
	set_active_user(null)
	set_active_board(null)
	users_by_id.clear()
	cards_by_id.clear()
	list_draft_cards.clear()
	lists_by_id.clear()
	boards_by_id.clear()
		
	boards_loaded = false	
	
func set_active_user(value : UserModel, persist : bool = true):
	active_user = value
	
	if persist:
		_persist_user()
	
	if active_user:
		add_user(active_user)
		Events.emit_signal("user_logged_in", active_user)	
		
func add_user(user : UserModel):
	users_by_id[user.id] = user
	
func add_board_member(email : String, board : BoardModel):
	# TODO: check if member exists
	var user_found = UserModel.new(DRAFT_ITEM_TEMP_ID, "Member", "Name", email)
	board.add_member(user_found)
	
func set_active_board(value : BoardModel):
	active_board = value

func get_active_board() -> BoardModel:
	return active_board

func get_boards() -> Dictionary:
	if not boards_loaded:
		DI.backend().get_boards()
		return {}
				
	else:
		return boards_by_id
	
func add_boards(boards : Array):
	for board in boards:
		add_board(board)
	
func add_board(board : BoardModel):
	boards_by_id[board.id] = board

func get_board(id: int):
	return boards_by_id.get(id)

func get_list(id: int):
	return lists_by_id.get(id)
	
func get_user(id: int):
	return users_by_id.get(id)
	
func add_list(list : ListModel):
	lists_by_id[list.id] = list	
	_map_cards_by_id(list.cards)

	var board = boards_by_id.get(list.board_id)
	board.add_list(list)

func move_card_to_list(card : CardModel, list : ListModel):
	var from_list = lists_by_id.get(card.list_id)
	var to_list = lists_by_id.get(list.id)
	
	if from_list and to_list:
		to_list.add_card(card)
		from_list.remove_card(card)

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
	var list = ListModel.new(DRAFT_ITEM_TEMP_ID, board.id, title)
	add_list(list)
	emit_signal("list_created", list)
	
func create_board(board):
	DI.backend().create_board(board.name)	
	
func get_draft_board(is_public : bool) -> BoardModel:
	return BoardModel.new(DRAFT_ITEM_TEMP_ID, active_user, is_public)

func get_draft_card(list):
	var draft_card = _find_draft_card_for_list(list)
	
	if not draft_card:	
		draft_card = CardModel.new(DRAFT_ITEM_TEMP_ID, list.id)
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

func _load_persisted_user():
	var file = File.new()
	if not file.file_exists(PERSISTED_USER_FILE_NAME):
		return
	
	file.open(PERSISTED_USER_FILE_NAME, File.READ)	
	var saved_data = parse_json(file.get_line())	
	file.close()
	
	if typeof(saved_data) == TYPE_DICTIONARY:
		var user = UserModel.new(
			saved_data["id"],
			saved_data["first_name"], saved_data["last_name"],
			saved_data["email"], saved_data["token"]
		)	
		set_active_user(user, false)	
	else:		
		_remove_persisted_user_file()

func _persist_user():
	if active_user:
		var file = File.new()
		file.open(PERSISTED_USER_FILE_NAME, File.WRITE)
		file.store_line(active_user.to_string())
		file.close()		
	else:
		_remove_persisted_user_file()
		
func _remove_persisted_user_file():
	var dir = Directory.new()
	dir.remove(PERSISTED_USER_FILE_NAME)
	
#
# Raw data utils
#

func _get_or_create_user_from_details(details : Dictionary) -> UserModel:
	var user = get_user(details["id"])
	
	if not user:		
		user = UserModel.new(details["id"], details["first_name"], details["last_name"], details["email"])
		add_user(user)
		
	return user

func _board_from_details(details : Dictionary) -> BoardModel:
	var members := []
	var lists := []
	var owner_user
	
	for user_details in details["users"]:
		var user = _get_or_create_user_from_details(user_details["user"])
		
		if user_details["is_owner"]:
			owner_user = user			
		else:
			members.append(user)
	
	# TODO: create lists
	for list_details in details["lists"]:
		pass

	return BoardModel.new(details["id"], owner_user, false, details["name"], lists, members)
	
#
# Signals
#

func _on_card_dropped(drop_data, into_list):
	if drop_data["model"].list_id != into_list.id:
		move_card_to_list(drop_data["model"], into_list)

func _on_user_logged_out():	
	_reset()

#
# Backend signals
#

func _on_backend_response(action : int, is_success : bool, body):
	if not is_success:
		return
		
	match action:
		Backend.Event.BOARD_CREATED:			
			var board = _board_from_details(body)
			add_board(board)
			emit_signal("board_created", board)
			
		Backend.Event.GET_BOARD:
			print("TODO IMPLEMENT ME - Backend.Event.GET_BOARD", body)
			# TODO: load full board into the model
			
		Backend.Event.GET_BOARDS:
			var boards := []			
			for details in body:
				boards.append(_board_from_details(details))
				
			add_boards(boards)
			boards_loaded = true
			emit_signal("boards_loaded")
