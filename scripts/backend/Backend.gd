class_name Backend extends Node

var loading_overlay

enum Action {IDLE, SIGN_UP, LOG_IN}
var last_action : int = Action.IDLE setget ,get_action

func _ready():
	loading_overlay = load("res://scenes/LoadingOverlay.tscn").instance()
	get_node("/root").call_deferred("add_child", loading_overlay)
	loading_overlay.set_visible(false)

#
# Public Interface
#

func connect_realtime(user : UserModel):
	pass
	
func disconnect_realtime():
	pass

func sign_up(user_details : Dictionary):
	last_action = Action.SIGN_UP
	
func log_in(credentials : Dictionary):
	last_action = Action.LOG_IN

func get_action() -> int:
	return last_action

#
# Helpers
#

func _set_idle():
	_set_action(Action.IDLE)

func _set_action(action : int):
	last_action = action

func _can_perform_http_request() -> bool:
	return last_action == Action.IDLE

#
# Signal helpers
#

func _emit_error(error_location : String, should_try_again := true, result = null, is_global := true):
	_emit_requesting(false, is_global)
	
	SceneUtils.create_single_error_popup("An error has occurred. Try again.", null, get_parent())
	
	Events.emit_signal("backend_error", last_action, should_try_again, result)
	_set_idle()
	print("ERROR: " + error_location, "should_try_again: ", should_try_again, "result: ", result)
	
func _emit_response(is_success, body, is_global := true):
	_emit_requesting(false, is_global)
	
	# For now, handle and display errors from here
	if not is_success and BackendUtils.is_response_generic_error(body):
		var first_error = BackendUtils.get_first_response_error(body)
		SceneUtils.create_single_error_popup(first_error.details, null, get_node("/root"))
		
	Events.emit_signal("backend_response", last_action, is_success, body)
	_set_idle()

func _emit_requesting(is_requesting, is_global := true):
	Events.emit_signal("backend_requesting", last_action, is_requesting, is_global)
	
	if is_global:
		# Move overlay to cover everything
		if is_requesting:
			get_node("/root").move_child(loading_overlay, get_node("/root").get_child_count() - 1)
			
		loading_overlay.set_visible(is_requesting)
