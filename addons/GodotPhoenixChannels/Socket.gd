extends Node

class_name PhoenixSocket

#
# Socket Members
#

const DEFAULT_TIMEOUT_MS := 10000
const DEFAULT_HEARTBEAT_INTERVAL_MS := 30000
const DEFAULT_BASE_ENDPOINT := "ws://localhost:4000/socket"
const DEFAULT_RECONNECT_AFTER_MS := [1000, 2000, 5000, 10000]
const TRANSPORT := "websocket"

const WRITE_MODE := WebSocketPeer.WRITE_MODE_TEXT

const TOPIC_PHOENIX := "phoenix"
const EVENT_HEARTBEAT := "heartbeat"
const EMPTY_REF := "-1"

const STATUS = {
	ok = "ok",
	error = "error",
	timeout = "timeout"
}

signal on_open(params)
signal on_error(data)
signal on_close()
signal on_connecting(is_connecting)

var _socket := WebSocketClient.new()
var _channels := []
var _settings := {} setget ,get_settings
var _is_https := false
var _endpoint_url := ""
var _last_status := -1
var _connected_at := -1
var _last_connected_at := -1
var _requested_disconnect := false
var _last_close_reason := {}

var _last_heartbeat_at := 0
var _pending_heartbeat_ref := EMPTY_REF

var _last_reconnect_try_at := -1
var _should_reconnect := false
var _reconnect_after_pos := 0

# TODO: refactor as SocketStates, just like ChannelStates
export var is_connected := false setget ,get_is_connected
export var is_connecting := false setget ,get_is_connecting

# Events / Messages
var _ref := 0

#
# Godot lifecycle for PhoenixSocket
#

func _init(endpoint, opts = {}):
	_settings = {
		heartbeat_interval = PhoenixUtils.get_key_or_default(opts, "heartbeat_interval", DEFAULT_HEARTBEAT_INTERVAL_MS),
		timeout = PhoenixUtils.get_key_or_default(opts, "timeout", DEFAULT_TIMEOUT_MS),
		reconnect_after = PhoenixUtils.get_key_or_default(opts, "reconnect_after", DEFAULT_RECONNECT_AFTER_MS),
		params = PhoenixUtils.get_key_or_default(opts, "params", {}),
	}
	
	set_endpoint(endpoint)	

func _ready():
	_socket.connect("connection_established", self, "_on_socket_connected")
	_socket.connect("connection_error", self, "_on_socket_error")
	_socket.connect("connection_closed", self, "_on_socket_closed")
	_socket.connect("data_received", self, "_on_socket_data_received")
	
	set_process(true)
	
func _process(delta):
	var status = _socket.get_connection_status()

	if status != _last_status:
		_last_status = status
	
		if status == WebSocketClient.CONNECTION_DISCONNECTED:
			is_connected = false
			_last_connected_at = _connected_at
			_connected_at = -1
		
		if status == WebSocketClient.CONNECTION_CONNECTING:
			emit_signal("on_connecting", true)
			is_connecting = true
		else:
			if is_connecting: emit_signal("on_connecting", false)
			is_connecting = false
			
	if status == WebSocketClient.CONNECTION_CONNECTED:
		var current_ticks = OS.get_ticks_msec()		
		
		if (current_ticks - _last_heartbeat_at >= _settings.heartbeat_interval) and (current_ticks - _connected_at >= _settings.heartbeat_interval):
			_heartbeat(current_ticks)
			
	if status == WebSocketClient.CONNECTION_DISCONNECTED: 
		_retry_reconnect(OS.get_ticks_msec())
		return

	_socket.poll()
	
func _enter_tree():
	get_tree().connect("node_removed", self, "_on_node_removed")
	
func _exit_tree():
	var payload = {message = "exit tree"}
	_close(true, payload)
	
	"""
	Closing the socket with _socket() leads to the chain of events that eventually call on_close,
	but then in this specific case of exiting the tree, the event is not called, because
	the tree is freed, so force call it from here.
	"""	
	emit_signal("on_close", payload)
	
#
# Public
#

func connect_socket():
	if is_connected:
		return
	
	_socket.verify_ssl = false
	
	_endpoint_url = PhoenixUtils.add_url_params(_settings.endpoint, _settings.params)
	_socket.connect_to_url(_endpoint_url)
	
func disconnect_socket():	
	_close(true, {message = "disconnect requested"})

func get_is_connected() -> bool:
	return is_connected
	
func get_is_connecting() -> bool:
	return is_connecting
	
func get_settings():
	return _settings
	
func set_endpoint(endpoint : String):
	_settings.endpoint = PhoenixUtils.add_trailing_slash(endpoint if endpoint else DEFAULT_BASE_ENDPOINT) + TRANSPORT
	_is_https = _settings.endpoint.begins_with("wss")
	
func set_params(params : Dictionary = {}):
	_settings.params = params
	
