class_name CardModel extends Model

var title : String = ""
var description : String = "" setget set_description
var list_id : String = ""
var tasks : Array = []

func _init(_id : String, _list_id : String, _title : String, _description : String = "").(ModelTypes.CARD, _id):
	list_id = _list_id
	title = _title
	description = _description

func set_title(_title: String):
	title = _title
	_notify_updated()
	
func set_description(_description: String):
	description = _description
	_notify_updated()

func _notify_updated():
	DataRepository.card_updated(self)

func _to_string():
	return to_json({
		"id": id,
		"title": title,
		"description": description,
		"list_id": list_id
	})
