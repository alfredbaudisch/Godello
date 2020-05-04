class_name ListModel extends Model

var title : String
var cards : Array

func _init(_id : String, _title : String, _cards : Array = []).(ModelTypes.LIST, _id):
	title = _title
	cards = _cards
