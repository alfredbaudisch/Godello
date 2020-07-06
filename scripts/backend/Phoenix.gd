class_name PhoenixBackend extends Node

var http

const BASE_URL := "http://127.0.0.1:4000"
const WS_BASE_URL := "ws://127.0.0.1:4000/socket"

# CHANNEL
const USER_CHANNEL := "user:"
const BOARD_CHANNEL := "board:"

var socket : PhoenixSocket
var user_channel : PhoenixChannel
var board_channel : PhoenixChannel
var presence : PhoenixPresence
var token_connected : String = ""
var user_connected : UserModel

# HTTP
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
	
#
# Channel public interface
#

func connect_realtime(user : UserModel):
	if socket:		
		if socket.get_is_connected():
			# The same user is already connected, ignore
			if token_connected != "" and user.token == token_connected:
				pass
			# Different user, disconnect and re-connect with the new token
			else:
				socket.disconnect_socket()				
	else:
		socket = PhoenixSocket.new(WS_BASE_URL)
		
		socket.connect("on_open", self, "_on_Socket_open")
		socket.connect("on_close", self, "_on_Socket_close")
		socket.connect("on_error", self, "_on_Socket_error")
		socket.connect("on_connecting", self, "_on_Socket_connecting")
		
		call_deferred("add_child", socket, true)

	# Remember connection details
	user_connected = user
	token_connected = user_connected.get_token()

	# Connect!
	socket.set_params({token = user.get_token()})
	socket.connect_socket()
	
func disconnect_realtime():
	if socket and socket.get_is_connected():
		socket.disconnect_socket()
		socket.queue_free()
		
func join_user_channel():
	if not socket:
		_emit_error("join_user_channel", false, "No socket, can't join user channel")
	
	else:
		if not user_channel:			
			user_channel = socket.channel(_get_user_connected_topic())
			
			user_channel.connect("on_event", self, "_on_UserChannel_event")
			user_channel.connect("on_join_result", self, "_on_UserChannel_join_result")
			user_channel.connect("on_error", self, "_on_UserChannel_error")
			user_channel.connect("on_close", self, "_on_UserChannel_close")
				
		if user_channel.is_joined():
			user_channel.leave()
			
		if user_channel.is_closed():
			user_channel.set_topic(_get_user_connected_topic())
			user_channel.join()
	
#
# HTTP public interface
#
	
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

#
# HTTP helpers
#

func _can_perform_http_request() -> bool:
	return current_http_action == AdapterHttpAction.IDLE
	
func _http_post(url, body):
	var result = http.json_post_request(url, body)
	
	if result != OK:
		_emit_error("HTTP REQUEST ERROR", true, result)

#
# HTTP signals
#

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
		
#
# Channel helpers
#

func _get_user_connected_topic():
	return USER_CHANNEL + str(user_connected.id)
		
#
# PhoenixSocket events
#

func _on_Socket_open(payload):	
	_emit_requesting(false)
	print("_on_Socket_open: " + str(payload))	
	
func _on_Socket_close(payload):
	print("_on_Socket_close: " + str(payload))
	
func _on_Socket_error(payload):
	print("_on_Socket_error: " + str(payload))

func _on_Socket_connecting(is_connecting):
	if is_connecting:
		_emit_requesting(true)
		
	print("_on_Socket_connecting: " + str(is_connecting))	

#
# Signal helpers
#

func _emit_error(error_location : String, should_try_again := true, result = null, is_global := true):
	_emit_requesting(false, is_global)
	emit_signal("on_backend_adapter_error", should_try_again, result)
	print("ERROR: " + error_location, "should_try_again: ", should_try_again, "result: ", result)
	
func _emit_response(is_success, body, is_global := true):
	_emit_requesting(false, is_global)
	emit_signal("on_backend_adapter_response", is_success, body)

func _emit_requesting(is_requesting, is_global := true):
	emit_signal("on_backend_adapter_requesting", is_requesting, is_global)
