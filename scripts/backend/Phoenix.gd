class_name PhoenixBackend extends Node

var http

const BASE_URL := "http://127.0.0.1:4000"
const ENDPONT_SIGN_UP := BASE_URL + "/users"
const ENDPONT_LOG_IN := BASE_URL + "/users/login"

const DATA_ERROR_CODE := 400
const SUCCESS_CODE := 200
const SERVER_ERROR_CODE := 500

enum AdapterHttpAction {IDLE, SIGN_UP, LOG_IN}
var current_http_action : int = AdapterHttpAction.IDLE

signal on_backend_adapter_requesting(is_requesting, is_global)
signal on_backend_adapter_response(is_success, body)
signal on_backend_adapter_error(should_try_again, result)

func _enter_tree():
	http = RESTBackend.new()
	add_child(http)
	
	http.connect("request_completed", self, "_on_http_request_completed")
	
func sign_up(user_details : Dictionary):
	if not _can_perform_http_request():
		return
		
	current_http_action = AdapterHttpAction.SIGN_UP
	_emit_requesting(true, true)
	_http_post(ENDPONT_SIGN_UP, user_details)
	
func log_in(credentials : Dictionary):
	if not _can_perform_http_request():
		return
	
	current_http_action = AdapterHttpAction.LOG_IN	
	_emit_requesting(true, true)
	_http_post(ENDPONT_LOG_IN, credentials)	
	
func _can_perform_http_request() -> bool:
	return current_http_action == AdapterHttpAction.IDLE
	
func _http_post(url, body):
	var result = http.json_post_request(url, body)
	
	if result != OK:
		_emit_error("HTTP REQUEST ERROR", true, result)

func _on_http_request_completed(result, response_code, headers, body):
	current_http_action = AdapterHttpAction.IDLE
	
	if result == HTTPRequest.RESULT_SUCCESS:
		var response = http.parse_json_response(body)
		
		match response_code:
			SUCCESS_CODE:
				_emit_response(true, response)
			DATA_ERROR_CODE:
				_emit_response(false, response)
			SERVER_ERROR_CODE, _:
				_emit_error("SERVER ERROR", true, response)
			
	else:
		_emit_error("HTTP RESULT ERROR", true, body)

func _emit_error(error_location : String, should_try_again := true, result = null, is_http := true):
	_emit_requesting(false, is_http)
	emit_signal("on_backend_adapter_error", should_try_again, result)
	print("PhoenixBackend.ERROR: " + error_location, "should_try_again: ", should_try_again, "result: ", result)
	
func _emit_response(is_success, body, is_http := true):
	_emit_requesting(false, is_http)
	emit_signal("on_backend_adapter_response", is_success, body)

func _emit_requesting(is_requesting, is_http := true):
	emit_signal("on_backend_adapter_requesting", is_requesting, is_http)
