// Copyright (C) 2018-2020 - DevSH Graphics Programming Sp. z O.O.
// This file is part of the "Nabla Engine".
// For conditions of distribution and use, see copyright notice in nabla.h

#ifndef __NBL_VIDEO_I_GPU_SKELETON_H_INCLUDED__
#define __NBL_VIDEO_I_GPU_SKELETON_H_INCLUDED__

#include "nbl/asset/asset.h"
#include "IGPUBuffer.h"

namespace nbl
{
namespace video
{

class IGPUSkeleton final : public asset::ISkeleton<IGPUBuffer>
{
        using base_t = asset::ISkeleton<IGPUBuffer>;

    public:
		inline IGPUSkeleton(asset::SBufferBinding<IGPUBuffer>&& _parentJointIDsBinding, asset::SBufferBinding<IGPUBuffer>&& _inverseBindPosesBinding, const decltype(m_nameToJointID)& nameToJointIDMap) :
			base_t(std::move(_parentJointIDsBinding),std::move(_inverseBindPosesBinding),nameToJointIDMap.size())
		{
			base_t::setJointNames(nameToJointIDMap);
		}

		template<typename NameIterator>
		inline IGPUSkeleton(asset::SBufferBinding<IGPUBuffer>&& _parentJointIDsBinding, asset::SBufferBinding<IGPUBuffer>&& _inverseBindPosesBinding, NameIterator begin, NameIterator end) :
			base_t(std::move(_parentJointIDsBinding),std::move(_inverseBindPosesBinding),std::distance(begin,end))
		{
			base_t::setJointNames<NameIterator>(begin,end);
		}

		template<typename... Args>
		inline IGPUSkeleton(Args&&... args) : base_t(std::forward<Args>(args)...) {}
};

} // end namespace video
} // end namespace nbl



#endif


