extern number time;

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords) {
    vec2 uv = tex_coords; // ekran sabiti
    vec2 pos = uv * 8.0 + vec2(time * 0.05); // sabit gürültü, yavaş hareket
    float n = noise(pos);
    return vec4(vec3(n), 1.0);
}
