extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var file =  "/Users/i13az81/Develop/UNI/MirrorRobot/example_data/cmd.sh"
# Called when the node enters the scene tree for the first time.
func _ready():
	var output = []
	print(OS.execute(file, [], false, output))


	print(output)
#	for line in output:
#		print(line)
