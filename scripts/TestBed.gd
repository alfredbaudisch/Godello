extends Panel

onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	var this_size = get_size()
	var inner_size = label.get_size()
	
	if inner_size.y > this_size.y:
		fit_to_children()
		
func fit_to_children():
	pass
