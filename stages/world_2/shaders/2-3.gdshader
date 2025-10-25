shader_type canvas_item;

uniform float wave_amplitude = 0.0;
uniform float wave_frequency = 0.0;
uniform float wave_speed = 1.0;

float calculate_diff(float uv, float amp, float freq, float spd){
    float diff_x = amp * sin((freq * uv) + (TIME * spd));
    return diff_x;
}

vec2 calculate_move(vec2 dir, float spd){
    vec2 move = dir * TIME;
    return move;
}


void fragment(){

    float wav_x = calculate_diff(UV.y, wave_amplitude, wave_frequency, wave_speed);


    if ( int( UV.y * 1.0 ) % 2 == 0)
    {

        wav_x = -wav_x;

    }


    vec4 textube = texture(TEXTURE, vec2(UV.x + wav_x, UV.y));


//    if (gba_transparency)
//    {
//
//        float copy_wav_x = -calculate_diff(UV.y, wave_amplitude, wave_frequency, wave_speed);
//        vec4 tex_copy;
//
//
//        if ( int( UV.y * height ) % 2 == 1)
//        {
//
//            copy_wav_x = -copy_wav_x;
//
//        }
//
//        if (gba_transparency_scroll_direction != vec2(0.0))
//        {
//
//            vec2 copy_move = calculate_move(gba_transparency_scroll_direction, gba_transparency_scroll_speed);
//            tex_copy = texture(TEXTURE, vec2(UV.x+def_x + copy_wav_x, UV.y+def_y + wav_y) + copy_move);
//
//        }
//        else tex_copy = texture(TEXTURE, vec2(UV.x+def_x + copy_wav_x, UV.y+def_y + wav_y) + move);
//
//
//        textube = mix(textube, tex_copy, gba_transparency_value);
//
//    }





    COLOR = textube;

}