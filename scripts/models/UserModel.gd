class_name UserModel extends Model

var first_name : String
var last_name : String
var email : String
var token : String = "" setget set_token, get_token

func _init(_id : int, _first_name : String, _last_name : String, _email : String, _token : String = "").(ModelTypes.USER, _id):
	first_name = _first_name
	last_name = _last_name
	email = _email
	token = _token

func get_full_name():
	return first_name + " " + last_name

func set_token(value : String):
	token = value

func get_token() -> String:
	return token

func to_string():
	return to_json({
		id = id,
		first_name = first_name,
		last_name = last_name,
		email = email,
		token = token
	})
