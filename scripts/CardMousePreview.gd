class_name CardPreview
extends MarginContainer

var title_label
var drag_data

func _ready():
  title_label = get_node("CardContent/InnerPadding/HBoxContainer/Title")

func set_data(_node, _model : CardModel):
  drag_data = DragUtils.get_drag_data(_node, _model)
  set_title(_model.title)
    
func set_title(_title):
  title_label.set_text(_title)
