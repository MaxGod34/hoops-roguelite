shader_type canvas_item;
render_mode unshaded;
// Outline Settings
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width: hint_range(0.0, 10.0) = 2.0;

// Instability / Energy Settings
uniform float wobble_speed : hint_range(0.0, 20.0) = 5.0;
uniform float wobble_intensity : hint_range(0.0, 0.1) = 0.01;

void fragment() {
	// 1. Energy Ripple
	vec2 distorted_uv = UV;
	// Use sine wave combined with TIME to make it continuously wave
	distorted_uv.x += sin(UV.y * 10.0 * TIME * wobble_speed) * wobble_intensity;
	// Sample PNG using new wavy coordinates
	vec4 base_color = texture(TEXTURE, distorted_uv);
	
	// Multiply by the Sprite2D's Modulate color so color picking still works
	base_color *= COLOR;
	
	// 2. Procedural Outline
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	float alpha_surround = 0.0;
	
	// Look Up, Down, Left, Right, and Diagonals
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(-size.x, 0.0)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(size.x, 0.0)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(0.0, -size.y)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(0.0, size.y)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(-size.x, -size.y)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(size.x, -size.y)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(-size.x, size.y)).a;
	alpha_surround += texture(TEXTURE, distorted_uv + vec2(size.x, size.y)).a;
	
	// If the current pixel is transparent, but it's touching a solid pixel, draw the outline
	if (base_color.a == 0.0 && alpha_surround > 0.0){
		COLOR = outline_color;
	} else {
		COLOR = base_color;
	}
}
