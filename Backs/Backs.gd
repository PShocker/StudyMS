extends Node
class_name Backs;

var _backs
var _tilemode

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _init(parent,backs):
	_backs=backs
	match backs['Type']:
		0:
			_tilemode={
				'tile_x': false,
				'tile_y': false,
				'auto_scroll_x': false,
				'auto_scroll_y': false,
			}
		1:
			_tilemode={
				'tile_x': true,
				'tile_y': false,
				'auto_scroll_x': false,
				'auto_scroll_y': false,
			}
		2:
			_tilemode={
				'tile_x': false,
				'tile_y': true,
				'auto_scroll_x': false,
				'auto_scroll_y': false,
			}
		3:
			_tilemode={
				'tile_x': true,
				'tile_y': true,
				'auto_scroll_x': false,
				'auto_scroll_y': false,
			}
		4:
			_tilemode={
				'tile_x': true,
				'tile_y': false,
				'auto_scroll_x': true,
				'auto_scroll_y': false,
			}
		5:
			_tilemode={
				'tile_x': false,
				'tile_y': true,
				'auto_scroll_x': false,
				'auto_scroll_y': true,
			}
		6:
			_tilemode={
				'tile_x': true,
				'tile_y': true,
				'auto_scroll_x': true,
				'auto_scroll_y': false,
			}
		7:
			_tilemode={
				'tile_x': true,
				'tile_y': true,
				'auto_scroll_x': false,
				'auto_scroll_y': true,
			}
	#初始化type后
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
