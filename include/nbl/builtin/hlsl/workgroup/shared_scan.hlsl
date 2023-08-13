// Copyright (C) 2023 - DevSH Graphics Programming Sp. z O.O.
// This file is part of the "Nabla Engine".
// For conditions of distribution and use, see copyright notice in nabla.h
#ifndef _NBL_BUILTIN_HLSL_WORKGROUP_SHARED_SCAN_INCLUDED_
#define _NBL_BUILTIN_HLSL_WORKGROUP_SHARED_SCAN_INCLUDED_

#include "nbl/builtin/hlsl/workgroup/scratch.hlsl"
#include "nbl/builtin/hlsl/workgroup/broadcast.hlsl"
#include "nbl/builtin/hlsl/glsl_compat/glsl_compat.hlsl"

namespace nbl 
{
namespace hlsl
{
namespace workgroup
{

template<typename T, class SubgroupOp, class SharedAccessor>
struct WorkgroupScanHead
{
    bool isScan;
    T identity;
	T firstLevelScan;
    uint itemCount;
    uint lastInvocation;
    uint lastInvocationInLevel;
    uint scanStoreIndex;

    static WorkgroupScanHead create(bool isScan, T identity, uint itemCount)
    {
        WorkgroupScanHead<T, SubgroupOp, SharedAccessor> wsh;
        wsh.isScan = isScan;
        wsh.identity = identity;
        wsh.itemCount = itemCount;
        wsh.lastInvocation = itemCount - 1u;
        return wsh;
    }

    T operator()(T value)
    {
        subgroup::ScratchOffsetsAndMasks offsetsAndMasks = subgroup::ScratchOffsetsAndMasks::WithSubgroupOpDefaults();
        SharedAccessor sharedAccessor;
        subgroup::scratchInitialize<SharedAccessor, T>(value, identity, itemCount);
        lastInvocationInLevel = lastInvocation;
		scanStoreIndex = Broadcast<T, SharedAccessor>(offsetsAndMasks.scanStoreOffset, lastInvocation) + gl_LocalInvocationIndex + 1u;
		
        SubgroupOp subgroupOp;
        firstLevelScan = subgroupOp(value);
        T scan = firstLevelScan;
		
        const bool isLastSubgroupInvocation = offsetsAndMasks.subgroupInvocation == offsetsAndMasks.subgroupMask; // last invocation in subgroup
		
		// Since we are scanning the RESULT of the initial scan (which paired one input per subgroup invocation) 
		// every group of 64 invocations has been coallesced into 1 result value. This means that the results of 
		// the first SubgroupSz^2 invocations will be processed by the first subgroup and so on.
		// Consequently, those first SubgroupSz^2 invocations will store their results on SubgroupSz scratch slots 
		// with halfSubgroupSz padding and the next level will follow the same + the previous as an `offset`.
		const uint offset = (gl_LocalInvocationIndex >> subgroup::SizeLog2()) & ~offsetsAndMasks.subgroupMask;
		const uint memBegin = (offset >> subgroup::SizeLog2()) * offsetsAndMasks.halfSubgroupSize + offset;
        const uint nextLevelStoreIndex = memBegin + offsetsAndMasks.halfSubgroupSize + offsetsAndMasks.subgroupId;
        
		bool participate = gl_LocalInvocationIndex <= lastInvocationInLevel;
        while(lastInvocationInLevel >= subgroup::Size() * subgroup::Size())
    	{
    		glsl::barrier();
    		if(participate)
    		{
    			if (any(bool2(gl_LocalInvocationIndex == lastInvocationInLevel, isLastSubgroupInvocation)))
    			{
    				sharedAccessor.main.set(nextLevelStoreIndex, scan);
    			}
    		}
    		glsl::barrier();
    		participate = gl_LocalInvocationIndex <= (lastInvocationInLevel >>= subgroup::SizeLog2());
    		if(participate)
    		{
    			const uint prevLevelScan = sharedAccessor.main.get(offsetsAndMasks.scanStoreOffset);
    			scan = subgroupOp(prevLevelScan);
    			if(isScan)
    				sharedAccessor.main.set(scanStoreIndex, scan);
    		}
    		if(isScan)
    			scanStoreIndex += lastInvocationInLevel + 1u;
    	}
    	if(lastInvocationInLevel >= subgroup::Size())
    	{
    		glsl::barrier();
    		if(participate)
    		{
    			if(any(bool2(gl_LocalInvocationIndex == lastInvocationInLevel, isLastSubgroupInvocation)))
    				sharedAccessor.main.set(nextLevelStoreIndex, scan);
    		}
    		glsl::barrier();
    		participate = gl_LocalInvocationIndex <= (lastInvocationInLevel >>= subgroup::SizeLog2());
    		if(participate)
    		{
    			const uint prevLevelScan = sharedAccessor.main.get(offsetsAndMasks.scanStoreOffset);
				scan = subgroupOp(prevLevelScan);
    			if(isScan) {
    				sharedAccessor.main.set(scanStoreIndex, scan);
				}
    		}
    	}
    	return scan;
    }
};

template<typename T, class Binop, class SharedAccessor>
struct WorkgroupScanTail
{
    bool isExclusive;
    T identity;
    T firstLevelScan;
    uint lastInvocation;
    uint scanStoreIndex;

