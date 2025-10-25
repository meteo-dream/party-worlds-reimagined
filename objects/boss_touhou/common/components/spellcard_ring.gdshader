shader_type canvas_item;
render_mode blend_add; // Uncomment this to make the ring additive.

instance uniform float thickness : hint_range(0, 1) = 0.1;
instance uniform float spin_speed : hint_range(-10, 10, 0.1) = 0.2;
instance uniform float repeat_count : hint_range(1, 30, 1) = 16.0;

instance uniform float source_thickness : hint_range(0.0, 1.0) = 0.125;
instance uniform float source_offset : hint_range(0.0, 1.0) = 0.0;

// Gets general uv coordinates and converts them to specific texture regions
vec2 get_texture_region(vec2 uv) {
    return vec2(source_offset + source_thickness * (1.0 - uv.y), (1.0 - uv.x));
}

// Converts raw angle and radius to appropriate uv values
vec2 get_polar_uv(float theta, float r) {
    return vec2(mod((theta + PI) / TAU * repeat_count, 1.0), (thickness - 1.0 + r) / thickness);
	// return vec2(mod((theta + PI) / TAU * repeat_count - TIME * spin_speed, 1.0), (thickness - 1.0 + r) / thickness);
}

void fragment() {
    // Offset UV to make conversion to polar coordinates easier
    vec2 uv_offset = 2.0 * UV - vec2(1.0);

    // Convert to polar coordinates
    float r = sqrt(uv_offset.x * uv_offset.x + uv_offset.y * uv_offset.y);
    float theta = atan(uv_offset.y, uv_offset.x);

    // Use polar coordinates to get uv values 
    vec2 polar_uv = get_polar_uv(theta, r);

    // Get uv for the region of the texture we want
    vec2 uv = get_texture_region(polar_uv);

    // Sample our texture with our new uvs
    vec4 color = texture(TEXTURE, uv);
    // Set the pixel colour to the value we got from the texture
    COLOR = color;

    // Have the sprite be transparent if beyond bounds
    if (polar_uv.y <= 0.0 || polar_uv.y >= 1.0) {
        COLOR.a = 0.0;
    }
}