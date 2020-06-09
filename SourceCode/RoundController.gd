extends Node2D

const number_file = preload("res://SourceCode/Number.tscn")
onready var player:Button=$Player
onready var highscore_text:Label=$HighScoreButton/ValueLabel
onready var score_text:Label=$ScoreButton/ValueLabel
onready var target:Button=$Target
onready var tween:Tween=$Tween
onready var timer:Timer=$Timer
onready var click_audio:AudioStreamPlayer=$ClickAudio
onready var move_audio:AudioStreamPlayer=$MoveAudio
onready var admob:Node=$Admob
onready var adpopup:Popup=$AdPopup
onready var warningpopup:Popup=$WarningPopup
onready var warningpopuptext:Label=$WarningPopup/Label

#variable about plotting game elements
var max_dim:int=3
var map_data:Array
var dim_mult:int=200
var x_offset:int=50
var y_offset:int=390

#player and target position
var pl_pos:Array
var t_pos:Array

#score variables
var current_score:int=0
var target_score:int=0

#input control variables
var swipe_start_pos:Vector2

#saved last step data
var prev_pl_pos:Array
var prev_num_pos:Array

func _ready():
#load ads
	admob.load_banner()
# warning-ignore:return_value_discarded
	get_tree().connect("screen_resized", self, "_on_resize")
	admob.load_rewarded_video()
#adjust size for the game
	max_dim=GameData.size
# warning-ignore:integer_division
	dim_mult=1000/max_dim
	pl_pos=[0,max_dim-1]
	t_pos=[max_dim-1,0]
			
#generate random numbers
	randomize()
	var rand:int
	var number_inst
	for i in range(max_dim):
# warning-ignore:unassigned_variable
		var column:Array
		for j in range(max_dim):
			if i==pl_pos[0] and j==pl_pos[1]:
				column.append([null,0,"start","start"])
			elif i==t_pos[0] and j==t_pos[1]:
				column.append([target,0,"target","target"])
			else:
				number_inst=number_file.instance()
# warning-ignore:narrowing_conversion
				rand=floor(rand_range(1,max_dim+1))
				add_child(number_inst)
				number_inst.text=str(rand)
				number_inst.rect_size=Vector2(dim_mult-20,dim_mult-20)
				number_inst.set_position(Vector2(i*dim_mult+x_offset,j*dim_mult+y_offset))
				column.append([number_inst,rand,"ready","ready"])
		map_data.append(column)
		
	#put player position on put on top of numbers
	set_pl_pos()
	player.raise()
	player.rect_size=Vector2(dim_mult-20,dim_mult-20)
	
	#set target
	target.set_position(Vector2(t_pos[0]*dim_mult+x_offset,t_pos[1]*dim_mult+y_offset))
	random_route()
	target.text=str(target_score)
	target.rect_size=Vector2(dim_mult-20,dim_mult-20)
	
	#load score and highscore
	var last_save=load_save()
	var score=last_save["score"]
	var highscore=last_save["highscore"]
	highscore_text.text=str(highscore)
	score_text.text=str(score)

# Admob callbacks
func _on_resize():
	admob.banner_resize()
		
func set_pl_pos():
	player.set_position(Vector2(pl_pos[0]*dim_mult+x_offset,pl_pos[1]*dim_mult+y_offset))
	
#player moves
func _input(event):
	if not event is InputEventScreenTouch:
		return
	if event.pressed:
		#if event.position.y>=y_offset and event.position.y<=y_offset+1000:
		start_detection(event.position)
	elif not timer.is_stopped():
		end_detection(event.position)
		
func start_detection(position):
	swipe_start_pos=position
	timer.start()
	
