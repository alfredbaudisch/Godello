class_name Utils extends Object

static func clear_children(node : Node, ignore := []) -> void:
	# O(n^1) but there won't be that many items anyway
	for child in node.get_children():
		if not child in ignore:
			child.queue_free()
