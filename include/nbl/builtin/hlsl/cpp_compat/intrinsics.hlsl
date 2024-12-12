#ifndef _NBL_BUILTIN_HLSL_CPP_COMPAT_INTRINSICS_INCLUDED_
#define _NBL_BUILTIN_HLSL_CPP_COMPAT_INTRINSICS_INCLUDED_

#include <nbl/builtin/hlsl/cpp_compat/matrix.hlsl>
#include <nbl/builtin/hlsl/type_traits.hlsl>
#include <nbl/builtin/hlsl/vector_utils/vector_traits.hlsl>
#include <nbl/builtin/hlsl/array_accessors.hlsl>
#include <nbl/builtin/hlsl/spirv_intrinsics/core.hlsl>
#include <nbl/builtin/hlsl/spirv_intrinsics/GLSL.std.450.hlsl>

#ifndef __HLSL_VERSION
#include <algorithm>
#include <cmath>
#include "nbl/core/util/bitflag.h"
#endif

namespace nbl
{
namespace hlsl
{

template<typename Integer>
inline int bitCount(NBL_CONST_REF_ARG(Integer) val)
{
#ifdef __HLSL_VERSION
	if (sizeof(Integer) == 8u)
	{
		uint32_t lowBits = val;
		uint32_t highBits = val >> 32u;

		return countbits(lowBits) + countbits(highBits);
	}

	return countbits(val);

#else
	return glm::bitCount(val);
#endif
}

template<typename T>
vector<T, 3> cross(NBL_CONST_REF_ARG(vector<T, 3>) lhs, NBL_CONST_REF_ARG(vector<T, 3>) rhs)
{
#ifdef __HLSL_VERSION
	return spirv::cross(lhs, rhs);
#else
	return glm::cross(lhs, rhs);
#endif
}

template<typename T>
T clamp(NBL_CONST_REF_ARG(T) val, NBL_CONST_REF_ARG(T) min, NBL_CONST_REF_ARG(T) max)
{
#ifdef __HLSL_VERSION
	return clamp(val, min, max);
#else
	return glm::clamp(val, min, max);
#endif
}

namespace cpp_compat_intrinsics_impl
{
template<typename T>
struct dot_helper
{
	using scalar_type = typename vector_traits<T>::scalar_type;

