class_name TaskModel extends Model

var title : String = ""
var card_id : String = ""
var is_done : bool = false

func _init(_id : String, _card_id : String, _title : String, _is_done : bool = false).(ModelTypes.TASK, _id):
	card_id = _card_id
	title = _title
	is_done = _is_done
