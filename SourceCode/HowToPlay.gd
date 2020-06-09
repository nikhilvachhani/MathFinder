extends Node2D

onready var click_audio:AudioStreamPlayer=$ClickAudio
	
func _on_HomeButton_pressed():
	click_audio.play()
	yield(click_audio,"finished")
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://SourceCode/TitleScreen.tscn")
