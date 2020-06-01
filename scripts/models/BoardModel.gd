class_name BoardModel extends Model

var title : String = ""
var is_public := false setget set_public
var archived_cards : Dictionary = {} setget ,get_archived_cards

var lists : Array = []
var lists_by_id : Dictionary = {}

func _init(_id : String, _is_public : bool = false, _title : String = "", _lists : Array = []).(ModelTypes.BOARD, _id):
	title = _title
	is_public = _is_public
	lists = _lists
	_map_lists_by_id()
	
func set_title(_title : String):
	title = _title
	_notify_updated()
	
func add_archived_card(card):
	archived_cards[card.id] = card
	
func remove_archived_card(card):	
	archived_cards.erase(card.id)
	
func get_archived_cards() -> Dictionary:
	return archived_cards
	
func set_public(value : bool):
	is_public = value

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
	
	lists_by_id.erase(list.id)

func _map_lists_by_id():
	for list in lists:
		lists_by_id[list.id] = list
	
func _to_string():
	return to_json({
		"id": id,
		"title": title,
		"is_public": is_public
	})

func _notify_updated():
	DataRepository.update_board(self)
