extends PanelContainer


const StyleDragged := preload("res://assets/style_panel_list_dragged.tres")
const ListDragPreview := preload("res://scenes/list_mouse_preview.tscn")
const CardScene := preload("res://scenes/card.tscn")

var is_receiving_drag_data := false
var model : ListModel setget set_model, get_model
var is_dragged := false setget set_is_dragged
var is_any_data_dragged := false

onready var list_content := $MarginContainer
onready var card_container := $MarginContainer/VerticalContent/CardContainerScroll/CardContainer
onready var card_container_scroll := $MarginContainer/VerticalContent/CardContainerScroll
onready var title_label := $MarginContainer/VerticalContent/TitleContainer/Title
onready var add_card_button := $MarginContainer/VerticalContent/AddCardButton


func _ready():
	set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

# warning-ignore:return_value_discarded
	Events.connect("card_dragged", self, "_on_card_dragged")
# warning-ignore:return_value_discarded
	Events.connect("card_dropped", self, "_on_card_dropped")
# warning-ignore:return_value_discarded
	Events.connect("list_dragged", self, "_on_list_dragged")
# warning-ignore:return_value_discarded
	Events.connect("list_dropped", self, "_on_list_dropped")

# warning-ignore:return_value_discarded
	DataRepository.connect("card_created", self, "_on_card_created")
# warning-ignore:return_value_discarded
	DataRepository.connect("list_updated", self, "_on_list_updated")
# warning-ignore:return_value_discarded
	DataRepository.connect("list_deleted", self, "_on_list_deleted")


func _unhandled_input(event):
	# Since Godot doesn't handle drops in failed places,
	# we have to handle this by ourselves
	if event is InputEventMouseButton and is_dragged:
		set_is_dragged(false)


func set_model(_model : ListModel, shallow_update := false):
	model = _model
	set_name("List_" + model.id)

	title_label.set_text(model.title)

	if not shallow_update:
		for card in model.cards:
			add_card(card)


func get_model():
	return model


func set_is_dragged(value := true):
	if value:
		set("custom_styles/panel", StyleDragged)
	else:
		set("custom_styles/panel", null)

	list_content.set_visible(not value)
	is_dragged = value


func add_card(card : CardModel):
	var card_element = CardScene.instance()
	card_container.add_child(card_element)
	card_element.set_model(card)


func get_drag_data(_pos):
	var list = ListDragPreview.instance()
	get_parent().add_child(list)
	list.set_data(self, get_model())
	get_parent().remove_child(list)
	set_drag_preview(list)

	set_is_dragged()

	Events.emit_signal("list_dragged", self, get_model())

	return list


func can_drop_data(mouse_pos, data):
	if data.drag_data["model"].model_type == Model.ModelTypes.CARD:
		is_receiving_drag_data = true

		var card_node = data.drag_data["node"]

		# If the Card comes from another List, reparent it
		if card_node.get_parent() != card_container:
			card_node.get_parent().remove_child(card_node)
			card_container.add_child(card_node)

		card_node.set_dragged_to_list(model)

		# This List has more than 1 children, we need to calculate where to re-position
		# this Card relative to the closest Card in relation to the mouse position
		if card_container.get_child_count() > 1:
			var closest_card = DragUtils.find_closest_vertical_child(mouse_pos, card_node, card_container, card_container_scroll)

			if closest_card[0]:
#				var curr_idx = card_node.get_index()
				var closest_idx = closest_card[0].get_index()
				var next_idx = max(0, closest_idx + (-1 if closest_card[1] else 0))
				card_container.move_child(card_node, next_idx)

		return true

	is_receiving_drag_data = false
	return false


func drop_data(_pos, data):
	if data.drag_data["model"].model_type == Model.ModelTypes.CARD:
		Events.emit_signal("card_dropped", data.drag_data, model)


func _on_card_created(_model):
	if _model.list_id == model.id:
		add_card(_model)


func _on_card_dragged(_node, _model):
	is_any_data_dragged = true


func _on_card_dropped(_drop_data, _into_list):
	is_any_data_dragged = false


func _on_list_updated(_model):
	if _model.id == model.id:
		set_model(_model, true)


func _on_list_deleted(_model):
	if _model.id == model.id:
		queue_free()


func _on_list_dragged(_node, _model):
	is_any_data_dragged = true
	set("mouse_filter", MOUSE_FILTER_PASS)


func _on_list_dropped(drop_data):
	is_any_data_dragged = false
	set("mouse_filter", MOUSE_FILTER_STOP)

	if drop_data and drop_data["node"] == self:
		set_is_dragged(false)
		Events.emit_signal("order_updated", get_parent().get_children(), Model.ModelTypes.LIST)


func _on_AddCardButton_pressed():
	Events.emit_signal("add_card_clicked", model)


func _on_ListActionsButton_pressed():
	SceneUtils.create_input_field_dialog(
		SceneUtils.InputFieldDialogMode.EDIT_LIST,
		DataRepository.get_board(model.board_id), model
	)
