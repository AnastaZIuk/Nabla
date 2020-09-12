// Copyright (C) 2020- Mateusz 'DevSH' Kielan
// This file is part of the "IrrlichtBAW" engine.
// For conditions of distribution and use, see copyright notice in irrlicht.h

#ifndef __IRR_C_GAUSSIAN_IMAGE_FILTER_KERNEL_H_INCLUDED__
#define __IRR_C_GAUSSIAN_IMAGE_FILTER_KERNEL_H_INCLUDED__


#include "irr/asset/filters/kernels/IImageFilterKernel.h"

#include <ratio>

namespace irr
{
namespace asset
{

// Truncated Gaussian filter, with stddev = 1.0, if you want a different stddev then you need to scale it with `CScaledImageFilterKernel`
template<uint32_t support=3u>
class CGaussianImageFilterKernel : public CFloatingPointIsotropicSeparableImageFilterKernelBase<CGaussianImageFilterKernel<support>,std::ratio<support,1> >
{
		using Base = CFloatingPointIsotropicSeparableImageFilterKernelBase<CGaussianImageFilterKernel<support>,std::ratio<support,1> >;

	public:
		inline float weight(float x, int32_t channel) const
		{
			if (Base::inDomain(x))
			{
				const float normalizationFactor = core::inversesqrt(2.f*core::PI<float>())/std::erff(core::sqrt<float>(2.f)*float(support));
				return normalizationFactor*exp2f(-0.72134752f*x*x);
			}
			return 0.f;
		}

		_IRR_STATIC_INLINE_CONSTEXPR bool has_derivative = true;
		inline float d_weight(float x, int32_t channel) const
		{
			if (Base::inDomain(x))
				return -x*CGaussianImageFilterKernel<support>::weight(x,channel);
			return 0.f;
		}
};

} // end namespace asset
} // end namespace irr

#endif