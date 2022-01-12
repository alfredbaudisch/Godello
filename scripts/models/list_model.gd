class_name ListModel extends Model


export(String) var board_id = ""
export(String) var title = ""
export(Array) var cards = []
export(Dictionary) var cards_by_id = {}


# Needs default values to be loaded as custom resource
func _init(
	_id : String = "",
	_board_id : String  = "",
	_title : String = "",
	_cards : Array = []
).(ModelTypes.LIST, _id):
	board_id = _board_id
	title = _title
	cards = _cards
	_map_cards_by_id()


func set_title(_title : String):
	title = _title
	_notify_updated()


func add_card(card):
	if not cards_by_id.get(card.id):
		card.list_id = id
		cards.append(card)
		cards_by_id[card.id] = card


func remove_cards():
	cards_by_id.clear()
	cards.clear()


func remove_card(card):
	var card_idx = cards.find(card)
	if card_idx != -1:
		cards.remove(card_idx)

	if !cards_by_id.erase(card.id):
		push_error("[list_model.remove_card] remove card with id %s not found" % card.id)


func _map_cards_by_id():
	for card in cards:
		cards_by_id[card.id] = card


func _notify_updated():
	DataRepository.update_list(self)


func _to_string() -> String:
	return to_json({
		"title":title,
		"id":id
	})
