varying vec2 uv, coordMin, coordMax;
varying vec3 normal, tangent, binorm;
varying vec3 baseColor;
varying vec4 eyeDir;
uniform sampler2D diffuseMap;
uniform sampler2D normalMap;
uniform sampler2D lightMap;

// this is all a bit hackish and unoptimised but it looks fairly good
void main()
{
	vec2 offsMin, offsMax, uvMin, uvMax;

	offsMin = vec2(greaterThan(coordMin, vec2(0.5, 0.5))) * 0.25;
	offsMax = vec2(greaterThan(coordMax, vec2(0.5, 0.5))) * 0.25 + 0.25;

	uvMin   = mod(coordMin - offsMin, 0.5) + offsMin;
	uvMax   = mod(coordMax - offsMax, 0.5) + offsMax;

	vec2 huv = uv * uv * (3.0 - 2.0 * uv);

	vec4 cols[4];
	cols[0] = texture2D(diffuseMap, vec2(uvMin.x, uvMin.y));
	cols[1] = texture2D(diffuseMap, vec2(uvMax.x, uvMin.y));
	cols[2] = texture2D(diffuseMap, vec2(uvMin.x, uvMax.y));
	cols[3] = texture2D(diffuseMap, vec2(uvMax.x, uvMax.y));
	vec4 color   = mix(mix(cols[0], cols[1], huv.x), mix(cols[2], cols[3], huv.x), huv.y);

	vec3 nors[4];
	nors[0] = vec3(texture2D(normalMap, vec2(uvMin.x, uvMin.y))) * 2.0 - 1.0;
	nors[1] = vec3(texture2D(normalMap, vec2(uvMax.x, uvMin.y))) * 2.0 - 1.0;
	nors[2] = vec3(texture2D(normalMap, vec2(uvMin.x, uvMax.y))) * 2.0 - 1.0;
	nors[3] = vec3(texture2D(normalMap, vec2(uvMax.x, uvMax.y))) * 2.0 - 1.0;
	vec3 texNorm = normalize(mix(mix(nors[0], nors[1], huv.x), mix(nors[2], nors[3], huv.x), huv.y));

	vec3 tN  = normalize(tangent);
	vec3 bN  = normalize(binorm);
	vec3 nN  = normalize(normal);
	mat3 TBN = mat3(tN, bN, nN);

	color = color * vec4(baseColor, 1.0);

	vec3 eN  = normalize(vec3(eyeDir));

	vec3 diffuse  =     vec3(texture2D(lightMap, nN.xy   * 0.45 + 0.5));
	vec3 specular = pow(vec3(texture2D(lightMap, -reflect(eN, nN).xy * 0.45 + 0.5)), vec3(16.0));

	gl_FragColor = vec4(clamp(color.rgb * diffuse + specular, 0.0, 1.0), color.a);
}
