// Copyright (C) 2022 - DevSH Graphics Programming Sp. z O.O.
// This file is part of the "Nabla Engine".
// For conditions of distribution and use, see copyright notice in nabla.h
#ifndef _NBL_BUILTIN_HLSL_TGMATH_INCLUDED_
#define _NBL_BUILTIN_HLSL_TGMATH_INCLUDED_

#include <nbl/builtin/hlsl/cpp_compat.hlsl>
#include <nbl/builtin/hlsl/ieee754.hlsl>
#include <nbl/builtin/hlsl/type_traits.hlsl>

namespace nbl
{
namespace hlsl
{

namespace tgmath
{

template <typename Float>
static inline bool isnan(Float val)
{
	using AsUint = typename unsigned_integer_of_size<sizeof(Float)>::type;
	using AsFloat = typename float_of_size<sizeof(Float)>::type;
	AsUint asUint = bit_cast<AsUint, Float>(val);
	return bool((ieee754::extractBiasedExponent<Float>(val) == ieee754::traits<Float>::specialValueExp) && (asUint & ieee754::traits<Float>::mantissaMask));
}

template <>
static inline bool isnan(uint64_t val)
{
	float64_t asFloat = bit_cast<float64_t, uint64_t>(val);
	return bool((ieee754::extractBiasedExponent<float64_t>(asFloat) == ieee754::traits<float64_t>::specialValueExp) && (val & ieee754::traits<float64_t>::mantissaMask));
}

// TODO: better implementation, also i'm not sure this is the right place for this function
template<typename Uint>
NBL_CONSTEXPR_STATIC_INLINE Uint lerp(Uint a, Uint b, bool c)
{
	return c ? b : a;
}

template<typename Uint>
NBL_CONSTEXPR_STATIC_INLINE bool isInf(Uint val)
{
	using AsFloat = typename float_of_size<sizeof(Uint)>::type;
	return (val & ~ieee754::traits<AsFloat>::signMask) == ieee754::traits<AsFloat>::inf;
}

}

}
}

#endif