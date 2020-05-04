class_name CardModel extends Model

var title : String
var description : String

func _init(_id : String, _title : String, _description : String = "").(ModelTypes.CARD, _id):
	title = _title
	description = _description
