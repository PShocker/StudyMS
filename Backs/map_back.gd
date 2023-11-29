extends Node2D
class_name MapBack

class MapBackDrawInfo extends RefCounted:
	var image_texture: ImageTexture
	var offset: Vector2
	var angle: float
	var flip: bool
	var a: float = 1
	var base_position: Vector2
	var tile_cnt_x: int
	var tile_cnt_y: int

var data: NXMapBack
var cx: int
var cy: int
var tile_x: bool
var tile_y: bool
var auto_move_x: bool
var auto_move_y: bool
var position_offset: Vector2
var elapsed_time: float
var animated_sprite: AnimatedSprite2D
var draw_info: MapBackDrawInfo

func _init(data: NXMapBack):
	self.data = data
	match self.data.type:
		0:
			self.tile_x = false
			self.tile_y = false
			self.auto_move_x = false
			self.auto_move_y = false
		1:
			self.tile_x = true
			self.tile_y = false
			self.auto_move_x = false
			self.auto_move_y = false
		2:
			self.tile_x = false
			self.tile_y = true
			self.auto_move_x = false
			self.auto_move_y = false
		3:
			self.tile_x = true
			self.tile_y = true
			self.auto_move_x = false
			self.auto_move_y = false
		4:
			self.tile_x = true
			self.tile_y = false
			self.auto_move_x = true
			self.auto_move_y = false
		5:
			self.tile_x = false
			self.tile_y = true
			self.auto_move_x = false
			self.auto_move_y = true
		6:
			self.tile_x = true
			self.tile_y = true
			self.auto_move_x = true
			self.auto_move_y = false
		7:
			self.tile_x = true
			self.tile_y = true
			self.auto_move_x = false
			self.auto_move_y = true

	self.cx = self.data.cx
	if self.cx == 0:
		self.cx = int(self.data.rect.size.x)
	self.cy = self.data.cy
	if self.cy == 0:
		self.cy = int(self.data.rect.size.y)


func _ready():
	if self.data.ani == NXMapBack.ANIMATION:
		var sprite_frames := SpriteFrames.new()
		var animation := "default"
		sprite_frames.set_animation_loop(animation, true)
		sprite_frames.set_animation_speed(animation, Constants.ANIMATION_FPS)
		for frame in self.data.animation.frames:
			sprite_frames.add_frame(animation, Globals.EmptyTexture, Constants.ANIMATION_FPS * frame.delay)
		self.animated_sprite = AnimatedSprite2D.new()
		self.animated_sprite.sprite_frames = sprite_frames
		self.animated_sprite.autoplay = animation
		self.add_child(self.animated_sprite)
	
