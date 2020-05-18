class_name BoardModel extends Model

var title : String = ""

func _init(_id : String, _title : String = "").(ModelTypes.BOARD, _id):
	title = _title
	
func _to_string():
	return to_json({
		"id": id,
		"title": title
	})
