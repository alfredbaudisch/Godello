extends Node

class_name PhoenixPresence

signal on_join(key, current_presence, new_presence)
signal on_leave(key, current_presence, left_presence)

var _state := {} setget ,get_state	

func sync_state(new_state : Dictionary) -> Dictionary:		
	var joins := {}
	var leaves := {}
	
	var keys := _state.keys()
	for key in keys:
		if not new_state.has(key):
			leaves[key] = _state[key]
	
	var new_state_keys := new_state.keys()		
	for key in new_state_keys:			
		var new_presence = new_state[key]
		
		if _state.has(key):
			var current_presence = _state[key]
			var new_refs := PhoenixUtils.map(funcref(self, "_get_phx_ref"), new_presence)
			var curr_refs := PhoenixUtils.map(funcref(self, "_get_phx_ref"), current_presence)
			
			var joined_metas := _find_metas_from_refs(new_presence.metas, curr_refs)
			var left_metas := _find_metas_from_refs(current_presence.metas, new_refs)
					
			if joined_metas.size() > 0:
				joins[key] = new_presence
				joins[key].metas = joined_metas
				
			if left_metas.size() > 0:
				leaves[key] = current_presence.duplicate(true)
				leaves[key].metas = left_metas					
		
		else:
			joins[key] = new_presence
	
	return sync_diff({
		joins = joins,
		leaves = leaves
	})
	
func sync_diff(diff : Dictionary) -> Dictionary:
	var joins = diff.joins
	var leaves = diff.leaves
	var emit_joins := []
	var emit_leaves := []
	
	var keys = joins.keys()
	for key in keys:
		var new_presence = joins[key]			
		var current_presence = _state[key] if _state.has(key) else null
		_state[key] = new_presence
		
		if current_presence:
			for meta in current_presence.metas:
				_state[key].metas.push_front(meta)
		
		emit_joins.append({
			key = key,
			current_presence = current_presence,
			new_presence = new_presence
		})			
		
	keys = leaves.keys()
	for key in keys:
		var left_presence = leaves[key]
		
		if _state.has(key):
			var current_presence = _state[key]				
			var refs_to_remove = PhoenixUtils.map(funcref(self, "_get_phx_ref"), left_presence.metas)				
			current_presence.metas = _find_metas_from_refs(current_presence.metas, refs_to_remove)
			
			emit_leaves.append({
				key = key,
				current_presence = current_presence,
				left_presence = left_presence
			})	
			
			if current_presence.metas.size() == 0:
				_state.erase(key)
	
	if emit_joins.size() > 0:
		emit_signal("on_join", emit_joins)
		
	if emit_leaves.size() > 0:
		emit_signal("on_leave", emit_leaves)
	
	return _state
	
func list(chooser : FuncRef = null):
	if chooser:
		var sorted := []		
		for key in _state.keys():
			sorted.append(chooser.call_func(key, _state[key]))
						
		return sorted
	
	else:
		return _state.values()
		
func clear():
	var leaves := []
	var keys = _state.keys()
	
	for key in keys:
		var current_presence = _state[key]
		leaves.append({
			key = key,
			current_presence = current_presence,
			left_presence = current_presence
		})	
		
	if leaves.size() > 0:
		emit_signal("on_leave", leaves)
			
	_state.clear()
	
func get_state():
	return _state

func _get_phx_ref(presence : Dictionary) -> String:
	return presence.phx_ref			

func _find_metas_from_refs(metas : Array, refs : Array) -> Array:	
	var final_metas := []
		
	for meta in metas:
		var pos := refs.find(meta.phx_ref)
		if pos == -1:
			final_metas.append(meta)
	
	return final_metas
