extends MarginContainer


const StyleDefault := preload("res://assets/style_panel_card.tres")
const StuleDragged := preload("res://assets/style_panel_card_dragged.tres")
const CardDragPreview := preload("res://scenes/card_mouse_preview.tscn")

var model : CardModel setget set_model, get_model
var is_dragged := false setget set_is_dragged
var is_dragged_to_list setget set_dragged_to_list
var is_any_data_dragged := false
var in_archives := false setget set_is_in_archives # Listed in the Archived Cards?

onready var content_container := $CardContent
onready var content_padding_container := $CardContent/InnerPadding
onready var title_label := $CardContent/InnerPadding/VBoxContainer/TitleContainer/Title
onready var edit_icon := $CardContent/InnerPadding/VBoxContainer/TitleContainer/EditIcon
onready var split := $CardContent/InnerPadding/VBoxContainer/TitleContainer/Split
onready var indicators_container := $CardContent/InnerPadding/VBoxContainer/IndicatorsContainer
onready var description_icon := $CardContent/InnerPadding/VBoxContainer/IndicatorsContainer/DescriptionIcon
onready var description_sep := $CardContent/InnerPadding/VBoxContainer/IndicatorsContainer/DescriptionSep
onready var checklist_icon := $CardContent/InnerPadding/VBoxContainer/IndicatorsContainer/ChecklistIcon
onready var checklist_count_label := $CardContent/InnerPadding/VBoxContainer/IndicatorsContainer/ChecklistCountLabel
onready var indicators_size_placeholder := $CardContent/InnerPadding/VBoxContainer/IndicatorsContainer/SizePlaceholder


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
	DataRepository.connect("card_updated", self, "_on_card_updated")
# warning-ignore:return_value_discarded
	DataRepository.connect("card_deleted", self, "_on_card_deleted")
# warning-ignore:return_value_discarded
	DataRepository.connect("list_deleted", self, "_on_list_deleted")

	split.set_visible(true)
	edit_icon.set_visible(false)


func _unhandled_input(event):
	# Since Godot doesn't handle drops outside draggable boundaries,
	# we have to handle this by ourselves
	if event is InputEventMouseButton and is_dragged:
		Events.emit_signal("card_dropped", DragUtils.get_drag_data(self, model), is_dragged_to_list)


func set_is_in_archives(value : bool):
	in_archives = value


func set_model(_model : CardModel):
	model = _model
	set_name("Card_" + model.id + ("_archived" if in_archives else ""))

	# Card is instantiated in the Archived Cards list but it's not archived anymore
	if not model.is_archived and in_archives:
		queue_free()
	else:
		var is_visible = not model.is_archived or (model.is_archived and in_archives)
		set_visible(is_visible)

		title_label.set_text(model.title)

		_set_indicators()


func get_model():
	return model


func set_is_dragged(value := true):
	if value:
		content_container.set("custom_styles/panel", StuleDragged)
		title_label.set_visible_characters(0)
		_set_indicators(true)
	else:
		content_container.set("custom_styles/panel", StyleDefault)
		title_label.set_visible_characters(-1)
		is_dragged_to_list = null
		_set_indicators()

	is_dragged = value


func set_dragged_to_list(list):
	is_dragged_to_list = list


func get_drag_data(_pos):
	if model.is_archived:
		return

	var card = CardDragPreview.instance()
	get_parent().add_child(card)
	card.set_data(self, get_model())
	get_parent().remove_child(card)
	set_drag_preview(card)

	set_is_dragged()
	set_edit_icon_visibility(false)

	Events.emit_signal("card_dragged", self, get_model())

	return card


func set_edit_icon_visibility(is_visible : bool):
	edit_icon.set_visible(is_visible)
	split.set_visible(not is_visible)


func _set_indicators(is_dragging := false):
	var has_description = model.description != ""
	var has_tasks = model.tasks.size() > 0
	indicators_container.set_visible(has_description or has_tasks)

	# When dragging, hide indicator icons,
	# keeping the height with indicators_size_placeholder
	if is_dragging:
		for child in indicators_container.get_children():
			child.set_visible(child == indicators_size_placeholder)
	else:
		description_icon.set_visible(has_description)
		description_sep.set_visible(has_description)
		checklist_icon.set_visible(has_tasks)
		checklist_count_label.set_visible(has_tasks)

		if has_tasks:
			checklist_count_label.set_text(str(model.count_tasks_done()) + "/" + str(model.tasks.size()))


func _on_Card_mouse_entered():
	if model.is_archived:
		return

	if not is_dragged and not is_any_data_dragged:
		set_edit_icon_visibility(true)


func _on_Card_mouse_exited():
	if not is_dragged and not is_any_data_dragged:
		set_edit_icon_visibility(false)


func _on_card_dragged(_node, _model):
	is_any_data_dragged = true
	_ignore_mouse()


func _on_card_dropped(drop_data, _new_owner):
	is_any_data_dragged = false
	_default_mouse()

	if drop_data and drop_data["node"] == self:
		set_is_dragged(false)
		Events.emit_signal("order_updated", get_parent().get_children(), Model.ModelTypes.CARD)



func _on_list_dragged(_node, _model):
	is_any_data_dragged = true
	_ignore_mouse()


func _on_list_dropped(_drop_data):
	is_any_data_dragged = false
	_default_mouse()


func _ignore_mouse():
	set("mouse_filter", MOUSE_FILTER_PASS)


func _default_mouse():
	set("mouse_filter", MOUSE_FILTER_STOP)


func _on_Card_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.is_pressed():
		Events.emit_signal("card_clicked", model)


func _on_card_updated(_card):
	if model and _card.id == model.id:
		set_model(_card)


func _on_card_deleted(_card):
	if model and _card.id == model.id:
		queue_free()


func _on_list_deleted(_list):
	# We need to delete the card if it's in the Archived Cards menu,
	# otherwise it will just get deleted with the list anyway.
	if in_archives and model and _list.id == model.list_id:
		queue_free()
