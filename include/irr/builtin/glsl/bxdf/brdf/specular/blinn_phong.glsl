#ifndef _IRR_BSDF_BRDF_SPECULAR_BLINN_PHONG_INCLUDED_
#define _IRR_BSDF_BRDF_SPECULAR_BLINN_PHONG_INCLUDED_

#include <irr/builtin/glsl/bxdf/common.glsl>
#include <irr/builtin/glsl/bxdf/common_samples.glsl>
#include <irr/builtin/glsl/bxdf/brdf/specular/ndf/blinn_phong.glsl>
#include <irr/builtin/glsl/bxdf/brdf/specular/geom/smith.glsl>

//conversion between alpha and Phong exponent, Walter et.al.
float irr_glsl_phong_exp_to_alpha2(in float n)
{
    return 2.0/(n+2.0);
}
//+INF for a2==0.0
float irr_glsl_alpha2_to_phong_exp(in float a2)
{
    return 2.0/a2 - 2.0;
}

//https://zhuanlan.zhihu.com/p/58205525
//only NDF sampling
//however we dont really care about phong sampling
irr_glsl_BSDFSample irr_glsl_blinn_phong_cos_generate(in irr_glsl_AnisotropicViewSurfaceInteraction interaction, in vec2 _sample, in float n)
{
    vec2 u = _sample;

    mat3 m = irr_glsl_getTangentFrame(interaction);

    float phi = 2.0*irr_glsl_PI*u.y;
    float cosTheta = pow(u.x, 1.0/(n+1.0));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    vec3 H = vec3(cosPhi*sinTheta, sinPhi*sinTheta, cosTheta);
    vec3 localV = interaction.isotropic.V.dir*m;

	return irr_glsl_createBSDFSample(H,localV,dot(H,localV),m);
}

/*
vec3 irr_glsl_blinn_phong_dielectric_cos_remainder_and_pdf(out float pdf, in irr_glsl_BSDFSample s, in irr_glsl_IsotropicViewSurfaceInteraction interaction, in float n, in vec3 ior)
{
	pdf = (n+1.0)*0.5*irr_glsl_RECIPROCAL_PI * 0.25*pow(s.NdotH,n)/s.VdotH;

    vec3 fr = irr_glsl_fresnel_dielectric(ior, s.VdotH);
    return fr * s.NdotL * (n*(n + 6.0) + 8.0) * s.VdotH / ((pow(0.5,0.5*n) + n) * (n + 1.0));
}

vec3 irr_glsl_blinn_phong_conductor_cos_remainder_and_pdf(out float pdf, in irr_glsl_BSDFSample s, in irr_glsl_IsotropicViewSurfaceInteraction interaction, in float n, in mat2x3 ior)
{
	pdf = (n+1.0)*0.5*irr_glsl_RECIPROCAL_PI * 0.25*pow(s.NdotH,n)/s.VdotH;

    vec3 fr = irr_glsl_fresnel_conductor(ior[0], ior[1], s.VdotH);
    return fr * s.NdotL * (n*(n + 6.0) + 8.0) * s.VdotH / ((pow(0.5,0.5*n) + n) * (n + 1.0));
}
*/

float irr_glsl_blinn_phong_cos_eval_DG(in irr_glsl_BSDFIsotropicParams params, in irr_glsl_IsotropicViewSurfaceInteraction inter, in float n, in float a2)
{
    float d = irr_glsl_blinn_phong(params.NdotH, n);
    float scalar_part = d/(4.0*inter.NdotV);
    if (a2>FLT_MIN)
    {
        float g = irr_glsl_beckmann_smith_correlated(inter.NdotV_squared, params.NdotL_squared, a2);
        scalar_part *= g;
    }
    return scalar_part;
}
vec3 irr_glsl_blinn_phong_cos_eval(in irr_glsl_BSDFIsotropicParams params, in irr_glsl_IsotropicViewSurfaceInteraction inter, in float n, in mat2x3 ior, in float a2)
{
    float scalar_part = irr_glsl_blinn_phong_cos_eval_DG(params, inter, n, a2);
    return scalar_part*irr_glsl_fresnel_conductor(ior[0], ior[1], params.VdotH);
}
float irr_glsl_blinn_phong_cos_eval_DG(in irr_glsl_BSDFIsotropicParams params, in irr_glsl_IsotropicViewSurfaceInteraction inter, in float n)
{
    float a2 = irr_glsl_phong_exp_to_alpha2(n);
    return irr_glsl_blinn_phong_cos_eval_DG(params, inter, n, a2);
}
vec3 irr_glsl_blinn_phong_cos_eval(in irr_glsl_BSDFIsotropicParams params, in irr_glsl_IsotropicViewSurfaceInteraction inter, in float n, in mat2x3 ior)
{
    float a2 = irr_glsl_phong_exp_to_alpha2(n);
    return irr_glsl_blinn_phong_cos_eval(params, inter, n, ior, a2);
}

float irr_glsl_blinn_phong_cos_eval_DG(in irr_glsl_BSDFAnisotropicParams params, in irr_glsl_AnisotropicViewSurfaceInteraction inter, in float nx, in float ny, in float ax2, in float ay2)
{
    float NdotH2 = params.isotropic.NdotH*params.isotropic.NdotH;
    float d = irr_glsl_blinn_phong(params.isotropic.NdotH, 1.0/(1.0-NdotH2), params.TdotH*params.TdotH, params.BdotH*params.BdotH, nx, ny);
    float scalar_part = d/(4.0*inter.isotropic.NdotV);
    if (ax2>FLT_MIN || ay2>FLT_MIN)
    {
        float TdotV2 = inter.TdotV*inter.TdotV;
        float BdotV2 = inter.BdotV*inter.BdotV;
        float TdotL2 = params.TdotL*params.TdotL;
        float BdotL2 = params.BdotL*params.BdotL;
        float g = irr_glsl_beckmann_smith_correlated(TdotV2, BdotV2, inter.isotropic.NdotV_squared, TdotL2, BdotL2, params.isotropic.NdotL_squared, ax2, ay2);
        scalar_part *= g;
    }

    return scalar_part;
}
vec3 irr_glsl_blinn_phong_cos_eval(in irr_glsl_BSDFAnisotropicParams params, in irr_glsl_AnisotropicViewSurfaceInteraction inter, in float nx, in float ny, in mat2x3 ior, in float ax2, in float ay2)
{
    float scalar_part = irr_glsl_blinn_phong_cos_eval_DG(params, inter, nx, ny, ax2, ay2);

    return scalar_part*irr_glsl_fresnel_conductor(ior[0], ior[1], params.isotropic.VdotH);
}
float irr_glsl_blinn_phong_cos_eval_DG(in irr_glsl_BSDFAnisotropicParams params, in irr_glsl_AnisotropicViewSurfaceInteraction inter, in float nx, in float ny)
{
    float ax2 = irr_glsl_phong_exp_to_alpha2(nx);
    float ay2 = irr_glsl_phong_exp_to_alpha2(ny);

    return irr_glsl_blinn_phong_cos_eval_DG(params, inter, nx, ny, ax2, ay2);
}
vec3 irr_glsl_blinn_phong_cos_eval(in irr_glsl_BSDFAnisotropicParams params, in irr_glsl_AnisotropicViewSurfaceInteraction inter, in float nx, in float ny, in mat2x3 ior)
{
    float ax2 = irr_glsl_phong_exp_to_alpha2(nx);
    float ay2 = irr_glsl_phong_exp_to_alpha2(ny);

    return irr_glsl_blinn_phong_cos_eval(params, inter, nx, ny, ior, ax2, ay2);
}
#endif
