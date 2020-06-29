extends Node

class_name PhoenixUtils

static func add_trailing_slash(value: String) -> String:
	return value if value.ends_with("/") else value + "/"

static func add_url_params(url: String, params: Dictionary = {}) -> String:
	if not params or (params and params.size() == 0):
		return url
	
	if "?" in url:
		if not url.ends_with("&"):
			url += "&"
	else:
		url += "?"
	
	var pos = 0
	for key in params:
		if pos > 0: url += "&"
		url += key + "=" + str(params[key]).percent_encode()
		pos += 1
		
	return url
	
static func get_key_or_default(values : Dictionary, key : String, default):
	if values.has(key):
		return values[key]
			
	return default
	
static func get_message_from_dictionary(from : Dictionary = {}) -> PhoenixMessage:
	var join_ref = from.join_ref if from.has("join_ref") else PhoenixMessage.GLOBAL_JOIN_REF
	var ref = from.ref if from.ref else PhoenixMessage.NO_REPLY_REF	
	return PhoenixMessage.new(from.topic, from.event, ref, join_ref, from.payload)
	
static func map(function: FuncRef, array: Array) -> Array:
	var o_array := []	
	for value in array:
		o_array.append(function.call_func(value))
		
	return o_array
	
static func filter(function: FuncRef, array: Array) -> Array:
	var filtered_array := []

	for candidate_value in array:
		if function.call_func(candidate_value):
			filtered_array.append(candidate_value)

	return filtered_array
