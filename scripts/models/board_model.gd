class_name BoardModel extends Model


var title : String = ""
var archived_cards : Dictionary = {} setget ,get_archived_cards
var is_public : bool = false

var user_owner : UserModel
var members : Array = []

var lists : Array = []
var lists_by_id : Dictionary = {}


func _init(_id : String, _owner : UserModel, _is_public := false, _title := "", _lists := []).(ModelTypes.BOARD, _id):
	title = _title
	user_owner = _owner
	is_public = _is_public
	lists = _lists
	_map_lists_by_id()


func set_title(_title : String):
	title = _title
	_notify_updated()


func add_archived_card(card):
	archived_cards[card.id] = card


func remove_archived_card(card):
	if !archived_cards.erase(card.id):
		print("[board_model.remove_archived_card] card with id not found: ", card.id)


func get_archived_cards() -> Dictionary:
	return archived_cards


func add_list(list):
	if not lists_by_id.get(list.id):
		list.board_id = id
		lists.append(list)
		lists_by_id[list.id] = list


func remove_lists():
	lists_by_id.clear()
	lists.clear()


func remove_list(list):
	var list_idx = lists.find(list)
	if list_idx != -1:
		lists.remove(list_idx)

	if !lists_by_id.erase(list.id):
		print("[board_model.remove_list] list with id not found: ", list.id)


func add_member(user : UserModel):
	if members.find(user) == -1:
		members.append(user)
		_notify_updated()


func remove_member(user : UserModel):
	members.erase(user)
	_notify_updated()


func _map_lists_by_id():
	for list in lists:
		lists_by_id[list.id] = list


func _to_string():
	return to_json({
		"id": id,
		"title": title
	})


func _notify_updated():
	DataRepository.update_board(self)
