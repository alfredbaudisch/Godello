class_name UserModel extends Model

var first_name : String
var last_name : String
var email : String
var token : String = "" setget set_token

func _init(_id : int, _first_name : String, _last_name : String, _email : String, token : String = "").(ModelTypes.USER, _id):
	first_name = _first_name
	last_name = _last_name
	email = _email

func get_full_name():
	return first_name + " " + last_name

func set_token(value : String):
	token = value	
