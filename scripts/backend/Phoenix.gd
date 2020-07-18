class_name PhoenixBackend extends Backend

const BASE_URL := "http://127.0.0.1:4000"
const WS_BASE_URL := "ws://127.0.0.1:4000/socket"

#
# CHANNEL
#
const USER_CHANNEL := "user:"
const USER_EVENTS := {
	create_board = "create_board",	
	get_boards = "get_boards",
	board_created = "board_created"
}

const BOARD_CHANNEL := "board:"
const BOARD_EVENTS := {
	get_board = "get_board",
	update_board = "update_board",
	board_updated = "board_updated",
	delete_board = "delete_board",
	board_deleted = "board_deleted"
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

var http

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
		
func create_board(name : String):
	_push_user_channel(USER_EVENTS.create_board, {name = name})

#
# Board channel public interface
#

func join_board_channel(board : BoardModel):
	if not socket:
		._emit_error("join_user_channel", false, "No socket, can't join user channel")

	else:
		if not board_channel:			
			if not board_presence:
				board_presence = PhoenixPresence.new()	

				board_presence.connect("on_join", self, "_on_board_presence_join")
				board_presence.connect("on_leave", self, "_on_board_presence_leave")

			board_channel = socket.channel(_get_board_topic(board), {}, board_presence)

			board_channel.connect("on_event", self, "_on_board_channel_event")
			board_channel.connect("on_join_result", self, "_on_board_channel_join_result")
			board_channel.connect("on_error", self, "_on_board_channel_error")
			board_channel.connect("on_close", self, "_on_board_channel_close")
				
		if board_channel.is_joined():
			board_channel.leave()
			
		if board_channel.is_closed():
			._emit_requesting(true)
			board_channel.set_topic(_get_board_topic(board))
			board_channel.join()

func leave_board_channel():
	if board_channel and board_channel.is_joined():
		board_channel.leave()
		
func update_board(name : String):
	_push_board_channel(BOARD_EVENTS.update_board, {name = name})
	
func delete_board(board : BoardModel):
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

func _get_user_connected_topic() -> String:
	return USER_CHANNEL + str(user_connected.id)

func _get_board_topic(board : BoardModel) -> String:
	return BOARD_CHANNEL + str(board.id)
	
func _can_push_user_channel():
	return user_channel.is_joined()
	
func _can_push_board_channel():
	return board_channel.is_joined()
	
func _push_user_channel(event, payload := {}):
	if not _can_push_user_channel():
		._emit_error(event, false, "Can't push user event: " + event + ", because the user channel is not joined")

	else:		
		if user_channel.push(event, payload):
			._emit_requesting(true, _is_event_global(event))
			return true
	
	._emit_error(event, false, "Could not push user event: " + event)
	return false
		
func _push_board_channel(event, payload := {}):
	if not _can_push_board_channel():
		._emit_error(event, false, "Can't push board event: " + event + ", because the board channel is not joined")
		
	if board_channel.push(event, payload):
		._emit_requesting(true, _is_event_global(event))		
		return true
	else:
		._emit_error(event, false, "Could not push board event: " + event)
		
	return false

func _get_event_for_channel_event(event : String) -> int:
	match(event):
		USER_EVENTS.get_boards:
			return Event.GET_BOARDS
		USER_EVENTS.create_board:
			return Event.BOARD_CREATED
		USER_EVENTS.board_created:
			return Event.BOARD_CREATED
			
		BOARD_EVENTS.get_board:
			return Event.GET_BOARD
		BOARD_EVENTS.update_board:
			return Event.BOARD_UPDATED
		BOARD_EVENTS.board_updated:
			return Event.BOARD_UPDATED
		
	return Event.ERROR

func _is_event_global(event : String) -> bool:
	return event in [
		USER_EVENTS.get_boards,
		USER_EVENTS.create_board,
		BOARD_EVENTS.update_board,
		BOARD_EVENTS.delete_board
	]
	
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
# Board PhoenixChannel events
#

func _on_board_channel_event(event, payload, status):
	print("_on_board_channel_event:  " + event + ", status: " + status + ", payload: " + str(payload))	

	if event == PhoenixChannel.PRESENCE_EVENTS.diff:
		board_presence.sync_diff(payload)		
	elif event == PhoenixChannel.PRESENCE_EVENTS.state:
		board_presence.sync_state(payload)
	else:
		var emit_event = _get_event_for_channel_event(event)
		._emit_response(status == PhoenixChannel.STATUS.ok, payload, emit_event, _is_event_global(event))
	
func _on_board_channel_join_result(status, result):
	var is_success = status == PhoenixChannel.STATUS.ok	
	._emit_channel_joined("board_channel", is_success, result)
	
	if is_success:
		._emit_response(is_success, result["board"], _get_event_for_channel_event(BOARD_EVENTS.get_board))
	
func _on_board_channel_error(error):
	print("_on_board_channel_error: " + str(error))
	
func _on_board_channel_close(closed):	
	print("_on_board_channel_close: " + str(closed))
	._emit_channel_left("board_channel")

func _on_board_presence_join(joins):
	print("_on_board_presence_join: " + str(joins))
	
func _on_board_presence_leave(leaves):
	print("_on_board_presence_leave: " + str(leaves))

	
#
# User PhoenixChannel events
#

func _on_user_channel_event(event, payload, status):
	print("_on_user_channel_event:  " + event + ", status: " + status + ", payload: " + str(payload))
	
	var emit_event = _get_event_for_channel_event(event)	
	if emit_event == Backend.Event.GET_BOARDS:
		payload = payload["boards"]	
	._emit_response(status == PhoenixChannel.STATUS.ok, payload, emit_event, _is_event_global(event))
	
func _on_user_channel_join_result(status, result):
	._emit_channel_joined("user_channel", status == PhoenixChannel.STATUS.ok, result)
	
func _on_user_channel_error(error):
	print("_on_user_channel_error: " + str(error))
	
	if user_channel.is_joined() and (not error or (typeof(error) == TYPE_DICTIONARY and error.empty())):
		SceneUtils.create_single_error_popup("An error has occurred, try again.", null, get_node("/root"))
	elif not user_channel.is_joined():
		print("_on_user_channel_error: error when trying to join the channel")
	
func _on_user_channel_close(closed):	
	print("_on_user_channel_close: " + str(closed))
	._emit_channel_left("user_channel")
