shader_type canvas_item;

uniform vec2 speed;
varying vec4 v_vertex_color;

void vertex() {
	v_vertex_color = COLOR;
}

void fragment() {
   COLOR = texture( TEXTURE, vec2(UV.x - TIME * speed.x, UV.y - TIME * speed.y) );
   COLOR.a *= v_vertex_color.a;
}