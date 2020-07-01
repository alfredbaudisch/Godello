class_name TaskModel extends Model

var title : String = ""
var card_id : int = 0
var is_done : bool = false

func _init(_id : int, _card_id : int, _title : String, _is_done : bool = false).(ModelTypes.TASK, _id):
	card_id = _card_id
	title = _title
	is_done = _is_done

func set_title(_title : String):
	title = _title
	
func set_is_done(_is_done : bool):
	is_done = _is_done
