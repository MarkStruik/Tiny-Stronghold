shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_tex : hint_albedo;
uniform vec4 albedo_color : source_color = vec4(1.0);

uniform int   shade_steps = 4;     // 3–6 looks nice
uniform float edge_soft   = 0.03;  // soften band edges (0 = hard toon)
uniform float rim_strength = 0.25; // 0–0.6
uniform float rim_power    = 2.0;  // 1–4
uniform float pastel_mix   = 0.2;  // 0–0.4 nudges toward softer colors

// desaturate a bit for pastel look
vec3 pastelize(vec3 c, float amt){
    float g = dot(c, vec3(0.299, 0.587, 0.114));
    return mix(c, vec3(g), amt);
}

void fragment() {
    vec3 albedo = albedo_color.rgb;
    if (TEXTURE_USED(albedo_tex)) {
        albedo *= texture(albedo_tex, UV).rgb;
    }
    ALBEDO    = pastelize(albedo, pastel_mix);
    METALLIC  = 0.0;
    SPECULAR  = 0.0;
    ROUGHNESS = 1.0; // matte
}

void light() {
    // per-light toon banding
    float ndl = max(dot(NORMAL, LIGHT_DIRECTION), 0.0);
    float stepf = floor(ndl * float(max(shade_steps,1))) / float(max(shade_steps-1,1));
    float toon  = smoothstep(stepf - edge_soft, stepf + edge_soft, ndl);

    // base lit color
    vec3 col = ALBEDO * LIGHT_COLOR.rgb * toon;

    // subtle rim light (view-facing edge)
    float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power) * rim_strength;
    col += rim * ALBEDO;

    LIGHT += col * ATTENUATION;
}
