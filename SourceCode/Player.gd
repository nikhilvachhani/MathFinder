extends TextureButton

onready var label:Label=$Label

func print_number(number_value):
	label.text=str(number_value)


func _on_pressed():
	label.set_position(Vector2(0,10))

func _on_button_down():
	label.set_position(Vector2(0,10))

func _on_button_up():
	label.set_position(Vector2(0,0))

func _on_mouse_entered():
	label.set_position(Vector2(0,10))

func _on_mouse_exited():
	label.set_position(Vector2(0,0))