	static inline scalar_type dot(NBL_CONST_REF_ARG(T) lhs, NBL_CONST_REF_ARG(T) rhs)
	{
		static array_get<T, scalar_type> getter;
		scalar_type retval = getter(lhs, 0) * getter(rhs, 0);

		static const uint32_t ArrayDim = sizeof(T) / sizeof(scalar_type);
		for (uint32_t i = 1; i < ArrayDim; ++i)
			retval = retval + getter(lhs, i) * getter(rhs, i);

		return retval;
	}
};

#define DEFINE_BUILTIN_VECTOR_SPECIALIZATION(FLOAT_TYPE, RETURN_VALUE)\
template<uint32_t N>\
struct dot_helper<vector<FLOAT_TYPE, N> >\
{\
	using VectorType = vector<FLOAT_TYPE, N>;\
	using ScalarType = typename vector_traits<VectorType>::scalar_type;\
\
	static inline ScalarType dot(NBL_CONST_REF_ARG(VectorType) lhs, NBL_CONST_REF_ARG(VectorType) rhs)\
	{\
		return RETURN_VALUE;\
	}\
};\

#ifdef __HLSL_VERSION
#define BUILTIN_VECTOR_SPECIALIZATION_RET_VAL dot(lhs, rhs)
#else
#define BUILTIN_VECTOR_SPECIALIZATION_RET_VAL glm::dot(lhs, rhs)
#endif

DEFINE_BUILTIN_VECTOR_SPECIALIZATION(float16_t, BUILTIN_VECTOR_SPECIALIZATION_RET_VAL)
DEFINE_BUILTIN_VECTOR_SPECIALIZATION(float32_t, BUILTIN_VECTOR_SPECIALIZATION_RET_VAL)
DEFINE_BUILTIN_VECTOR_SPECIALIZATION(float64_t, BUILTIN_VECTOR_SPECIALIZATION_RET_VAL)

#undef BUILTIN_VECTOR_SPECIALIZATION_RET_VAL
#undef DEFINE_BUILTIN_VECTOR_SPECIALIZATION

}

template<typename T>
typename vector_traits<T>::scalar_type dot(NBL_CONST_REF_ARG(T) lhs, NBL_CONST_REF_ARG(T) rhs)
{
	return cpp_compat_intrinsics_impl::dot_helper<T>::dot(lhs, rhs);
}

// TODO: for clearer error messages, use concepts to ensure that input type is a square matrix
// determinant not defined cause its implemented via hidden friend
// https://stackoverflow.com/questions/67459950/why-is-a-friend-function-not-treated-as-a-member-of-a-namespace-of-a-class-it-wa
template<typename T, uint16_t N>
inline T determinant(NBL_CONST_REF_ARG(matrix<T, N, N>) m)
{
#ifdef __HLSL_VERSION
	spirv::determinant(m);
#else
	return glm::determinant(reinterpret_cast<typename matrix<T, N, N>::Base const&>(m));
#endif
}

template<typename Integer>
int findLSB(NBL_CONST_REF_ARG(Integer) val)
{
#ifdef __HLSL_VERSION
	return spirv::findILsb(val);
#else
	if (is_signed_v<Integer>)
	{
		// GLM accepts only integer types, so idea is to cast input to integer type
		using as_int = typename integer_of_size<sizeof(Integer)>::type;
		const as_int valAsInt = reinterpret_cast<const as_int&>(val);
		return glm::findLSB(valAsInt);
	}
	else
	{
		// GLM accepts only integer types, so idea is to cast input to integer type
		using as_uint = typename unsigned_integer_of_size<sizeof(Integer)>::type;
		const as_uint valAsUnsignedInt = reinterpret_cast<const as_uint&>(val);
		return glm::findLSB(valAsUnsignedInt);
	}
#endif
}

template<typename Integer>
int findMSB(NBL_CONST_REF_ARG(Integer) val)
{
#ifdef __HLSL_VERSION
	if (is_signed_v<Integer>)
	{
		return spirv::findSMsb(val);
	}
	else
	{
		return spirv::findUMsb(val);
	}
#else
	if (is_signed_v<Integer>)
	{
		// GLM accepts only integer types, so idea is to cast input to integer type
		using as_int = typename integer_of_size<sizeof(Integer)>::type;
		const as_int valAsInt = reinterpret_cast<const as_int&>(val);
		return glm::findMSB(valAsInt);
	}
	else
	{
		// GLM accepts only integer types, so idea is to cast input to integer type
		using as_uint = typename unsigned_integer_of_size<sizeof(Integer)>::type;
		const as_uint valAsUnsignedInt = reinterpret_cast<const as_uint&>(val);
		return glm::findMSB(valAsUnsignedInt);
	}
#endif
}

// TODO: some of the functions in this header should move to `tgmath`
template<typename T>
inline T floor(NBL_CONST_REF_ARG(T) val)
{
#ifdef __HLSL_VERSION
	return spirv::floor(val);
#else
	return glm::floor(val);
#endif
	
}

// inverse not defined cause its implemented via hidden friend
template<typename T, uint16_t N, uint16_t M>
inline matrix<T, N, M> inverse(NBL_CONST_REF_ARG(matrix<T, N, M>) m)
{
#ifdef __HLSL_VERSION
	return spirv::matrixInverse(m);
#else
	return reinterpret_cast<matrix<T, N, M>&>(glm::inverse(reinterpret_cast<typename matrix<T, N, M>::Base const&>(m)));
#endif
}

namespace cpp_compat_intrinsics_impl
{

