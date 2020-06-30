class_name BackendUtils extends Object

const REASON_DATA_ERROR := "data_error"

static func post_request():
	pass
	
static func is_response_data_error(result) -> bool:
	return result and result.errors and result.errors.reason == REASON_DATA_ERROR
	
static func is_response_generic_error(result) -> bool:
	return result and result.errors and typeof(result.errors) == TYPE_DICTIONARY
	
static func get_first_response_error(result : Dictionary) -> Dictionary:
	match typeof(result.errors.details):
		TYPE_STRING:
			return {key = result.errors.reason, details = result.errors.details}
		TYPE_DICTIONARY:
			var key = result.errors.details.keys()[0]			
			var details
			
			if typeof(result.errors.details[key]) == TYPE_ARRAY:
				details = key.capitalize() + " " + result.errors.details[key][0]
			else:
				details = result.errors.details[key]
			
			return {key = key, details = details}
		_:
			assert("result has invalid type")
			return {}