func can_push(event : String) -> bool:
	return is_connected
	
func channel(topic : String, params : Dictionary = {}, presence = null) -> PhoenixChannel:
	var channel := PhoenixChannel.new(self, topic, params, presence)
	
	_channels.push_back(channel)
	add_child(channel)
	return channel
	
func compose_message(event : String, payload := {}, topic := TOPIC_PHOENIX, ref := "", join_ref := PhoenixMessage.GLOBAL_JOIN_REF) -> PhoenixMessage:	
	if event == EVENT_HEARTBEAT:
		join_ref = PhoenixMessage.GLOBAL_JOIN_REF

	ref = ref if ref != "" else make_ref()
	topic = topic if topic else TOPIC_PHOENIX
	
	return PhoenixMessage.new(topic, event, ref, join_ref, payload)
	
func push(message : PhoenixMessage):
	var dict = message.to_dictionary()
	
	if can_push(dict.event):	
		_socket.get_peer(1).put_packet(to_json(dict).to_utf8())		
		
func make_ref() -> String:
	_ref = _ref + 1
	return str(_ref)

#
# Implementation 
#

func _trigger_channel_error(channel : PhoenixChannel, payload := {}):
	channel.raw_trigger(PhoenixChannel.CHANNEL_EVENTS.error, payload)

func _close(requested := false, reason := {}):
	if not is_connected:
		return
		
	_last_close_reason = reason
	_requested_disconnect = requested
	_socket.disconnect_from_host()	

func _reset_reconnection():
	_last_reconnect_try_at = -1
	_should_reconnect = false
	_reconnect_after_pos = 0

func _retry_reconnect(current_time):
	if _should_reconnect:
		# Just started the reconnection timer, set time as now, so the
		# first _reconnect_after_pos amount will be subtracted from now
		if _last_reconnect_try_at == -1:
			_last_reconnect_try_at = current_time
		else:
			var reconnect_after = _settings.reconnect_after[_reconnect_after_pos]
							
			if current_time - _last_reconnect_try_at >= reconnect_after:
				_last_reconnect_try_at = current_time
				
				# Move to the next reconnect time (or keep the last one)
				if _reconnect_after_pos < reconnect_after - 1 and _reconnect_after_pos < _settings.reconnect_after.size() - 1: 
					_reconnect_after_pos += 1
					
				connect_socket()
	
func _heartbeat(time):
	if get_is_connected():
		# There is still a pending heartbeat, which means it timed out
		if _pending_heartbeat_ref != EMPTY_REF:
			_close(false, {message = "heartbeat timeout"})
		else:
			_pending_heartbeat_ref = make_ref()
			push(compose_message(EVENT_HEARTBEAT, {}, TOPIC_PHOENIX, _pending_heartbeat_ref))
			_last_heartbeat_at = time
	
func _find_and_remove_channel(channel : PhoenixChannel):	
	var pos = _channels.find(channel)
	if pos != -1:
		_channels.remove(pos)
		
#
# Listeners
#

func _on_socket_connected(protocol):
	_socket.get_peer(1).set_write_mode(WRITE_MODE)
	
	_connected_at = OS.get_ticks_msec()
	_last_close_reason = {}
	_pending_heartbeat_ref = EMPTY_REF
	_last_heartbeat_at = 0
	_requested_disconnect = false
	_reset_reconnection()
	
	is_connected = true	
	emit_signal("on_open", {})
	
func _on_socket_error(reason = null):
	if not is_connected or (_connected_at == -1 and _last_connected_at != -1):
		_should_reconnect = true

	_last_close_reason = reason if reason else {message = "connection error"}
	
	emit_signal("on_error", _last_close_reason)
		
func _on_socket_closed(clean):
	if not _requested_disconnect:
		_should_reconnect = true	
	
	_last_close_reason = {message = "connection lost"} if _last_close_reason.empty() else _last_close_reason
	
	var payload = {
		was_requested = _requested_disconnect,
		will_reconnect = not _requested_disconnect,
		reason = _last_close_reason
	}	
	
	for channel in _channels:
		channel.close(payload, _should_reconnect)

	emit_signal("on_close", payload)	
	
func _on_socket_data_received(pid := 1):
	var packet = _socket.get_peer(1).get_packet()
	var json = JSON.parse(packet.get_string_from_utf8())
	
	if json.result.has("event"):
		var result = json.result
		var message = PhoenixUtils.get_message_from_dictionary(json.result)
		var ref = message.get_ref()
		
		if message.get_topic() == TOPIC_PHOENIX:
			if ref == _pending_heartbeat_ref:
				_pending_heartbeat_ref = EMPTY_REF
		else:
			for channel in _channels:
				if channel.is_member(message.get_topic(), message.get_join_ref()):
					channel.trigger(message)

func _on_node_removed(node : Node):
	var channel = node as PhoenixChannel
	if channel:
		_find_and_remove_channel(channel)
