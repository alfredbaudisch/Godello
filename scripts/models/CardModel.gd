class_name CardModel extends Model

var title : String = ""
var description : String = "" setget set_description
var list_id : String = ""
var tasks : Array = []
var is_archived := false

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

func add_task(task):
	tasks.push_back(task)
	_notify_updated()
	
func update_task(task, _title, _is_done):
	task.set_title(_title)
	task.set_is_done(_is_done)
	_notify_updated()

func delete_task(task):
	var task_idx = tasks.find(task)	
	if task_idx != -1:
		tasks.remove(task_idx)
		_notify_updated()

func archive():
	is_archived = true
	_notify_updated()
	
func unarchive():
	is_archived = false
	_notify_updated()

func _notify_updated():
	DataRepository.update_card(self)

func _to_string():
	return to_json({
		"id": id,
		"title": title,
		"description": description,
		"list_id": list_id
	})