func end_detection(position):
	timer.stop()
	var direction=(position-swipe_start_pos).normalized()
	if abs(direction.x)+abs(direction.y)>=1.3:
		return
	if abs(direction.x)>abs(direction.y):
		if direction.x<0 and pl_pos[0]>0:
			if map_data[pl_pos[0]-1][pl_pos[1]][2]=="ready":
				calc_move(pl_pos[0]-1,pl_pos[1])
			elif map_data[pl_pos[0]-1][pl_pos[1]][2]=="target":
				check_win(pl_pos[0]-1,pl_pos[1])
		if direction.x>0 and pl_pos[0]<max_dim-1:
			if map_data[pl_pos[0]+1][pl_pos[1]][2]=="ready":
				calc_move(pl_pos[0]+1,pl_pos[1])
			elif map_data[pl_pos[0]+1][pl_pos[1]][2]=="target":
				check_win(pl_pos[0]+1,pl_pos[1])
	else:
		if direction.y<0 and pl_pos[1]>0:
			if map_data[pl_pos[0]][pl_pos[1]-1][2]=="ready":
				calc_move(pl_pos[0],pl_pos[1]-1)
			elif map_data[pl_pos[0]][pl_pos[1]-1][2]=="target":
				check_win(pl_pos[0],pl_pos[1]-1)
		if direction.y>0 and pl_pos[1]<max_dim-1:
			if map_data[pl_pos[0]][pl_pos[1]+1][2]=="ready":
				calc_move(pl_pos[0],pl_pos[1]+1)
			elif map_data[pl_pos[0]][pl_pos[1]+1][2]=="target":
				check_win(pl_pos[0],pl_pos[1]+1)
		

func _on_Timer_timeout():
	pass # Replace with function body.			

#do the move after valid swipe
func calc_move(a,b):
	save_step(a,b)
	pl_pos=[a,b]
	current_score+=map_data[a][b][1]
	player.text=str(current_score)
	map_data[a][b][2]="expired"
	move_audio.play()
