extends Control

var current_os = OS.get_name()
var working_dir = "."
var copy_config: Dictionary
var date = ''

func _ready():
	Logger.set_default_logfile_path("/Users/i13az81/Develop/UNI/MirrorRobot/Logger/logfile.log")
	Logger.default_output_level = Logger.DEBUG
	
	var out_strats = [Logger.STRATEGY_PRINT, Logger.STRATEGY_PRINT, Logger.STRATEGY_PRINT_AND_FILE, Logger.STRATEGY_PRINT_AND_FILE, Logger.STRATEGY_PRINT_AND_FILE]
	Logger.add_module("App", Logger.VERBOSE, out_strats)
	Logger.info(Logger.default_logfile_path, "App")
	Logger.default_module = "App"
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
		
	if file.open(path, File.READ_WRITE) != OK:
		Logger.warn("Could not open file " + path)
		return 
		
	var file_contend = file.get_as_text()
	var invalid = validate_json(file_contend)
	if not invalid:
		var config: Dictionary = parse_json(file_contend)
		if not (config.has_all(["input", "output"]) and config["input"] is Array):
			Logger.warn("Invalide Config File")
			Logger.error("Did not set config")
			$MirrorErrorDialog.popup_centered()
			return
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
		
#	$MirrorButton.disabled = true TODO 
	$MirrorButton.text = "Mirroring..."


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
