class_name PhoenixBackend extends Backend

var http

const BASE_URL := "http://127.0.0.1:4000"
const WS_BASE_URL := "ws://127.0.0.1:4000/socket"

#
# CHANNEL
#
const USER_CHANNEL := "user:"
const BOARD_CHANNEL := "board:"
const USER_EVENTS := {
	create_board = "create_board",
	get_boards = "get_boards"
}

var socket : PhoenixSocket
var user_channel : PhoenixChannel
var board_channel : PhoenixChannel
var board_presence : PhoenixPresence

# Channel state
var token_connected : String = ""
var user_connected : UserModel
var board_connected : BoardModel

#
# HTTP
#
const ENDPONT_SIGN_UP := BASE_URL + "/users"
const ENDPONT_LOG_IN := BASE_URL + "/users/login"
const DATA_ERROR_CODE := 400
const SUCCESS_CODE := 200
const SERVER_ERROR_CODE := 500

func _enter_tree():
	http = RESTBackend.new()
	.add_child(http)
	
	http.connect("request_completed", self, "_on_http_request_completed")
	
#
# User channel public interface
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
		
		socket.connect("on_open", self, "_on_socket_open")
		socket.connect("on_close", self, "_on_socket_close")
		socket.connect("on_error", self, "_on_socket_error")
		socket.connect("on_connecting", self, "_on_socket_connecting")
		
		.call_deferred("add_child", socket, true)
		
	.connect_realtime(user)

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
		._emit_error("join_user_channel", false, "No socket, can't join user channel")
		
	elif not user_connected:
		._emit_error("join_user_channel", false, "No user, can't join user channel")
	
	else:
		if not user_channel:			
			user_channel = socket.channel(_get_user_connected_topic())
			
			user_channel.connect("on_event", self, "_on_user_channel_event")
			user_channel.connect("on_join_result", self, "_on_user_channel_join_result")
			user_channel.connect("on_error", self, "_on_user_channel_error")
			user_channel.connect("on_close", self, "_on_user_channel_close")
				
		if user_channel.is_joined():
			user_channel.leave()
			
		if user_channel.is_closed():
			._emit_requesting(true)			
			user_channel.set_topic(_get_user_connected_topic())
			user_channel.join()
			
func get_boards():
	_push_user_channel(USER_EVENTS.get_boards)
		
func create_board(details : Dictionary):
	_push_user_channel(USER_EVENTS.create_board, details)

#
# Board channel public interface
#

func join_board_channel(board : BoardModel):
	pass

#
# HTTP public interface
#
	
func sign_up(user_details : Dictionary):
	if not ._can_perform_http_request():
		return
		
	.sign_up(user_details)
	._emit_requesting(true)
	_http_post(ENDPONT_SIGN_UP, user_details)
	
func log_in(credentials : Dictionary):
	if not ._can_perform_http_request():
		return
	
	.log_in(credentials)
	._emit_requesting(true)
	_http_post(ENDPONT_LOG_IN, credentials)	

#
# HTTP helpers
#
	
func _http_post(url, body):
	var result = http.json_post_request(url, body)
	
	if result != OK:
		._emit_error("HTTP REQUEST ERROR", true, result)

#
# HTTP signals
#

func _on_http_request_completed(result, response_code, headers, body):	
	if result == HTTPRequest.RESULT_SUCCESS:
		var response = http.parse_json_response(body)
		
		match response_code:
			SUCCESS_CODE:
				._emit_response(true, response)
			DATA_ERROR_CODE:
				._emit_response(false, response)
			SERVER_ERROR_CODE, _:
				._emit_error("SERVER ERROR", true, response)
			
	else:
		._emit_error("HTTP RESULT ERROR", true, body)
		
#
# Channel helpers
#

func _get_user_connected_topic():
	return USER_CHANNEL + str(user_connected.id)
	
func _can_push_user_channel():
	return user_channel.is_joined()
	
func _push_user_channel(event, payload := {}):
	if not _can_push_user_channel():
		._emit_error(event, false, "Can't push user event: " + event + ", because the user channel is not joined")

	else:		
		if user_channel.push(event, payload):
			._emit_requesting(true, event == USER_EVENTS.get_boards)
			return true
	
	._emit_error(event, false, "Could not push user event: " + event)
	return false
		
func _push_board_channel(event, payload := {}):
	if board_channel.push(event, payload):
		._emit_requesting(true, false)

func _get_action_for_event(event : String) -> int:
	match(event):
		USER_EVENTS.get_boards:
			return Action.GET_BOARDS
		USER_EVENTS.create_board:
			return Action.CREATE_BOARD		
		
	return Action.ERROR
	
#
# PhoenixSocket events
#

func _on_socket_open(payload):	
	print("_on_socket_open: " + str(payload))	
	join_user_channel()
	
func _on_socket_close(payload):
	print("_on_socket_close: " + str(payload))
	
func _on_socket_error(payload):
	print("_on_socket_error: " + str(payload))

func _on_socket_connecting(is_connecting):
	if is_connecting:
		._emit_requesting(true)
		
	print("_on_socket_connecting: " + str(is_connecting))	
	
#
# User PhoenixChannel events
#

func _on_user_channel_event(event, payload, status):
	print("_on_user_channel_event:  " + event + ", status: " + status + ", payload: " + str(payload))
	
	# Get action separately, because GET_BOARDS is a global action
	var action = _get_action_for_event(event)
	._emit_response(status == PhoenixChannel.STATUS.ok, payload, action, action == Backend.Action.GET_BOARDS)
	
func _on_user_channel_join_result(status, result):
	._emit_user_channel_joined(status == PhoenixChannel.STATUS.ok, result)
	
func _on_user_channel_error(error):
	print("_on_user_channel_error: " + str(error))
	
func _on_user_channel_close(closed):	
	print("_on_user_channel_close: " + str(closed))
	._emit_user_channel_left()
