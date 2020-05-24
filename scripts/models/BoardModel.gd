class_name BoardModel extends Model

var title : String = ""

var archived_cards : Dictionary = {} setget ,get_archived_cards

func _init(_id : String, _title : String = "").(ModelTypes.BOARD, _id):
	title = _title
	
func add_archived_card(card):
	archived_cards[card.id] = card
	
func remove_archived_card(card):	
	archived_cards.erase(card.id)
	
func get_archived_cards() -> Dictionary:
	return archived_cards
	
func _to_string():
	return to_json({
		"id": id,
		"title": title
	})
