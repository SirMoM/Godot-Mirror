extends Control

var current_os = OS.get_name()
var working_dir = "/0 MiscDev/GODOT/Godot-Mirror/.gdignore/example_data"
var copy_config: Dictionary

func _ready():
	#Logger.set_default_logfile_path("/Users/i13az81/Develop/UNI/MirrorRobot/Logger/logfile.log")
	Logger.default_output_level = Logger.DEBUG
	
	var out_strats = [Logger.STRATEGY_PRINT, Logger.STRATEGY_PRINT, Logger.STRATEGY_PRINT_AND_FILE, Logger.STRATEGY_PRINT_AND_FILE, Logger.STRATEGY_PRINT_AND_FILE]
	Logger.add_module("App", Logger.TRACE, out_strats)
	Logger.info(Logger.default_logfile_path, "App")
	Logger.default_module_name = "App"
#	match current_os:
#		"Windows":
#			$OSSelector.select(0)
#			file_ext = ".zip"
#		_:
#			printerr("This OS is not supported!")
#			queue_free()

	# Add the date and extension to the file name to compare to previous versions
	$ProgressBar.value = 0
	fill_config_file_selector()


func _on_AboutButton_pressed():
	$AboutDialog.popup()


func _process(_delta):
	pass


func list_files_in_directory(path) -> Array:
	# By volzhs
	# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
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


func _on_Label2_meta_clicked(meta):
	OS.shell_open(meta)


func _on_MirrorButton_pressed():
	var file: File = _open_file()
	if _load_file_contend(file) != OK:
		return
		
	$MirrorButton.disabled = true 
	$MirrorButton.text = "Mirroring..."
	
	var console=[]
	for input in copy_config["input"]:
		Directory.new().make_dir_recursive(copy_config["output"])
		OS.execute("robocopy", [input, copy_config["output"], "/MIR"], true,console)
		$ProgressBar.value += 100 / copy_config["input"].size()
	Logger.debug(console)

func _open_file():
	var selector: OptionButton =$HBoxContainer/ConfigFileSelector
	
	if  selector.selected < 0:
		Logger.debug("No file selected!")
		return ERR_CANT_ACQUIRE_RESOURCE
	
	var path: String = selector.get_item_text(selector.selected)
	path = working_dir + "/" + path  
	var file : = File.new()
	if !file.file_exists(path):
		Logger.info(file.is_open())
		Logger.info("Could not open file " + path)
		return ERR_DOES_NOT_EXIST
		
	if file.open(path, File.READ_WRITE) != OK:
		Logger.warn("Could not open file " + path)
		return ERR_FILE_CANT_OPEN
	return file
	

func _load_file_contend(file: File):
	var file_contend = file.get_as_text()
	var invalid = validate_json(file_contend)
	if not invalid:
		var config: Dictionary = parse_json(file_contend)
		if not (config.has_all(["input", "output"]) and config["input"] is Array):
			Logger.warn("Invalide Config File")
			Logger.error("Did not set config")
			$MirrorErrorDialog.popup_centered()
			return ERR_INVALID_DATA
		else:
			copy_config = config
			Logger.info("Set config: " + str(copy_config))
	else:
		Logger.info("Tryed to open invalide JSON")
		Logger.info(invalid)
		$MirrorErrorDialog/LineEdit.text = (
			"Could not load json!"
			+ "\n"
			+ "The File has to contain a valid JSON."
			+ "\n"
			+ "Errors:"
			+ "\n"
			+ invalid
		)
		$MirrorErrorDialog.popup_centered()
		return ERR_FILE_CORRUPT
	return OK


func _on_OpenFolderButton_pressed():
	$FileDialog.popup_centered_clamped(rect_size, 0.9)


func _on_FileDialog_dir_selected(dir):
	working_dir = dir
	fill_config_file_selector()


func fill_config_file_selector() -> void:
	var selector := $HBoxContainer/ConfigFileSelector
	selector.clear()
	Logger.debug(working_dir, "App")
	for path in list_files_in_directory(working_dir):
		if path.ends_with(".json"):
			selector.add_item(path)
	if selector.get_item_count() == 0:
		selector.text = "Could not find any files!"


func _on_MirrorErrorDialog_popup_hide():
	$MirrorErrorDialog/LineEdit.bbcode_text = "[color=grey][matrix]Error[/matrix]"


func _on_EditSelectedFileButton_pressed():
	var selector: OptionButton =$HBoxContainer/ConfigFileSelector
	
	if  selector.selected < 0:
		Logger.debug("No file selected!")
		return
	
	var path: String = selector.get_item_text(selector.selected)
	path = working_dir + "/" + path  
	var file : = File.new()
	if !file.file_exists(path):
		Logger.info(file.is_open())
		Logger.info("Could not open file " + path)
		return
	OS.shell_open("file://" + path)
