extends Node


func normalize(z):
	var scale = 16;
	z = z+ scale/2
	z = max(0, min(z, scale - 1));
	return z;

func composite_zindex(z, z0, z1, z2):
	var scale = 16
	return ((normalize(z) * scale * scale * scale
		+ normalize(z0) * scale * scale
		+ normalize(z1) * scale
		+ normalize(z2)))/100;

func get_resource(i):
	var image := Image.new()
	image.load_png_from_buffer(Wz.GetResource(i))
	return ImageTexture.create_from_image(image)
