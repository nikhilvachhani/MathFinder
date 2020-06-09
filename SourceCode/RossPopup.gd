extends TextureButton

onready var open_popup:PopupDialog=$PopupDialog
onready var tween:Tween=$Tween
onready var click_audio:AudioStreamPlayer=$ClickAudio

func _on_RossPopup_pressed():
	click_audio.play()
	open_popup.popup()
# warning-ignore:return_value_discarded
	tween.interpolate_property(open_popup, "rect_position",\
		Vector2(0,-1920), Vector2(0,0),0.5,\
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	tween.start()		

func _on_CloseButton_pressed():
	click_audio.play()
# warning-ignore:return_value_discarded
	tween.interpolate_property(open_popup, "rect_position",\
		Vector2(0,0), Vector2(0,-1920),0.5,\
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	tween.start()	
	yield(tween,"tween_all_completed")	
	open_popup.hide()

func _on_OpenLink_pressed():
	click_audio.play()
# warning-ignore:return_value_discarded
	OS.shell_open("https://play.google.com/store/apps/details?id=com.ross.numbergame12345")
	
