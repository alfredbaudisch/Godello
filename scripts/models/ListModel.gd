class_name ListModel extends Model

var title : String
var cards : Array

func _init(_id : String, _title : String, _cards : Array = []).(ModelTypes.LIST, _id):
	title = _title
	cards = _cards

func add_card(card):
	if card.list_id != id:
		card.list_id = id
		cards.append(card)
	
func remove_card(card):
	if card.list_id == id:
		var card_idx = cards.find(card)	
		if card_idx != -1:
			cards.remove(card_idx)