    static WorkgroupScanTail create(bool isExclusive, T identity, T firstLevelScan, uint lastInvocation, uint scanStoreIndex)
    {
        WorkgroupScanTail<T, Binop, SharedAccessor> wst;
        wst.isExclusive = isExclusive;
        wst.identity = identity;
        wst.firstLevelScan = firstLevelScan;
        wst.lastInvocation = lastInvocation;
        wst.scanStoreIndex = scanStoreIndex;
        return wst;
    }

    T operator()()
    {
		glsl::barrier();
        Binop binop;
        SharedAccessor sharedAccessor;
		
        if(lastInvocation >= subgroup::Size())
    	{
			const uint subgroupId = subgroup::SubgroupID();
    		uint scanLoadIndex = scanStoreIndex + subgroup::Size();
    		const uint shiftedInvocationIndex = gl_LocalInvocationIndex + subgroup::Size();
    		const uint currentToHighLevel = subgroupId - shiftedInvocationIndex;
    		for(uint logShift = (firstbithigh(lastInvocation) / subgroup::SizeLog2() - 1u) * subgroup::SizeLog2(); logShift > 0u; logShift -= subgroup::SizeLog2())
    		{
    			uint lastInvocationInLevel = lastInvocation >> logShift;
    			glsl::barrier();
    			const uint currentLevelIndex = scanLoadIndex - (lastInvocationInLevel + 1u);
    			if(shiftedInvocationIndex <= lastInvocationInLevel)
    			{
    				sharedAccessor.main.set(currentLevelIndex, binop(sharedAccessor.main.get(scanLoadIndex+currentToHighLevel), sharedAccessor.main.get(currentLevelIndex)));
    			}
    			scanLoadIndex = currentLevelIndex;
    		}
    		glsl::barrier();
			
    		if(gl_LocalInvocationIndex <= lastInvocation && subgroupId != 0u)
    		{
    			const uint higherLevelExclusive = sharedAccessor.main.get(scanLoadIndex + currentToHighLevel - 1u);
    			firstLevelScan = binop(higherLevelExclusive, firstLevelScan);
    		}
    	}
		
    	if(isExclusive)
    	{
    		if(gl_LocalInvocationIndex < lastInvocation)
    		{
    			sharedAccessor.main.set(gl_LocalInvocationIndex + 1u, firstLevelScan);
    		}
			glsl::barrier();
    		return any(bool2(gl_LocalInvocationIndex != 0u, gl_LocalInvocationIndex <= lastInvocation)) ? sharedAccessor.main.get(gl_LocalInvocationIndex) : identity;
    	}
    	else
    	{
    		return firstLevelScan;
    	}
    }
};
}
}
}

#endif