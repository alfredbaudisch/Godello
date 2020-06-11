class_name Utils extends Object

static func clean_input_text(text : String) -> String:
	return text.replace("\n", "").trim_suffix(" ").trim_prefix(" ")
	
static func validate_not_empty_text(text : String, field_name : String, input_field : Control, parent : Node) -> bool:		
	if not text or text == "":
		SceneUtils.create_single_error_popup(field_name + " is required.", input_field, parent)
		return false
	
	return true	

# Basic email validation (x@x.x)
static func validate_email(email : String) -> bool:
	var regex = RegEx.new()
	regex.compile("([\\w-]+@([\\w-]+\\.)+[\\w-]+)")					
	return regex.search(email) != null
	
static func validate_email_field(input_field : Control, parent : Node) -> bool:
	if not validate_email(input_field.get_text()):
		SceneUtils.create_single_error_popup("Email is not valid.", input_field, parent)
		return false
	
	return true

static func clear_children(node : Node, ignore := []) -> void:
	# O(n^1) but there won't be that many items anyway
	for child in node.get_children():
		if not child in ignore:
			child.queue_free()

static func is_mouse_inside_control(node : Control) -> bool:
	return Rect2(node.get_global_position(), node.get_size()).has_point(node.get_global_mouse_position())
