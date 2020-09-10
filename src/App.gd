extends Control

const ERROR_BBCODE := "[matrix]Error:[/matrix]"

export var working_dir: String = "."

var current_os: String = OS.get_name()
var mirror_config: Dictionary

var _windows: bool = false
var _mac: bool = false


## Sets up the Logger from https://github.com/SirMoM/godot-logger
## And sets general settings for the app
func _ready():
	var logfile = Logger.add_logfile("res://logs/log.log")
	Logger.output_format = "[{TIME}] [{MOD}] [{LVL}]{ERR} {MSG}"
	var out_strats = [
		Logger.STRATEGY_PRINT,
		Logger.STRATEGY_PRINT,
		Logger.STRATEGY_PRINT_AND_FILE,
		Logger.STRATEGY_PRINT_AND_FILE,
		Logger.STRATEGY_PRINT_AND_FILE
	]
	Logger.add_module("App", Logger.TRACE, out_strats, logfile)
	Logger.default_module_name = "App"

	match current_os:
		"Windows":
			_windows = true
		"OSX":
			_mac = true
		_:
			Logger.error("This OS (" + current_os + ") is not supported!")
			queue_free()

	$ProgressBar.value = 0
	_fill_config_file_selector()


func _on_AboutButton_pressed():
	$AboutDialog.popup()


# By volzhs
# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func _list_files_in_directory(path) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files


## For opening the links in the AboutDialog
func _on_Label2_meta_clicked(meta):
	OS.shell_open(meta)


## Loads the config from the selected file and starts the mirroring process.
## Dose nothing if the config file is invalid
func _on_MirrorButton_pressed():
	var file = _open_file()
	if not file is File or _load_file_contend(file) != OK:
		return

	$MirrorButton.disabled = true
	$MirrorButton.text = "Mirroring..."

	var console = []
	for input in mirror_config["input"]:
		Directory.new().make_dir_recursive(mirror_config["output"])

		if _windows:
			OS.execute("robocopy", [input, mirror_config["output"], "/MIR"], true, console)
			OS.execute("rsync", [input + " " + mirror_config["output"] + "-av"], true, console)

		$ProgressBar.value += 100 / mirror_config["input"].size()
	Logger.debug(console)

	$MirrorButton.disabled = false
	$MirrorButton.text = "Mirror"


## Trys to open the config file
## @return a File or an Error code
func _open_file():
	var selector: OptionButton = $HBoxContainer/ConfigFileSelector

	if selector.selected < 0:
		Logger.debug("No file selected!", "App", ERR_CANT_ACQUIRE_RESOURCE)
		return ERR_CANT_ACQUIRE_RESOURCE

	var path: String = selector.get_item_text(selector.selected)
	path = working_dir + "/" + path
	var file := File.new()

	# Check if the exists
	if ! file.file_exists(path):
		Logger.info("File does not exist " + path)
		return ERR_DOES_NOT_EXIST
	# Check if the file can be opened
	if file.open(path, File.READ_WRITE) != OK:
		Logger.warn("Could not open file " + path)
		return ERR_FILE_CANT_OPEN
	return file


## Loads the file contend into the mirror configuration: mirror_config
## @returns Error code or OK
func _load_file_contend(file: File):
	var file_contend = file.get_as_text()
	var invalid = validate_json(file_contend)
	if not invalid.empty():
		Logger.info("Tryed to open invalide JSON. The error:")
		Logger.info(_format_error(invalid))
		$MirrorErrorDialog/LineEdit.bbcode_text = (
			"Could not load json!\n"
			+ "The File has to contain a valid JSON.\n"
			+ "\n"
			+ ERROR_BBCODE
			+ "\n"
			+ _format_error(invalid)
		)

		$MirrorErrorDialog.popup_centered()
		return ERR_FILE_CORRUPT
	else:
		var config: Dictionary = parse_json(file_contend)
		if not (
			config.has_all(["input", "output"])
			and config["input"] is Array
			and config["input"] is String
		):
			Logger.warn("Invalide Config File")
			Logger.warn("Did not set config")
			$MirrorErrorDialog/LineEdit.bbcode_text = (
				ERROR_BBCODE
				+ "\n"
				+ "Invalide Config File!\n"
				+ "The File has to contain a valid configuration.\n"
				+ "\n"
				+ "The config has to include 'input', 'output'.\n"
				+ "For information click [url]here[/url]."
			)
			$MirrorErrorDialog.popup_centered()
			return ERR_INVALID_DATA
		else:
			mirror_config = config
			Logger.info("Set config: " + str(mirror_config))
	return OK


## Formats the json_parse Errso into a more readable message
func _format_error(error: String) -> String:
	return "Line " + error.replace(":", ": ")


## Opens the FileDialog for selecting the dir with the config files / working_dir
func _on_OpenFolderButton_pressed():
	$FileDialog.popup_centered_clamped(rect_size, 0.9)


## Triggert after the dir has been selected
## Fills the ConfigFileSelect based on the selected dir
func _on_FileDialog_dir_selected(dir):
	working_dir = dir
	_fill_config_file_selector()


## Fills the ConfigFileSelector with items bases on the "working_dir".
func _fill_config_file_selector() -> void:
	var selector := $HBoxContainer/ConfigFileSelector
	selector.clear()
	Logger.debug(working_dir)
	for path in _list_files_in_directory(working_dir):
		if path.ends_with(".json"):
			selector.add_item(path)
	if selector.get_item_count() == 0:
		selector.text = "Could not find any json files!"


## Opens the currently selected file in the system editor
func _on_EditSelectedFileButton_pressed():
	var file = _open_file()
	if file is File:
		OS.shell_open("file://" + file.get_path_absolute())


## For opening the url to the ussage dialog
func _on_LineEdit_meta_clicked(_meta) -> void:
	$MirrorErrorDialog.hide()
	$TitleBar/HelpDialog.popup_centered()
