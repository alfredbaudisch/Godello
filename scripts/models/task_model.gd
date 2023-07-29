class_name TaskModel extends Model


export(String) var title = ""
export(String) var card_id = ""
export(bool) var is_done = false


# Needs default values to be loaded as custom resource
func _init(
	_id : String = "",
	_card_id : String = "",
	_title : String = "",
	_is_done : bool = false
).(ModelTypes.TASK, _id):
	card_id = _card_id
	title = _title
	is_done = _is_done


func set_title(_title : String):
	title = _title


func set_is_done(_is_done : bool):
	is_done = _is_done
