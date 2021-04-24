#ifndef _NBL_GLSL_EXT_SCAN_DEFAULT_SWEEP_COMMON_GLSL_INCLUDED_

#ifndef _NBL_GLSL_WORKGROUP_SIZE_
#define _NBL_GLSL_WORKGROUP_SIZE_ 256
layout(local_size_x = _NBL_GLSL_WORKGROUP_SIZE_) in;
#endif

#ifndef _NBL_GLSL_EXT_SCAN_INPUT_SET_DEFINED_
#define _NBL_GLSL_EXT_SCAN_INPUT_SET_DEFINED_ 0
#endif

#ifndef _NBL_GLSL_EXT_SCAN_INPUT_BINDING_DEFINED_
#define _NBL_GLSL_EXT_SCAN_INPUT_BINDING_DEFINED_ 0
#endif

#ifndef _NBL_GLSL_EXT_SCAN_INPUT_DESCRIPTOR_DEFINED_

layout(set = _NBL_GLSL_EXT_SCAN_INPUT_SET_DEFINED_, binding = _NBL_GLSL_EXT_SCAN_INPUT_BINDING_DEFINED_, std430) buffer InoutBuffer
{
	// Todo: Make this type generic, so I can process int and floats as well
	// nbl_glsl_ext_SCAN_storage_t inout_values[];
	uint inout_values[];
};

#define _NBL_GLSL_EXT_SCAN_INPUT_DESCRIPTOR_DEFINED_
#endif

#include "nbl/builtin/glsl/ext/Scan/parameters_struct.glsl"
#include "nbl/builtin/glsl/ext/Scan/parameters.glsl"

#define STRIDED_IDX(i) (((i) + 1)*(nbl_glsl_ext_Scan_Parameters_t_getStride())-1)

#ifndef _NBL_GLSL_EXT_SCAN_PUSH_CONSTANTS_DEFINED_

layout(push_constant) uniform PushConstants
{
	layout(offset = 0) nbl_glsl_ext_Scan_Parameters_t params;
} pc;

#define _NBL_GLSL_EXT_SCAN_PUSH_CONSTANTS_DEFINED_
#endif

#ifndef _NBL_GLSL_EXT_SCAN_GET_PARAMETERS_DEFINED_
nbl_glsl_ext_Scan_Parameters_t nbl_glsl_ext_Scan_getParameters()
{
	return pc.params;
}
#define _NBL_GLSL_EXT_SCAN_GET_PARAMETERS_DEFINED_
#endif

#ifndef _NBL_GLSL_EXT_SCAN_SET_DATA_DEFINED_

void nbl_glsl_ext_Scan_setData(in uint idx, in uint val)
{
	if (gl_GlobalInvocationID.x < nbl_glsl_ext_Scan_Parameters_t_getElementCountPass())
		inout_values[idx] = val;
}

#define _NBL_GLSL_EXT_SCAN_SET_DATA_DEFINED_
#endif

#ifndef _NBL_GLSL_EXT_SCAN_GET_PADDED_DATA_DEFINED_

uint nbl_glsl_ext_Scan_getPaddedData(in uint idx, in uint pad_val, bool is_upsweep)
{
	uint data = pad_val;
	if (is_upsweep)
	{
		if (gl_GlobalInvocationID.x < nbl_glsl_ext_Scan_Parameters_t_getElementCountPass())
			data = inout_values[idx];
	}
	else
	{
		if (idx < nbl_glsl_ext_Scan_Parameters_t_getElementCountTotal())
			data = inout_values[idx];
	}

	return data;
}

#define _NBL_GLSL_EXT_SCAN_GET_PADDED_DATA_DEFINED_
#endif

#ifndef _NBL_GLSL_EXT_SCAN_BIN_OP_
#error "_NBL_GLSL_EXT_SCAN_BIN_OP_ must be defined!"
#endif

#include "nbl/builtin/glsl/macros.glsl"

#if NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 0)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepAnd
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepAnd
#elif NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 1)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepXor
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepXor
#elif NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 2)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepOr
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepOr
#elif NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 3)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepAdd
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepAdd
#elif NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 4)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepMul
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepMul
#elif NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 5)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepMin
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepMin
#elif NBL_GLSL_EQUAL(_NBL_GLSL_EXT_SCAN_BIN_OP_, 1 << 6)
#define _NBL_GLSL_EXT_SCAN_UPSWEEP_TYPE_ nbl_glsl_ext_Scan_upsweepMax
#define _NBL_GLSL_EXT_SCAN_DOWNSWEEP_TYPE_ nbl_glsl_ext_Scan_downsweepMax
#endif

#define _NBL_GLSL_EXT_SCAN_DEFAULT_SWEEP_COMMON_GLSL_INCLUDED_
#endif