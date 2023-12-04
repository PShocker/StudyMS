extends Node2D

class_name Player;
var _foothold
var _player
var _down_jump_flag=false


const PLAYER_VELOCITY_X=400
const PLAYER_WIDTH=32
const PLAYER_HEIGHT=32
const PLAYER_DOWN_JUMP_HEIGHT=40


func body_exited(body: Node2D):
	_down_jump_flag=false
	#print("exit")

func init_area(_player):
	var area2D=Area2D.new()
	var collisionShape2D=CollisionShape2D.new()
	var rectangleShape2D=RectangleShape2D.new()
	area2D.set_position(Vector2(0,(PLAYER_DOWN_JUMP_HEIGHT-PLAYER_HEIGHT)/2))
	rectangleShape2D.set_size(Vector2(PLAYER_WIDTH,PLAYER_DOWN_JUMP_HEIGHT))
	collisionShape2D.set_shape(rectangleShape2D)
	area2D.add_child(collisionShape2D)
	area2D.connect("body_exited", body_exited)
	_player.add_child(area2D)

func _init(parent,limit_left,limit_right):
	_player=CharacterBody2D.new()
	_player.set_floor_snap_length(20)
	var sprite=Sprite2D.new()
	sprite.set_texture(load("res://icon.svg"))
	sprite.set_scale(Vector2(0.25,0.25))

	var collisionShape2D=CollisionShape2D.new()
	var rectangleShape2D=RectangleShape2D.new()
	rectangleShape2D.set_size(Vector2(PLAYER_WIDTH,PLAYER_HEIGHT))
	collisionShape2D.set_shape(rectangleShape2D)
	
	var camera2d=Camera2D.new()
	camera2d.set_position_smoothing_enabled(true)
	camera2d.limit_left=limit_left
	camera2d.limit_right=limit_right
	_player.add_child(sprite)
	_player.add_child(collisionShape2D)
	_player.add_child(camera2d)
	_player.add_child(self)
	init_area(_player)
	parent.add_child(_player)
	pass


func get_input(delta):
	if _player.is_on_floor():
		_player.velocity.x = 0
	var right = Input.is_action_pressed('ui_right')&&!Input.is_action_pressed('ui_down')
	var left = Input.is_action_pressed('ui_left')&&!Input.is_action_pressed('ui_down')
	var jump = Input.is_action_pressed('ui_left_alt')&&!Input.is_action_pressed('ui_down')
	var down_jump = Input.is_action_pressed('ui_left_alt')&&Input.is_action_pressed('ui_down')

	if down_jump and _player.is_on_floor() and _down_jump_flag==false:
		_player.collision_mask=0
		_player.velocity.y -= 100
		_down_jump_flag=true
		pass
	elif jump and _player.is_on_floor():
		_player.velocity.y += -500
	if right and _player.is_on_floor():
		_player.velocity.x += PLAYER_VELOCITY_X
	if left and _player.is_on_floor():
		_player.velocity.x -= PLAYER_VELOCITY_X
	_player.velocity.x=clamp(_player.velocity.x,-PLAYER_VELOCITY_X,PLAYER_VELOCITY_X)

func _process(delta):
	get_input(delta)
		

func _physics_process(delta):
	_player.velocity.y += 800 * delta
	if _player.move_and_slide()==true &&_player.is_on_floor_only()==true:
		for i in _player.get_slide_collision_count():
			var collision = _player.get_slide_collision(i).get_collider()
			var layer=collision.get_meta("layer",0)
			_player.set_z_index(Common.composite_zindex(layer,1,1,1))
			_player.collision_mask=pow(2,layer)+pow(2,layer+8)
	elif _player.is_on_floor()==false and _down_jump_flag==false:
		_player.collision_mask=int((pow(2,8)-1))|_player.collision_mask
