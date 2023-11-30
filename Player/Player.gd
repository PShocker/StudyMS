extends CharacterBody2D

enum {IDLE, RUN, JUMP}
var state
var anim
var new_anim

func _ready():
	change_state(IDLE)

func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			new_anim = 'idle'
		RUN:
			new_anim = 'run'
		JUMP:
			new_anim = 'jump_up'

func get_input():
	velocity.x = 0
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_select')

	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = 200
	if right:
		change_state(RUN)
		velocity.x += 400
	if left:
		change_state(RUN)
		velocity.x -= 400
	if !right and !left and state == RUN:
		change_state(IDLE)

func _process(delta):
	get_input()
	if new_anim != anim:
		anim = new_anim

func _physics_process(delta):
	velocity.y += 200 * delta
	if state == JUMP:
		if is_on_floor():
			change_state(IDLE)
	move_and_slide()