func _process(delta: float) -> void:
	var camera = self.get_viewport().get_camera_2d()
	var viewport_center = camera.get_screen_center_position() if camera != null else Vector2()
	var viewport_rect_left = viewport_center.x - get_viewport_rect().size.x / 2
	var viewport_rect_top = viewport_center.y - get_viewport_rect().size.y / 2
	var viewport_rect_right = viewport_center.x + get_viewport_rect().size.x / 2
	var viewport_rect_bottom = viewport_center.y + get_viewport_rect().size.y / 2
	
	var sprite_rect = self.data.rect
	var sprite_rect_right = sprite_rect.position.x + sprite_rect.size.x
	var sprite_rect_bottom = sprite_rect.position.y + sprite_rect.size.y

	if self.auto_move_x:
		self.position_offset.x = self.position_offset.x + self.data.rx * 5 * delta
		self.position_offset.x = self.position_offset.x - floor(self.position_offset.x / self.cx) * self.cx
	else:
		# parallax scroll by following camera center
		# rx = -100: fixed in map
		# rx = 0: sync with camera
		# rx = 100: faster than camera
		self.position_offset.x = (viewport_center.x - 0) * (self.data.rx + 100) / 100.0
	
	if self.auto_move_y:
		self.position_offset.y = self.position_offset.y + self.data.ry * 5 * delta
		self.position_offset.y = self.position_offset.y - floor(self.position_offset.y / self.cy) * self.cy
	else:
		self.position_offset.y = (viewport_center.y - 0) * (self.data.ry + 100) / 100.0	

	var base_position = Vector2(self.data.x + self.position_offset.x, self.data.y + self.position_offset.y)
	var angle: float = 0.0
	
	var tile_cnt_x = 1
	var tile_cnt_y = 1
	var tile_start_left: int
	var tile_start_right: int
	var tile_start_top: int
	var tile_start_bottom: int
	if self.tile_x and self.cx > 0:
		tile_start_right = int(base_position.x + sprite_rect_right - viewport_rect_left) % self.cx
		if tile_start_right <= 0:
			tile_start_right = tile_start_right + self.cx
		tile_start_right = tile_start_right + viewport_rect_left
	
		tile_start_left = tile_start_right - sprite_rect.size.x
		if tile_start_left >= viewport_rect_right:
			tile_cnt_x = 0
		else:
			tile_cnt_x = ceil((viewport_rect_right - tile_start_left) / float(self.cx))
			base_position.x = tile_start_left - sprite_rect.position.x
	if self.tile_y and self.cy > 0:
		tile_start_bottom = int(base_position.y + sprite_rect_bottom - viewport_rect_top) % self.cy
		if tile_start_bottom <= 0:
			tile_start_bottom = tile_start_bottom + self.cy
		tile_start_bottom = tile_start_bottom + viewport_rect_top
	
		tile_start_top = tile_start_bottom - sprite_rect.size.y
		if tile_start_top >= viewport_rect_bottom:
			tile_cnt_y = 0
		else:
			tile_cnt_y = ceil((viewport_rect_bottom - tile_start_top) / float(self.cy))
			base_position.y = tile_start_top - sprite_rect.position.y
	
	if self.data.ani == NXMapBack.ANIMATION and self.data.animation.frames[0].move_type > 0:
		self.elapsed_time = self.elapsed_time + delta
		match self.data.animation.frames[0].move_type:
			NXFrame.MOVE_TYPE.SIN_X:
				base_position.x = base_position.x + (self.data.animation.frames[0].move_w) * sin(2 * PI * self.move_type_elapsed_time * 1000 / self.data.animation.frames[0].move_p)
			NXFrame.MOVE_TYPE.SIN_Y:
				base_position.y = base_position.y + (self.data.animation.frames[0].move_h) * sin(2 * PI * self.move_type_elapsed_time * 1000 / self.data.animation.frames[0].move_p)
			NXFrame.MOVE_TYPE.ROTATION:
				angle = 2 * PI * self.elapsed_time * 1000 / self.data.animation.frames[0].move_r
		
	var draw_info := MapBackDrawInfo.new()
	draw_info.base_position = base_position
	draw_info.angle = angle
	draw_info.tile_cnt_x = tile_cnt_x
	draw_info.tile_cnt_y = tile_cnt_y
	draw_info.flip = self.data.flip
	match self.data.ani:
		NXMapBack.IMAGE_TEXTURE:
			draw_info.image_texture = self.data.image_texture.image_texture
			draw_info.offset = self.data.image_texture.offset
		NXMapBack.ANIMATION:
			var frame := self.data.animation.frames[self.animated_sprite.frame]
			draw_info.image_texture = frame.image_texture
			draw_info.offset = frame.offset
			draw_info.a = (frame.a1 - frame.a0) * self.animated_sprite.frame_progress + frame.a0
	self.draw_info = draw_info
	
	self.queue_redraw()

func _draw() -> void:
	if self.draw_info == null:
		return
		
	for j in range(self.draw_info.tile_cnt_y):
		for i in range(self.draw_info.tile_cnt_x):
			var tile_position := Vector2(self.draw_info.base_position.x + i * self.cx, self.draw_info.base_position.y + j * self.cy)
			if self.draw_info.flip:
				tile_position.x = tile_position.x * -1
				self.draw_set_transform(Vector2.ZERO, self.draw_info.angle, Vector2(-1, 1))
			else:
				self.draw_set_transform(Vector2.ZERO, self.draw_info.angle, Vector2(1, 1))
			tile_position = tile_position.rotated(-self.draw_info.angle)
			tile_position = tile_position + self.draw_info.offset
			self.draw_texture(self.draw_info.image_texture, tile_position, Color(1, 1, 1, self.draw_info.a))
