shader_type canvas_item;

uniform float offset = 0.0;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    float avg = (COLOR.r + COLOR.g + COLOR.b) / 3.0 + offset;
    COLOR.rgb = vec3(avg);
}