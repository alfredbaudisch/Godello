extends Node

var adapter : PhoenixBackend
var loading_overlay

# Any scene can connect to those signals
signal on_backend_requesting(action, is_requesting, is_global)
signal on_backend_response(action, is_success, body)
signal on_backend_error(action, should_try_again, result)

enum BackendAction {IDLE, SIGN_UP, LOGIN}
var last_action : int = BackendAction.IDLE setget ,get_action

func _ready():
	loading_overlay = load("res://scenes/LoadingOverlay.tscn").instance()
	get_parent().call_deferred("add_child", loading_overlay)
	loading_overlay.set_visible(false)
	
	adapter = PhoenixBackend.new()
	add_child(adapter)
	
	# Low level signals, to be used exclusively between the Backend manager and the adapter
	adapter.connect("on_backend_adapter_requesting", self, "_on_backend_adapter_requesting")
	adapter.connect("on_backend_adapter_response", self, "_on_backend_adapter_response")
	adapter.connect("on_backend_adapter_error", self, "_on_backend_adapter_error")

#
# Public Interface
#

func sign_up(user_details : Dictionary):
	last_action = BackendAction.SIGN_UP
	adapter.sign_up(user_details)
	
func login():
	last_action = BackendAction.LOGIN
	
func get_action() -> int:
	return last_action

#
# Adapter Communication
#

func _on_backend_adapter_requesting(is_requesting, is_global):
	emit_signal("on_backend_requesting", last_action, is_requesting, is_global)
	
	if is_global:
		loading_overlay.set_visible(is_requesting)

func _on_backend_adapter_response(is_success, body):	
	# For now, handle and display errors from here
	if not is_success and BackendUtils.is_response_generic_error(body):
		var first_error = BackendUtils.get_first_response_error(body)
		SceneUtils.create_single_error_popup(first_error.details, null, get_parent())
		
	emit_signal("on_backend_response", last_action, is_success, body)
	print("_on_backend_adapter_response", ", is_success: ", is_success, ", body: ", body)
	
func _on_backend_adapter_error(should_try_again, result):	
	SceneUtils.create_single_error_popup("An error has occurred. Try again.", null, get_parent())
	emit_signal("on_backend_error", last_action, should_try_again, result)
	print("_on_backend_adapter_error", ", should_try_again: ", should_try_again, ", result: ", result)
