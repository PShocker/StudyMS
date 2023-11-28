extends Sprite2D
class_name Backs;

var _backs
var _tilemode

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _init(parent,backs):
	_backs=backs
	var type=backs['Type']
	if type==0:
		_tilemode={
			'tile_x': false,
			'tile_y': false,
			'auto_scroll_x': false,
			'auto_scroll_y': false,
		}
	if type==1:
		_tilemode={
			'tile_x': true,
			'tile_y': false,
			'auto_scroll_x': false,
			'auto_scroll_y': false,
		}
	if type==2:
		_tilemode={
			'tile_x': false,
			'tile_y': true,
			'auto_scroll_x': false,
			'auto_scroll_y': false,
		}
	if type==3:
		_tilemode={
			'tile_x': true,
			'tile_y': true,
			'auto_scroll_x': false,
			'auto_scroll_y': false,
		}
	if type==4:
		_tilemode={
			'tile_x': true,
			'tile_y': false,
			'auto_scroll_x': true,
			'auto_scroll_y': false,
		}
	if type==5:
		_tilemode={
			'tile_x': false,
			'tile_y': true,
			'auto_scroll_x': false,
			'auto_scroll_y': true,
		}
	if type==6:
		_tilemode={
			'tile_x': true,
			'tile_y': true,
			'auto_scroll_x': true,
			'auto_scroll_y': false,
		}
	if type==7:
		_tilemode={
			'tile_x': true,
			'tile_y': true,
			'auto_scroll_x': false,
			'auto_scroll_y': true,
		}
	#初始化type后
	var layerNode=CanvasLayer.new()
	layerNode.layer=-2
	parent.add_child(layerNode)
	layerNode.add_child(self)
	set_z_index(-1)
	set_centered(false)
	set_offset(Vector2(-_backs['Resource']['OriginX'], -_backs['Resource']['OriginY']))
	set_position(Vector2(_backs['X'], _backs['Y']))
	set_texture(load("res://"+_backs['Resource']['ResourceUrl']))
	#var view = sprite.get_viewport().get_camera_2d();
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	pass


func _draw():
	#draw_texture(load("res://"+_backs['Resource']['ResourceUrl']),Vector2(_backs['X'],_backs['Y']))
	pass
	
