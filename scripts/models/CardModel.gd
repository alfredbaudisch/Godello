class_name CardModel extends Model

var id : String
var title : String
var description : String

func _init(_id : String, _title : String, _description : String = "").(ModelTypes.CARD):
	id = _id
	title = _title
	description = _description
