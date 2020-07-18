class_name BoardModel extends Model

var name : String = ""
var archived_cards : Dictionary = {} setget ,get_archived_cards
var is_public : bool = false

var user_owner : UserModel
var members : Array = []

var lists : Array = []
var lists_by_id : Dictionary = {}

func _init(_id : int, _owner : UserModel, _is_public := false, _name := "", _lists := [], _members := []).(ModelTypes.BOARD, _id):
	name = _name
	user_owner = _owner
	is_public = _is_public
	lists = _lists
	members = _members
	_map_lists_by_id()
	
func update_with_details(details : Dictionary, _members := [], should_update_lists := true, _lists := []):
	name = details["name"]
	
	if should_update_lists:
		remove_lists()
		lists = _lists
		_map_lists_by_id()
	
	members.clear()
	members = _members
	
func set_name(_name : String, should_notify := true):
	name = _name
	if should_notify: _notify_updated()
	
func add_archived_card(card):
	archived_cards[card.id] = card
	
func remove_archived_card(card):	
	archived_cards.erase(card.id)
	
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
	
	lists_by_id.erase(list.id)
	
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
		"name": name
	})

func _notify_updated():
	DataRepository.update_board(self)
