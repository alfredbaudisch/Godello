extends Node

class_name PhoenixMessage

const NO_REPLY_REF := ""
const GLOBAL_JOIN_REF := ""

var _message : Dictionary = {} setget ,to_dictionary

func _init(topic : String, event : String, ref : String = NO_REPLY_REF, join_ref : String = GLOBAL_JOIN_REF, payload : Dictionary = {}):
	var final_join_ref = join_ref if join_ref != GLOBAL_JOIN_REF else null
	var final_ref = ref if ref != NO_REPLY_REF else null
	
	_message = {
		topic = topic,
		event = event,
		payload = payload,
		ref = final_ref,
		join_ref = final_join_ref
	}

func get_topic() -> String: return _message.topic
func get_event() -> String: return _message.event
func get_payload() -> Dictionary: return _message.payload
func get_ref() -> String: return _message.ref
func get_join_ref() -> String: return _message.join_ref

func get_response():
	if _message.payload.has("response"):
		return _message.payload.response
		
	return _message.payload

func to_dictionary() -> Dictionary:
	return _message
