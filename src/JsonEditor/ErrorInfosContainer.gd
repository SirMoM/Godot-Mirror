extends HBoxContainer

onready var error_label := $CenterContainer/ErrorLabel
onready var error_info_btn := $CenterContainer2/ErrorInfoButton
onready var error_label_dialog := $AcceptDialog/RichTextLabel

var error_template: String = "[color=red]{error}"
var error_meta_template: String = "[color=red][url]{error}[/url]"



var errors: Array = [] setget  set_errors

func _ready() -> void:
	set_errors(JsonValidator.validate_config_json(get_parent().get_child(0).text))

func set_errors(_errors: Array) -> void:
	errors = _errors
	error_info_btn.text = str(errors.size())
	if _errors.size() == 0:
		error_label.bbcode_text = ""
		return

	for error in errors:
		if error.begins_with("[Invalid]"):
			error_label.bbcode_text=error_meta_template.format({"error": error})
		else:
			error_label.bbcode_text=error_template.format({"error": error})

func _on_ErrorInfoButton_pressed() -> void:
	error_label_dialog.bbcode_text = ""
	for error in errors:
		if error.begins_with("[Invalid]"):
			error_label_dialog.bbcode_text+=error_meta_template.format({"error": error})
		else:
			error_label_dialog.bbcode_text+=error_template.format({"error": error})+"\n\n"
	$AcceptDialog.popup_centered()
