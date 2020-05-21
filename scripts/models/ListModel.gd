class_name ListModel extends Model

var title : String = ""
var cards : Array = []
var cards_by_id : Dictionary = {}
var board_id : String = ""

func _init(_id : String, _board_id : String, _title : String, _cards : Array = []).(ModelTypes.LIST, _id):
	title = _title
	board_id = _board_id
	cards = _cards
	_map_cards_by_id()

func add_card(card):
	if not cards_by_id.get(card.id):
		card.list_id = id
		cards.append(card)
		cards_by_id[card.id] = card
	
func remove_card(card):	
	var card_idx = cards.find(card)	
	if card_idx != -1:
		cards.remove(card_idx)		
	
	cards_by_id.erase(card.id)

func _map_cards_by_id():
	for card in cards:
		cards_by_id[card.id] = card