	// TODO: concept requiring T to be a float
template<typename T, typename U>
struct lerp_helper
{
	static inline T lerp(NBL_CONST_REF_ARG(T) x, NBL_CONST_REF_ARG(T) y, NBL_CONST_REF_ARG(U) a)
	{
#ifdef __HLSL_VERSION
		return spirv::fMix(x, y, a);
#else
		return glm::mix<T, U>(x, y, a);
#endif
	}
};

template<typename T>
struct lerp_helper<T, bool>
{
	static inline T lerp(NBL_CONST_REF_ARG(T) x, NBL_CONST_REF_ARG(T) y, NBL_CONST_REF_ARG(bool) a)
	{
		return a ? y : x;
	}
};

template<typename T, int N>
struct lerp_helper<vector<T, N>, vector<bool, N> >
{
	using output_vec_t = vector<T, N>;

	static inline output_vec_t lerp(NBL_CONST_REF_ARG(output_vec_t) x, NBL_CONST_REF_ARG(output_vec_t) y, NBL_CONST_REF_ARG(vector<bool, N>) a)
	{
		output_vec_t retval;
		for (uint32_t i = 0; i < vector_traits<output_vec_t>::Dimension; i++)
			retval[i] = a[i] ? y[i] : x[i];
		return retval;
	}
};

}

template<typename T, typename U>
inline T lerp(NBL_CONST_REF_ARG(T) x, NBL_CONST_REF_ARG(T) y, NBL_CONST_REF_ARG(U) a)
{
	return cpp_compat_intrinsics_impl::lerp_helper<T, U>::lerp(x, y, a);
}

// transpose not defined cause its implemented via hidden friend
template<typename T, uint16_t N, uint16_t M>
inline matrix<T, M, N> transpose(NBL_CONST_REF_ARG(matrix<T, N, M>) m)
{
#ifdef __HLSL_VERSION
	return spirv::transpose(m);
#else
	return reinterpret_cast<matrix<T, M, N>&>(glm::transpose(reinterpret_cast<typename matrix<T, N, M>::Base const&>(m)));
#endif
}

template<typename T>
inline T min(NBL_CONST_REF_ARG(T) a, NBL_CONST_REF_ARG(T) b)
{
#ifdef __HLSL_VERSION
	min(a, b);
#else
	return glm::min(a, b);
#endif
}

template<typename T>
inline T max(NBL_CONST_REF_ARG(T) a, NBL_CONST_REF_ARG(T) b)
{
#ifdef __HLSL_VERSION
	max(a, b);
#else
	return glm::max(a, b);
#endif
}

template<typename FloatingPoint>
inline FloatingPoint isnan(NBL_CONST_REF_ARG(FloatingPoint) val)
{
#ifdef __HLSL_VERSION
	return spirv::isNan(val);
#else
	return std::isnan(val);
#endif
}

template<typename FloatingPoint>
inline FloatingPoint isinf(NBL_CONST_REF_ARG(FloatingPoint) val)
{
#ifdef __HLSL_VERSION
	return spirv::isInf(val);
#else
	return std::isinf(val);
#endif
}

template<typename  T>
inline T exp2(NBL_CONST_REF_ARG(T) val)
{
#ifdef __HLSL_VERSION
	return spirv::exp2(val);
#else
	return std::exp2(val);
#endif
}

#define DEFINE_EXP2_SPECIALIZATION(TYPE)\
template<>\
inline TYPE exp2(NBL_CONST_REF_ARG(TYPE) val)\
{\
	return _static_cast<TYPE>(1ull << val);\
}\

DEFINE_EXP2_SPECIALIZATION(int16_t)
DEFINE_EXP2_SPECIALIZATION(int32_t)
DEFINE_EXP2_SPECIALIZATION(int64_t)
DEFINE_EXP2_SPECIALIZATION(uint16_t)
DEFINE_EXP2_SPECIALIZATION(uint32_t)
DEFINE_EXP2_SPECIALIZATION(uint64_t)

template<typename FloatingPoint>
inline FloatingPoint rsqrt(FloatingPoint x)
{
	// TODO: https://stackoverflow.com/a/62239778
#ifdef __HLSL_VERSION
	return spirv::inverseSqrt(x);
#else
	return 1.0f / std::sqrt(x);
#endif
}

}
}

#endif