extends TextureButton

var item_data: AccessoryData

signal item_claimed(item)


func setup(item: AccessoryData):
	item_data = item
	texture_normal = item.item_texture
	


func _on_mouse_entered():
	get_tree().get_first_node_in_group("tooltip").display_item(item_data)
	if self.disabled == false:
		self.scale = Vector2(1.2, 1.2)


func _on_mouse_exited():
	get_tree().get_first_node_in_group("tooltip").hide_tooltip()
	self.scale = Vector2(1.0, 1.0)


func _on_pressed():
	item_claimed.emit(item_data)
	disabled = true
	modulate.a = 0.3
	self.scale = Vector2(1.0, 1.0)
	
	get_tree().get_first_node_in_group("tooltip").hide_tooltip()
