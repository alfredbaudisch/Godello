extends Button

export(String) var expand_to
var normal_text

func _ready():
	normal_text = get_text()

func _on_BoardOwnerButton_gui_input(event):
	if event is InputEventMouseMotion:
		set_text(expand_to)
		$Timer.start()		

func _on_Timer_timeout():
	if not Utils.is_mouse_inside_control(self):
		set_text(normal_text)
		$Timer.stop()
