varying vec2 uv, coordMin, coordMax;
varying vec4 eyeDir;
varying vec3 normal, tangent, binorm;
varying vec3 baseColor;

attribute vec3 in_tangent;
attribute vec2 in_size;

void main()
{
	uv = gl_MultiTexCoord0.xy;

	baseColor = vec3(gl_Color);

	vec4 vertex = gl_Vertex;
	vec2 scale  = in_size;
	coordMin = scale * uv;
	coordMax = 1.0 - scale * (1.0 - uv);

	normal  = normalize(gl_NormalMatrix * gl_Normal);
	tangent = normalize(gl_NormalMatrix * in_tangent);
	binorm  = normalize(cross(normal, tangent));

	vec4 view = gl_ModelViewMatrix * vertex;
	eyeDir = normalize(view);

	gl_Position = gl_ProjectionMatrix * view;
}
