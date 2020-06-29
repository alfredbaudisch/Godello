class_name ErrorModel extends Object

const REASON_DATA_ERROR := "data_error"

var reason : String setget ,get_reason
var details setget ,get_details

func _init(_reason, _details):
	reason = _reason
	details = _details
	
func is_data_error() -> bool:
	return reason == REASON_DATA_ERROR
	
func get_reason() -> String:
	return reason

func get_details():
	return details
