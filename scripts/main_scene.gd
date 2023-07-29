extends ColorRect


const BoardsScene := preload("res://scenes/boards.tscn")
const BoardScene := preload("res://scenes/board.tscn")

var route : int
var route_scene : Node

onready var content_container := $ContentContainer
onready var top_bar := $ContentContainer/TopBar
onready var user_button := $ContentContainer/TopBar/HBoxContainer/UserButton


func _ready():
# warning-ignore:return_value_discarded
	SceneUtils.connect("change_route_requested", self, "_on_change_scene_requested")
	SceneUtils.go_to_boards()

	call_deferred("_set_user")


func _set_user():
	user_button.set_text(DataRepository.active_user.get_full_name())


func _on_change_scene_requested(next_route : int):
	_go_ro_route(next_route)


func _go_ro_route(next_route : int):
	if route_scene:
		route_scene.queue_free()

	route_scene = _get_scene_for_route(next_route).instance()
	content_container.add_child(route_scene)
	route = next_route


func _get_scene_for_route(next_route : int) -> PackedScene:
	match next_route:
		SceneUtils.Routes.BOARD:
			return BoardScene
		_:
			return BoardsScene


func _on_HomeButton_pressed():
	SceneUtils.go_to_boards()


func _on_LogOutButton_pressed():
	Events.emit_signal("user_logged_out")
	SceneUtils.go_to_login()
