extends Node2D
class_name Backs;

var _backs
var _tilemode
var _texture
var _x: int
var _y: int
var _cx: int
var _cy: int
var _rx: int
var _ry: int
var _position
var _offset
var _width
var _height
var _size

var _position_offset_x = 0;
var _position_offset_y = 0;
	
var _draw_info={}
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
	layerNode.layer=backs['ID']-100
	layerNode.set_follow_viewport(true)
	parent.add_child(layerNode)
	layerNode.add_child(self)
	_texture=load("res://"+_backs['Resource']['ResourceUrl'])
	_width=_backs['Resource']['Width']
	_height=_backs['Resource']['Height']
	_x=backs['X']
	_y=backs['Y']
	_cx=backs['Cx']
	_cy=backs['Cy']
	if _cx == 0:
		_cx = _width
	if _cy == 0:
		_cy = _height
	_rx=backs['Rx']
	_ry=backs['Ry']
	_position=Vector2(_x,_y)
	_offset=Vector2(-_backs['Resource']['OriginX'],-_backs['Resource']['OriginY'])
	_size=Vector2(_width,_height)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var camera = get_viewport().get_camera_2d()
	var viewport_center = camera.get_screen_center_position() if camera != null else Vector2()
	var viewport_rect_left = viewport_center.x - get_viewport_rect().size.x / 2
	var viewport_rect_top = viewport_center.y - get_viewport_rect().size.y / 2
	var viewport_rect_right = viewport_center.x + get_viewport_rect().size.x / 2
	var viewport_rect_bottom = viewport_center.y + get_viewport_rect().size.y / 2
	
	if _tilemode['auto_scroll_x'] == true :
		_position_offset_x += (_rx  * 5.0 * delta)
		_position_offset_x -= floor(_position_offset_x / _cx) * _cx
#		_position_offset_x = int(_position_offset_x) %_cx
	else:
		_position_offset_x = (viewport_center.x - 0) * (_rx + 100) / 100.0
		
	if _tilemode['auto_scroll_y'] == true :
		_position_offset_y += (_ry  * 5.0 * delta)
		_position_offset_y -= floor(_position_offset_y / _cy) * _cy
#		_position_offset_y = int(_position_offset_y) %_cy
	else:
		_position_offset_y = (viewport_center.y - 0) * (_ry + 100) / 100.0
	
	var base_position = Vector2(_x + _position_offset_x, _y + _position_offset_y)
	
	var sprite_rect = Rect2(_offset,_size)
	var sprite_rect_right = sprite_rect.position.x + sprite_rect.size.x
	var sprite_rect_bottom = sprite_rect.position.y + sprite_rect.size.y
	var tile_cnt_x = 1
	var tile_cnt_y = 1
	var tile_start_left: int
	var tile_start_right: int
	var tile_start_top: int
	var tile_start_bottom: int
	if _tilemode['tile_x']==true and _cx > 0:
		tile_start_right = int(base_position.x + sprite_rect_right - viewport_rect_left) % _cx
		if tile_start_right <= 0:
			tile_start_right = tile_start_right + _cx
		tile_start_right = tile_start_right + viewport_rect_left
	
		tile_start_left = tile_start_right - sprite_rect.size.x
		if tile_start_left >= viewport_rect_right:
			tile_cnt_x = 0
		else:
			tile_cnt_x = ceil((viewport_rect_right - tile_start_left) / float(_cx))
			base_position.x = tile_start_left - sprite_rect.position.x
#			
			
	if _tilemode['tile_y']==true and _cy > 0:
		tile_start_bottom = int(base_position.y + sprite_rect_bottom - viewport_rect_top) % _cy
		if tile_start_bottom <= 0:
			tile_start_bottom = tile_start_bottom + _cy
		tile_start_bottom = tile_start_bottom + viewport_rect_top
	
		tile_start_top = tile_start_bottom - sprite_rect.size.y
		if tile_start_top >= viewport_rect_bottom:
			tile_cnt_y = 0
		else:
			tile_cnt_y = ceil((viewport_rect_bottom - tile_start_top) / float(_cy))
			base_position.y = tile_start_top - sprite_rect.position.y
			
	_draw_info.base_position = base_position
	_draw_info.tile_cnt_x = tile_cnt_x
	_draw_info.tile_cnt_y = tile_cnt_y
	_draw_info.angle = 0
	_draw_info.flip = false
	_draw_info.offset = _offset
	queue_redraw()
	pass


func _draw():
	if _draw_info == {}:
		return
#	print(_draw_info.tile_cnt_y)
	
	for j in range(_draw_info.tile_cnt_y):
		for i in range(_draw_info.tile_cnt_x):
			var tile_position = Vector2(_draw_info.base_position.x + i * _cx, _draw_info.base_position.y + j * _cy)
			if _draw_info.flip:
				tile_position.x = tile_position.x * -1
				self.draw_set_transform(Vector2.ZERO, _draw_info.angle, Vector2(-1, 1))
			else:
				self.draw_set_transform(Vector2.ZERO, _draw_info.angle, Vector2(1, 1))
				
			tile_position = tile_position + _draw_info.offset
			draw_texture(_texture, tile_position)

	
