extends Node2D
class_name Objs;

var _animatedSprite2D;
var _offset=[];

# Called when the node enters the scene tree for the first time.
func sprite_frames_changed():
	_animatedSprite2D.set_offset(_offset[_animatedSprite2D.frame])


func _ready():
	pass
		
func _init(parent,obj):
	var frames=obj['Resource']['Frames']
	var animatedSprite2D=AnimatedSprite2D.new()
	var node = Sprite2D.new()
	var spriteFrames=SpriteFrames.new()
	for frame in frames:
		spriteFrames.add_frame("default",load("res://"+frame['ResourceUrl']))
		_offset.push_back(Vector2(-frame['OriginX'],-frame['OriginY']))
	animatedSprite2D.set_sprite_frames(spriteFrames)
	animatedSprite2D.set_position(Vector2(obj['X'], obj['Y']))
	animatedSprite2D.set_centered(false)
	animatedSprite2D.play()
	animatedSprite2D.connect("frame_changed", sprite_frames_changed)
	_animatedSprite2D=animatedSprite2D
	parent.add_child(animatedSprite2D)
