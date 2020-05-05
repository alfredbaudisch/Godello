class_name CardModel extends Model

var title : String
var description : String
var list_id : String

func _init(_id : String, _list_id : String, _title : String, _description : String = "").(ModelTypes.CARD, _id):
	list_id = _list_id
	title = _title
	description = _description

func get_drag_data(_node) -> Dictionary:
	return {
		["node"]: _node,
		["model"]: self
	}
