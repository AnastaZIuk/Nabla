#ifndef _IRR_BUILTIN_GLSL_WORKGROUP_VOTE_INCLUDED_
#define _IRR_BUILTIN_GLSL_WORKGROUP_VOTE_INCLUDED_



#include <irr/builtin/glsl/workgroup/shared_vote.glsl>



#ifdef _IRR_GLSL_SCRATCH_SHARED_DEFINED_
	#if IRR_GLSL_EVAL(_IRR_GLSL_SCRATCH_SHARED_SIZE_DEFINED_)<IRR_GLSL_EVAL(_IRR_GLSL_WORKGROUP_VOTE_SHARED_SIZE_NEEDED_)
		#error "Not enough shared memory declared"
	#endif
#else
	#if _IRR_GLSL_WORKGROUP_VOTE_SHARED_SIZE_NEEDED_>0
		#define _IRR_GLSL_SCRATCH_SHARED_DEFINED_ irr_glsl_workgroupVoteScratchShared
		#define _IRR_GLSL_SCRATCH_SHARED_SIZE_DEFINED_ _IRR_GLSL_WORKGROUP_VOTE_SHARED_SIZE_NEEDED_
		shared uint _IRR_GLSL_SCRATCH_SHARED_DEFINED_[_IRR_GLSL_WORKGROUP_VOTE_SHARED_SIZE_NEEDED_];
	#endif
#endif


bool irr_glsl_workgroupAll_noBarriers(in bool value)
{
	// TODO: Optimization using subgroupAll in an ifdef IRR_GL_something (need to do feature mapping first), probably only first 2 lines need to change
	_IRR_GLSL_SCRATCH_SHARED_DEFINED_[0u] = 1u;
	barrier();
	memoryBarrierShared();
	atomicAnd(_IRR_GLSL_SCRATCH_SHARED_DEFINED_[0u],value ? 1u:0u);
	barrier();

	return _IRR_GLSL_SCRATCH_SHARED_DEFINED_[0u]!=0u;
}
bool irr_glsl_workgroupAll(in bool value)
{
	barrier();
	memoryBarrierShared();
	const bool retval = irr_glsl_workgroupAll_noBarriers(value);
	barrier();
	return retval;
}

bool irr_glsl_workgroupAny_noBarriers(in bool value)
{
	// TODO: Optimization using subgroupAny in an ifdef IRR_GL_something (need to do feature mapping first), probably only first 2 lines need to change
	_IRR_GLSL_SCRATCH_SHARED_DEFINED_[0u] = 0u;
	barrier();
	memoryBarrierShared();
	atomicOr(_IRR_GLSL_SCRATCH_SHARED_DEFINED_[0u],value ? 1u:0u);
	barrier();

	return _IRR_GLSL_SCRATCH_SHARED_DEFINED_[0u]!=0u;
}
bool irr_glsl_workgroupAny(in bool value)
{
	barrier();
	memoryBarrierShared();
	const bool retval = irr_glsl_workgroupAny_noBarriers(value);
	barrier();
	return retval;
}

/** TODO @Cyprian or @Anastazluk
bool irr_glsl_workgroupAllEqual(in bool val);
float irr_glsl_workgroupAllEqual(in float val);
uint irr_glsl_workgroupAllEqual(in uint val);
int irr_glsl_workgroupAllEqual(in int val);
**/


#endif
