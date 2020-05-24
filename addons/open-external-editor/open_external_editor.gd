# Copyright (c) 2018 Calvin Ikenberry.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

tool
extends EditorPlugin

const SHORTCUT_SCANCODE = KEY_E
const SHORTCUT_MODIFIERS = KEY_MASK_CTRL

const USE_EXTERNAL_EDITOR_SETTING = "text_editor/external/use_external_editor"
const EXEC_PATH_SETTING = "text_editor/external/exec_path"
const EXEC_FLAGS_SETTING = "text_editor/external/exec_flags"

var godot_version

var script_editor
var editor_settings
var button
var shortcut

func _enter_tree():
	godot_version = Engine.get_version_info()
	if godot_version["major"] < 3:
		print("\"Open External Editor\" plugin requires Godot 3.0 or higher")
		return
	script_editor = get_editor_interface().get_script_editor()
	editor_settings = get_editor_interface().get_editor_settings()
	var input_event = InputEventKey.new()
	input_event.scancode = SHORTCUT_SCANCODE
	if SHORTCUT_MODIFIERS & KEY_MASK_ALT:
		input_event.alt = true
	if SHORTCUT_MODIFIERS & KEY_MASK_CMD:
		input_event.command = true
	if SHORTCUT_MODIFIERS & KEY_MASK_CTRL:
		input_event.control = true
	if SHORTCUT_MODIFIERS & KEY_MASK_META:
		input_event.meta = true
	if SHORTCUT_MODIFIERS & KEY_MASK_SHIFT:
		input_event.shift = true
	shortcut = ShortCut.new()
	shortcut.set_shortcut(input_event)
	button = ToolButton.new()
	button.text = "Ext. Editor"
	button.hint_tooltip = "Open script in external editor (" + shortcut.get_as_text() + ")"
	button.connect("pressed", self, "open_external_editor")
	var vbox1 = script_editor.get_child(0)
	var hbox1 = vbox1.get_child(0)
	hbox1.add_child(button)

func _exit_tree():
	if button != null:
		button.free()

func _input(event):
	if shortcut.is_shortcut(event) && !event.pressed && script_editor.is_visible_in_tree():
		open_external_editor()

func open_external_editor():
	var use_external_editor = editor_settings.get_setting(USE_EXTERNAL_EDITOR_SETTING)
	var exec_path = editor_settings.get_setting(EXEC_PATH_SETTING)
	var exec_flags = editor_settings.get_setting(EXEC_FLAGS_SETTING)
	if use_external_editor:
		return
	var args = parse_exec_flags(exec_flags)
	if args == null:
		return
	OS.execute(exec_path, args, false)

# This feels super hacky but whatever ¯\_(ツ)_/¯
func get_text_edit():
	var vbox1 = script_editor.get_child(0)
	var hsplit1 = vbox1.get_child(1)
	var tab_cont1 = hsplit1.get_child(1)
	var current_script = script_editor.get_current_script()
	var open_scripts = script_editor.get_open_scripts()
	var i = 0
	for child in tab_cont1.get_children():
		if child.get_class() != "ScriptTextEditor":
			continue
		if current_script == open_scripts[i]:
			var editor = child.get_child(0)
			if godot_version["minor"] == 0:
				return editor.get_child(1)
			else:
				for child in editor.get_child(0).get_children():
					if child.name == "TextEdit":
						return child
		i += 1

func parse_exec_flags(flags):
	var text_edit = get_text_edit()
	if text_edit == null:
		printerr("Couldn't get TextEdit node")
		return
	
	var script = script_editor.get_current_script()
	if script == null:
		return
	var project_path = ProjectSettings.globalize_path("res://")
	var script_path = ProjectSettings.globalize_path(script.resource_path)
	if script_path.empty():
		return
	var line = text_edit.cursor_get_line() + 1
	var column = text_edit.cursor_get_column() + 1
	flags = flags.replacen("{line}", str(max(1, line)))
	flags = flags.replacen("{col}", str(column))
	flags = flags.strip_edges().replace("\\\\", "\\")
	var args = PoolStringArray()
	var from = 0
	var num_chars = 0
	var inside_quotes = false
	for i in range(flags.length() + 1):
		if i == flags.length() || (!inside_quotes && flags[i] == " "):
			var arg = flags.substr(from, num_chars)
			arg = arg.replacen("{project}", project_path)
			arg = arg.replacen("{file}", script_path)
			args.push_back(arg)
			from = i + 1
			num_chars = 0
		elif flags[i] == "\"" && (!i || flags[i-1] != "\\"):
			if !inside_quotes:
				from += 1
			inside_quotes = !inside_quotes
		else:
			num_chars += 1
	return args
