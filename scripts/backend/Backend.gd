class_name Backend extends Node

var loading_overlay

enum Event {
	ERROR,
	IDLE,
	
	# HTTP
	SIGN_UP,
	LOG_IN,
	
	# User channel
	CONNECT_REALTIME,
	GET_BOARDS,
	CREATE_BOARD,
	BOARD_CREATED,
	
	# Board channel
	JOIN_BOARD_CHANNEL,
	GET_BOARD,
	EDIT_BOARD,
	BOARD_EDITED,
	DELETE_BOARD,
	BOARD_DELETED
}

var last_event : int = Event.IDLE setget ,get_event
var pending_local_requests : int = 0

func _ready():
	loading_overlay = load("res://scenes/LoadingOverlay.tscn").instance()
	get_node("/root").call_deferred("add_child", loading_overlay)
	loading_overlay.set_visible(false)

#
# Public Interface
#

func connect_realtime(user : UserModel):
	last_event = Event.CONNECT_REALTIME
	
func disconnect_realtime():
	pass

func sign_up(user_details : Dictionary):
	last_event = Event.SIGN_UP
	
func log_in(credentials : Dictionary):
	last_event = Event.LOG_IN
	
func create_board(name : String):
	last_event = Event.CREATE_BOARD
	
func get_boards():
	last_event = Event.GET_BOARDS
	
func join_board_channel(board : BoardModel):
	pass
	
func leave_board_channel():
	pass
	
func edit_board(board : BoardModel):
	pass
	
func delete_board(board : BoardModel):
	pass

#
# Helpers
#

func get_event() -> int:
	return last_event

func _set_idle():
	_set_event(Event.IDLE)

func _set_event(event : int):
	last_event = event

func _can_perform_http_request() -> bool:
	return last_event == Event.IDLE

#
# Signal helpers
#

func _emit_error(error_location : String, should_try_again := true, result = null,
	 is_global := true, message := "An error has occurred. Try again."):
	_emit_requesting(false, is_global)
	
	var error_message = result if result and typeof(result) == TYPE_STRING else message
	SceneUtils.create_single_error_popup(error_message, null, get_parent())
	
	Events.emit_signal("backend_error", last_event, should_try_again, result)
	_set_idle()
	
	print("BACKEND ERROR: " + error_location, "should_try_again: ", should_try_again, "result: ", result)
	
func _emit_response(is_success : bool, body, event : int = Event.IDLE, is_global := true):
	_emit_requesting(false, is_global)
	
	# For now, handle and display errors from here
	if not is_success and BackendUtils.is_response_generic_error(body):
		var first_error = BackendUtils.get_first_response_error(body)
		SceneUtils.create_single_error_popup(first_error.details, null, get_node("/root"))
	
	var emit_event = last_event if event == Event.IDLE else event
	Events.emit_signal("backend_response", emit_event, is_success, body)
	_set_idle()

func _emit_requesting(is_requesting, is_global := true):
	# Local/async requests: count amount of requests
	if not is_global:
		if is_requesting:
			pending_local_requests += 1
		else:		
			pending_local_requests -= 1
			pending_local_requests = max(pending_local_requests, 0)
			
			# If there are still pending local requests, do not emit/do not hide loading indicators
			if pending_local_requests > 0:
				return
	
	Events.emit_signal("backend_requesting", last_event, is_requesting, is_global)
	
	if is_global:
		# Move overlay to cover everything
		if is_requesting:
			get_node("/root").move_child(loading_overlay, get_node("/root").get_child_count() - 1)
			
		loading_overlay.set_visible(is_requesting)
		
func _emit_channel_joined(name : String, is_success : bool, result):
	_emit_requesting(false)
	
	if is_success:
		Events.emit_signal(name + "_joined")
	else:
		_emit_error("join_" + name, false, "Could not join " + name)

	_set_idle()
	
	print("_on_" + name + "_join_result: " + str(is_success) + ", " + str(result))

func _emit_channel_left(name : String):	
	Events.emit_signal(name + "_left")
	print("_on_" + name + "_left")
