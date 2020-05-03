class_name ListPreview
extends PanelContainer

var title_label
var model : ListModel

func _ready():
	title_label = get_node("Panel/MarginContainer/VerticalContent/ListNameLabel")

func set_data(_data : ListModel):
	model = _data
	set_title(_data.title)
		
func set_title(_title):
	title_label.set_text(_title)