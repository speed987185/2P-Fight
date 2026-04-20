shader_type canvas_item;

uniform float speed = 1.2;
uniform float strength = 0.03;
uniform float scale = 8.0;

uniform vec2 ripple_center = vec2(0.5, 0.5);
uniform float ripple_time = 0.0;

void fragment() {
    vec2 uv = UV;
    float t = TIME * speed;

    float w1 = sin(uv.x * scale + t);
    float w2 = cos(uv.y * scale * 0.7 + t * 1.3);
    float w3 = sin((uv.x + uv.y) * scale * 0.5 + t * 0.8);

    vec2 flow = vec2(w1 + w3, w2);
    uv += flow * strength;

    float dist = distance(uv, ripple_center);
    float life = smoothstep(1.5, 0.0, ripple_time);

    float ripple_wave = sin(dist * 25.0 - ripple_time * 6.0);
    float ripple_mask = smoothstep(0.35, 0.0, dist);

    uv += normalize(uv - ripple_center) * ripple_wave * ripple_mask * 0.04 * life;

    float ring = smoothstep(0.02, 0.0, abs(ripple_wave)) * ripple_mask * life;

    float rt = TIME * 0.8;
    vec3 rainbow = vec3(
        sin(rt * 3.0) * 0.5 + 0.5,
        sin(rt * 3.0 + 2.0) * 0.5 + 0.5,
        sin(rt * 3.0 + 4.0) * 0.5 + 0.5
    );
    vec3 pink_base = vec3(1.0, 0.4, 0.7);
    vec3 mid = mix(pink_base, rainbow, 0.45);
    vec3 deep = mix(mid * 0.5, vec3(0.8, 0.1, 0.4), 0.5);
    vec3 light = min(mid + vec3(0.3, 0.2, 0.3), vec3(1.0));

    float depth = (w1 + w2 + w3) * 0.3 + 0.5;
    vec3 color = mix(deep, mid, depth);
    color = mix(color, light, pow(depth, 3.0));

    float highlight = smoothstep(0.4, 1.0, w1 * 0.5 + 0.5);
    color += highlight * 0.15;

    color -= ring * 0.5;

    COLOR = vec4(color, 1.0);
}