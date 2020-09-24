extends Control

signal change_view()

onready var text_edit: TextEdit = $VBoxContainer/TextEdit


var file: File setget set_file
var _changed_text: bool = false

func _ready() -> void:
	text_edit.add_color_region("\"", "\"", Color(1, 0.92549, 0.631373) )
	$SaveChangesDialog.get_cancel().connect("pressed", self, "_on_AcceptDialog_cancled")


func _on_SaveButton_pressed() -> bool:
	var text: String = text_edit.text
	var errors := JsonValidator.validate_config_json(text)
	var save_instead_of_errors := true
	if errors:
		$VBoxContainer/ErrorInfosContainer.errors = errors
		for error in errors:
			if error.begins_with("[Error]") or error.begins_with("[Invalid]"):
				save_instead_of_errors = false
				return false
			if save_instead_of_errors:
				Logger.info("Saved file: " + file.get_path())
				_save_contend()
				return true
	else:
			_save_contend()
	return true


func _on_BackButton_pressed() -> void:
	if _changed_text:
		$SaveChangesDialog.popup()
	else:
		emit_signal("change_view")


func _on_TextEdit_text_changed() -> void:
	_changed_text = true
	_update_errors()


func set_file(_file: File):
	if _file == null:
		return ERR_DOES_NOT_EXIST
	if _file.file_exists(_file.get_path()):
		text_edit.text = _file.get_as_text()
	_changed_text = false
	file = _file
	_update_errors()
	


func _on_AcceptDialog_confirmed() -> void:
	if _on_SaveButton_pressed():
		emit_signal("change_view")


func _on_AcceptDialog_cancled() -> void:
	emit_signal("change_view")


func _update_errors()->void:
	var _errors := JsonValidator.validate_config_json(text_edit.get("text"))
	$VBoxContainer/ErrorInfosContainer.errors = _errors


func _save_contend():
	file.open(file.get_path(), File.WRITE_READ) # This seems like a hacky solution! Should be fixed"
	file.store_string(text_edit.text)
	var error = file.get_error()
	if error != OK:
		Logger.error("Could not write to File", "App", error)
	else:
		_changed_text = false


func _on_ErrorLabel_meta_clicked(meta) -> void:
	if meta.empty():
		meta = $VBoxContainer/ErrorInfosContainer/CenterContainer/ErrorLabel.bbcode_text
		Logger.warn("Used unsafe method of getting the meta text!")
	var line:=int(meta.split(":")[0])-1
	text_edit.cursor_set_line(line)


func _on_RichTextLabel_meta_clicked(meta: String) -> void:
	if meta.empty():
		Logger.warn("Meta empty")
	var line:=int(meta.split(":")[0])-1
	text_edit.cursor_set_line(line)
	$VBoxContainer/ErrorInfosContainer/AcceptDialog.hide()
