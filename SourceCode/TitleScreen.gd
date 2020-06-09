extends Node2D

var level_size:int=3
onready var start_button:Button=$Start
onready var howto_button:Button=$HowToPlay
onready var click_audio:AudioStreamPlayer=$ClickAudio
onready var level_image:Sprite=$Levels
onready var consent:Label=$Consent

var ads_file = "user://ads.save"

func _ready():
	var ads = File.new()
	if ads.file_exists(ads_file):
		consent.hide()
	else:
		start_button.disabled=true
		start_button.visible=false
		howto_button.disabled=true
		howto_button.visible=false

func _on_Ok_pressed():
	var ads = File.new()
	ads.open(ads_file, File.WRITE)
	ads.store_var(1)
	ads.close()
	consent.hide()
	start_button.disabled=false
	start_button.visible=true
	howto_button.disabled=false
	howto_button.visible=true

func _on_Left_pressed():
	click_audio.play()
	yield(click_audio,"finished")
	if level_size==3:
		level_size=6
	else:
		level_size-=1
	print_level()

func _on_Right_pressed():
	click_audio.play()
	yield(click_audio,"finished")
	if level_size==6:
		level_size=3
	else:
		level_size+=1
	print_level()
	
func print_level():
	start_button.text="Start "+str(level_size)+"x"+str(level_size)
	level_image.frame=level_size-3

func _on_Start_pressed():
	GameData.size=level_size
	click_audio.play()
	yield(click_audio,"finished")
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://SourceCode/RoundController.tscn")


func _on_HowToPlay_pressed():
	click_audio.play()
	yield(click_audio,"finished")
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://SourceCode/HowToPlay.tscn")
