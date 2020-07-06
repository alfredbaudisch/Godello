extends Node

var _backend : Backend setget ,backend

enum BackendType {MOCKED, PHOENIX}
var backend_type = BackendType.PHOENIX

func _ready():
	_create_backend()	
	
func backend() -> Backend:
	return _backend

func _create_backend():
	match(backend_type):
		BackendType.MOCKED:
			assert("not implemented")
		BackendType.PHOENIX:
			_backend = PhoenixBackend.new()
			
	add_child(_backend)
