extends CharacterBody2D

enum {IDLE, RUN, JUMP}
var state
var anim
var new_anim
var layer
var timer
var _foothold

var _down_jump_flag=false

const PLAYER_VELOCITY_X=400


func _ready():
	change_state(IDLE)
	init_timer()

func _on_timer_timeout() -> void:
	_down_jump_flag=false
	
func init_timer():
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.6
	timer.one_shot = true
	timer.connect("timeout",_on_timer_timeout)
	
func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			new_anim = 'idle'
		RUN:
			new_anim = 'run'
		JUMP:
			new_anim = 'jump_up'

func get_input(delta):
	if is_on_floor():
		velocity.x = 0
	var right = Input.is_action_pressed('ui_right')&&!Input.is_action_pressed('ui_down')
	var left = Input.is_action_pressed('ui_left')&&!Input.is_action_pressed('ui_down')
	var jump = Input.is_action_pressed('ui_left_alt')&&!Input.is_action_pressed('ui_down')
	var down_jump = Input.is_action_just_pressed('ui_left_alt')&&Input.is_action_pressed('ui_down')

	if down_jump and is_on_floor() and _down_jump_flag==false:
		self.collision_mask=0
		_down_jump_flag=true
		velocity.y -= 100
		timer.start()
		pass
	elif jump and is_on_floor():
		change_state(JUMP)
		velocity.y += -500
			
	if right and is_on_floor():
		change_state(RUN)
		velocity.x += PLAYER_VELOCITY_X
	if left and is_on_floor():
		change_state(RUN)
		velocity.x -= PLAYER_VELOCITY_X
	velocity.x=clamp(velocity.x,-PLAYER_VELOCITY_X,PLAYER_VELOCITY_X)
	if !right and !left and state == RUN:
		change_state(IDLE)

func _process(delta):
	get_input(delta)
	if new_anim != anim:
		anim = new_anim
	#if is_on_floor()==false:
		

func _physics_process(delta):
	velocity.y += 800 * delta
	if state == JUMP:
		if is_on_floor():
			change_state(IDLE)
	if move_and_slide()==true:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i).get_collider()
			var layer=collision.get_meta("layer","")
			var type=collision.get_meta("type","")
			if type=="floor":
				_foothold=collision
			if str(layer) != "":#当碰撞体无layer时
				set_z_index(Common.composite_zindex(layer,1,1,1))
				if  is_on_floor()==true:
					self.collision_mask=pow(2,layer)
	elif is_on_floor()==false and _down_jump_flag==false:
		self.collision_mask=Common.ALL_MASK-pow(2,31)
