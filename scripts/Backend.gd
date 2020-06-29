extends Node

var adapter : PhoenixBackend

signal on_backend_response(is_success, body)

func _ready():
	adapter = PhoenixBackend.new()
	add_child(adapter)
	
	adapter.connect("on_backend_adapter_response", self, "_on_backend_adapter_response")
	adapter.connect("on_backend_adapter_error", self, "_on_backend_adapter_error")
	
	sign_up({
		first_name = "foo"		
	});
	
func sign_up(user_details : Dictionary):
	adapter.sign_up(user_details)
	
func login():
	pass

func _on_backend_adapter_response(is_success, body):
	print("_on_backend_adapter_response", ", is_success: ", is_success, ", body: ", body)
	
func _on_backend_adapter_error(should_try_again, result):
	print("_on_backend_adapter_error", ", should_try_again: ", should_try_again, ", result: ", result)
