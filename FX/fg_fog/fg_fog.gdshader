shader_type canvas_item;

uniform sampler2D noise_texture: repeat_enable, filter_nearest;
uniform float density: hint_range(0.0, 1.0) = 1;
uniform vec2 speed = vec2(0.044, 0);
uniform float freq = 1.0;
void fragment() {
	vec2 uv = UV + speed * TIME;
	float noise = texture(noise_texture, uv).r;
	float fog = clamp(noise * 2.0 - freq, 0.0, 1.0);
	COLOR.a *= fog * density;
}