# warning-ignore:return_value_discarded
	tween.interpolate_property(map_data[a][b][0], "modulate",\
		Color(1,1,1,1), Color(1,1,1,0), 0.25,\
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	tween.interpolate_property(player, "rect_position",\
		player.get_position(), Vector2(a*dim_mult+x_offset,b*dim_mult+y_offset), 0.25,\
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	tween.start()
#tell user if she/he lost
	if current_score>target_score:
		warningpopup.popup()
		warningpopuptext.text="Looks like you lost, because your score of " + str(current_score)\
		+ " is higher than target score of " + str(target_score) + " (press New button to restart or Undo button)" 
	
#save last step 
func save_step(x,y):
	prev_pl_pos=pl_pos.duplicate(true)
	prev_num_pos=[x,y]
		
func check_win(a,b):	
	if current_score==target_score:
		pl_pos=[a,b]
		move_audio.play()
	# warning-ignore:return_value_discarded
		tween.interpolate_property(map_data[a][b][0], "modulate",\
			Color(1,1,1,1), Color(1,1,1,0), 0.25,\
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	# warning-ignore:return_value_discarded
		tween.interpolate_property(player, "rect_position",\
			player.get_position(), Vector2(a*dim_mult+x_offset,b*dim_mult+y_offset), 0.25,\
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	# warning-ignore:return_value_discarded
		tween.start()
		yield(tween,"tween_completed")
		click_audio.play()
		yield(click_audio,"finished")
		save_game(target_score+int(score_text.text))
# warning-ignore:return_value_discarded
		get_tree().reload_current_scene()
	else:
		warningpopup.popup()
		warningpopuptext.text="To win, you need to have a score of " + str(target_score) + " (shown in top right piece)" 
		
func random_route():
	var route_pos:Array=pl_pos+[]
	var exit_loop:bool=false
	var route_sum:int=0
	var count_turn=0
	while exit_loop==false:
		#check if stuck
		if count_turn>60:
			exit_loop=true
# warning-ignore:return_value_discarded
			get_tree().reload_current_scene()
		else:
			count_turn+=1
# warning-ignore:narrowing_conversion
			var rand_move:int=floor(rand_range(0,4))
					
			if rand_move==0 and route_pos[0]<max_dim-1:  #move right
				if map_data[route_pos[0]+1][route_pos[1]][3]=="target":
					exit_loop=true
					target_score=route_sum
				elif map_data[route_pos[0]+1][route_pos[1]][3]=="ready":
					route_sum+=map_data[route_pos[0]+1][route_pos[1]][1]
					map_data[route_pos[0]+1][route_pos[1]][3]="expired"
					route_pos[0]+=1
					
			elif rand_move==1 and route_pos[1]>0:  #move up
				if map_data[route_pos[0]][route_pos[1]-1][3]=="target":
					exit_loop=true
					target_score=route_sum
				elif map_data[route_pos[0]][route_pos[1]-1][3]=="ready":
					route_sum+=map_data[route_pos[0]][route_pos[1]-1][1]
					map_data[route_pos[0]][route_pos[1]-1][3]="expired"
					route_pos[1]-=1
					
			elif rand_move==2 and route_pos[0]>0:  #move left
				if map_data[route_pos[0]-1][route_pos[1]][3]=="target":
					exit_loop=true
					target_score=route_sum
				elif map_data[route_pos[0]-1][route_pos[1]][3]=="ready":
					route_sum+=map_data[route_pos[0]-1][route_pos[1]][1]
					map_data[route_pos[0]-1][route_pos[1]][3]="expired"
					route_pos[0]-=1
					
			elif rand_move==3 and route_pos[1]<max_dim-1:  #move down
				if map_data[route_pos[0]][route_pos[1]+1][3]=="target":
					exit_loop=true
					target_score=route_sum
				elif map_data[route_pos[0]][route_pos[1]+1][3]=="ready":
					route_sum+=map_data[route_pos[0]][route_pos[1]+1][1]
					map_data[route_pos[0]][route_pos[1]+1][3]="expired"
					route_pos[1]+=1
									
func _on_UndoButton_pressed():
	click_audio.play()
	if prev_pl_pos.empty()==false or prev_num_pos.empty()==false:
		print("ads video ready?", admob.is_rewarded_video_loaded())
		if admob.is_rewarded_video_loaded():
			adpopup.popup()
		else:
			revert_move()
			
func revert_move():
	pl_pos=prev_pl_pos.duplicate(true)
	current_score-=map_data[prev_num_pos[0]][prev_num_pos[1]][1]
	map_data[prev_num_pos[0]][prev_num_pos[1]][0].modulate=Color(1,1,1,1)
	map_data[prev_num_pos[0]][prev_num_pos[1]][2]="ready"
	player.text=str(current_score)
	set_pl_pos()
	prev_pl_pos=[]
	prev_num_pos=[]

func _on_HomeButton_pressed():
# warning-ignore:return_value_discarded
	click_audio.play()
	yield(click_audio,"finished")
	get_tree().change_scene("res://SourceCode/TitleScreen.tscn")

func _on_NewButton_pressed():
	click_audio.play()
	yield(click_audio,"finished")
	save_game(0)
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func save_game(score):
	var highscore=max(score,int(highscore_text.text))
	var save_data:Dictionary = {"score": score,"highscore": highscore}		
	var save_game = File.new()
	save_game.open("user://file.save", File.WRITE)
	save_game.store_line(to_json(save_data))
	save_game.close()
	
func load_save():
	#var save_data:Dictionary = {"score": 0,"highscore": 0}	
	var save_game = File.new()
	if not save_game.file_exists("user://file.save"):
		print("Error! We don't have a save to load")
		return{"score": 0,"highscore": 0}
	else:
		save_game.open("user://file.save", File.READ)
		var save_data = parse_json(save_game.get_line())
		save_game.close()
		return save_data

#undo the move
func _on_Admob_rewarded(_currency, _amount):
	revert_move()
	adpopup.hide()
	admob.load_rewarded_video()

#load new rewarded video
func _on_Admob_rewarded_video_closed():
	admob.load_rewarded_video()

func _on_ShowAdd_pressed():
	click_audio.play()
	admob.show_rewarded_video()

func _on_CloseAdPopup_pressed():
	click_audio.play()
	adpopup.hide()
