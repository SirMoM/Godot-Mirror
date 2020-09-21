extends Control

signal change_view()

onready var text_edit: TextEdit = $TextEdit


var file: File setget set_file
var _changed_text: bool = false

func _ready() -> void:
	print("")
	text_edit.add_color_region("\"", "\"", Color(1, 0.92549, 0.631373) )

func _on_SaveButton_pressed() -> void:
	print("pressed")
	var text: String = text_edit.text
	var errors = JsonValidator.validate_config_json(text)
	if errors:
		pass # TODO save 4 real
	else:
		pass # Popup fehler
	print(errors)

func _on_BackButton_pressed() -> void:
	print("pressed")
	if _changed_text:
		pass # pop up unsaved changes usw
	else:
		emit_signal("change_view")

func _on_TextEdit_text_changed() -> void:
	_changed_text = true
	pass

func set_file(_file: File):
	text_edit.text = _file.get_as_text()
	_changed_text = false
	file = _file
