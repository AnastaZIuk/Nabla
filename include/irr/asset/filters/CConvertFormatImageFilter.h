// Copyright (C) 2020- Mateusz 'DevSH' Kielan
// This file is part of the "IrrlichtBAW" engine.
// For conditions of distribution and use, see copyright notice in irrlicht.h

#ifndef __IRR_C_CONVERT_FORMAT_IMAGE_FILTER_H_INCLUDED__
#define __IRR_C_CONVERT_FORMAT_IMAGE_FILTER_H_INCLUDED__

#include "irr/core/core.h"

#include <type_traits>

#include "irr/asset/filters/CSwizzleAndConvertImageFilter.h"

namespace irr
{
namespace asset
{

// copy while converting format from input image to output image
template<E_FORMAT inFormat=EF_UNKNOWN, E_FORMAT outFormat=EF_UNKNOWN, bool Normalize = false, bool Clamp = false, class Dither = IdentityDither>
class CConvertFormatImageFilter : public CSwizzleAndConvertImageFilter<inFormat,outFormat,VoidSwizzle,Normalize,Clamp,Dither>
{
	public:
		virtual ~CConvertFormatImageFilter() {}
		
		using state_type = typename CSwizzleAndConvertImageFilter<inFormat,outFormat,VoidSwizzle,Normalize,Clamp,Dither>::state_type;
};

} // end namespace asset
} // end namespace irr

#endif