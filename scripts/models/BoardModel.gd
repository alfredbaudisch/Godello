class_name BoardModel extends Model

var title : String = ""
var is_public := false setget set_public
var archived_cards : Dictionary = {} setget ,get_archived_cards

func _init(_id : String, _is_public : bool = false, _title : String = "").(ModelTypes.BOARD, _id):
	title = _title
	is_public = _is_public
	
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
	
func _to_string():
	return to_json({
		"id": id,
		"title": title,
		"is_public": is_public
	})

func _notify_updated():
	DataRepository.update_board(self)
