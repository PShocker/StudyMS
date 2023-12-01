extends Node2D
class_name Objs;

var _animatedSprite2D;
var _offset=[];
var _z_index=[];
var _i;
# Called when the node enters the scene tree for the first time.
func sprite_frames_changed():
	_animatedSprite2D.set_offset(_offset[_animatedSprite2D.frame])
	_animatedSprite2D.set_z_index(Common.composite_zindex(_i,_z_index[_animatedSprite2D.frame].x,_z_index[_animatedSprite2D.frame].y,0))

func _ready():
	pass
		
func _init(parent,obj,i):
	_i=i
	var frames=obj['Resource']['Frames']
	var animatedSprite2D=AnimatedSprite2D.new()
	var node = Sprite2D.new()
	var spriteFrames=SpriteFrames.new()
	for frame in frames:
		spriteFrames.add_frame("default",load("res://"+frame['ResourceUrl']))
		_offset.push_back(Vector2(-frame['OriginX'],-frame['OriginY']))
		_z_index.push_back(Vector2(frame['Z'],obj['ID']))
	animatedSprite2D.set_sprite_frames(spriteFrames)
	animatedSprite2D.set_position(Vector2(obj['X'], obj['Y']))
	animatedSprite2D.set_centered(false)
	animatedSprite2D.play()
	animatedSprite2D.connect("frame_changed", sprite_frames_changed)
	_animatedSprite2D=animatedSprite2D
	parent.add_child(animatedSprite2D)
