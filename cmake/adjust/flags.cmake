include_guard(GLOBAL)

define_property(TARGET PROPERTY NBL_CONFIGURATION_MAP
  BRIEF_DOCS "Stores configuration map for a target, it will evaluate to the configuration it's mapped to"
)

macro(_NBL_IMPL_GET_FLAGS_PROFILE_)
	if(MSVC)
		include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/template/windows/msvc.cmake")
	elseif(ANDROID)
		include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/template/unix/android.cmake")
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/template/unix/gnu.cmake")
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/template/unix/clang.cmake")
	else()
		message(WARNING "UNTESTED COMPILER DETECTED, EXPECT WRONG OPTIMIZATION FLAGS! SUBMIT ISSUE ON GITHUB https://github.com/Devsh-Graphics-Programming/Nabla/issues")
	endif()
endmacro()

function(NBL_EXT_P_APPEND_COMPILE_OPTIONS NBL_LIST_NAME MAP_RELEASE MAP_RELWITHDEBINFO MAP_DEBUG)
	_NBL_IMPL_GET_FLAGS_PROFILE_()
		
	macro(NBL_MAP_CONFIGURATION NBL_CONFIG_FROM NBL_CONFIG_TO)
		string(TOUPPER "${NBL_CONFIG_FROM}" NBL_CONFIG_FROM_U)
		string(TOUPPER "${NBL_CONFIG_TO}" NBL_CONFIG_TO_U)
		
		string(REPLACE ";" " " _NBL_CXX_CO_ "${NBL_CXX_${NBL_CONFIG_TO_U}_COMPILE_OPTIONS}")
		string(REPLACE ";" " " _NBL_C_CO_ "${NBL_C_${NBL_CONFIG_TO_U}_COMPILE_OPTIONS}")
		
		list(APPEND ${NBL_LIST_NAME} "-DCMAKE_CXX_FLAGS_${NBL_CONFIG_FROM_U}:STRING=${_NBL_CXX_CO_}")
		list(APPEND ${NBL_LIST_NAME} "-DCMAKE_C_FLAGS_${NBL_CONFIG_FROM_U}:STRING=${_NBL_C_CO_}")
	endmacro()
	
	NBL_MAP_CONFIGURATION(RELEASE ${MAP_RELEASE})
	NBL_MAP_CONFIGURATION(RELWITHDEBINFO ${MAP_RELWITHDEBINFO})
	NBL_MAP_CONFIGURATION(DEBUG ${MAP_DEBUG})
	
	set(${NBL_LIST_NAME} 
		${${NBL_LIST_NAME}}
	PARENT_SCOPE)
endfunction()

# Adjust compile flags for the build system, supports calling per target or directory and map a configuration into another one.
#
# -- TARGET mode --
#
# nbl_adjust_flags(
#	TARGET <NAME_OF_TARGET> MAP_RELEASE <CONFIGURATION> MAP_RELWITHDEBINFO <CONFIGURATION> MAP_DEBUG <CONFIGURATION>
#	...
#	TARGET <NAME_OF_TARGET> MAP_RELEASE <CONFIGURATION> MAP_RELWITHDEBINFO <CONFIGURATION> MAP_DEBUG <CONFIGURATION>
# )
#
# -- DIRECTORY mode --
#
# nbl_adjust_flags(
#	MAP_RELEASE <CONFIGURATION> MAP_RELWITHDEBINFO <CONFIGURATION> MAP_DEBUG <CONFIGURATION>
# )

function(nbl_adjust_flags)
	# only configuration dependent, global CMAKE_<LANG>_FLAGS flags are fine
	macro(UNSET_GLOBAL_CONFIGURATION_FLAGS NBL_CONFIGURATION)
		if(DEFINED CMAKE_CXX_FLAGS_${NBL_CONFIGURATION})
			unset(CMAKE_CXX_FLAGS_${NBL_CONFIGURATION} CACHE)
		endif()
		
		if(DEFINED CMAKE_C_FLAGS_${NBL_CONFIGURATION})
			unset(CMAKE_C_FLAGS_${NBL_CONFIGURATION} CACHE)
		endif()
	endmacro()

	foreach(_NBL_CONFIG_IMPL_ ${CMAKE_CONFIGURATION_TYPES})
		string(TOUPPER "${_NBL_CONFIG_IMPL_}" _NBL_CONFIG_U_IMPL_)
		UNSET_GLOBAL_CONFIGURATION_FLAGS(${_NBL_CONFIG_U_IMPL_})
		
		list(APPEND _NBL_OPTIONS_IMPL_ MAP_${_NBL_CONFIG_U_IMPL_})
	endforeach()

	if(NOT _NBL_OPTIONS_IMPL_)
		message(FATAL_ERROR "Internal error, there are no configurations available! Please set \"CMAKE_CONFIGURATION_TYPES\"")
	endif()

	list(APPEND _NBL_OPTIONS_IMPL_ TARGET)
	cmake_parse_arguments(NBL "" "" "${_NBL_OPTIONS_IMPL_}" ${ARGN})
	
	_NBL_IMPL_GET_FLAGS_PROFILE_()

	# TARGET mode
	if(NBL_TARGET)
		# validate	
		list(LENGTH NBL_TARGET _NBL_V_OPTION_LEN_)
		list(REMOVE_ITEM _NBL_OPTIONS_IMPL_ TARGET)
		foreach(_NBL_OPTION_IMPL_ ${_NBL_OPTIONS_IMPL_})
			if(NOT NBL_${_NBL_OPTION_IMPL_})
				message(FATAL_ERROR "Internal error, nbl_adjust_flags called with TARGET mode missing \"${_NBL_OPTION_IMPL_}\" argument!")
			endif()
			
			list(LENGTH NBL_${_NBL_OPTION_IMPL_} _NBL_C_V_OPTION_LEN_)
			if("${_NBL_C_V_OPTION_LEN_}" STREQUAL "${_NBL_V_OPTION_LEN_}")
				set(_NBL_V_OPTION_LEN_ 
					"${_NBL_C_V_OPTION_LEN_}"
				PARENT_SCOPE)
			else()
				message(FATAL_ERROR "Internal error, nbl_adjust_flags called with TARGET mode has inequal arguments!")
			endif()
		endforeach()
		list(APPEND _NBL_OPTIONS_IMPL_ TARGET)
		
		set(_NBL_ARG_I_ 0)
		while(_NBL_ARG_I_ LESS ${_NBL_V_OPTION_LEN_})
			foreach(_NBL_OPTION_IMPL_ ${_NBL_OPTIONS_IMPL_})
				list(GET NBL_${_NBL_OPTION_IMPL_} ${_NBL_ARG_I_} NBL_${_NBL_OPTION_IMPL_}_ITEM)
				
				set(NBL_${_NBL_OPTION_IMPL_}_ITEM 
					${NBL_${_NBL_OPTION_IMPL_}_ITEM}
				PARENT_SCOPE)
			endforeach()

			# global compile options
			list(APPEND _D_NBL_COMPILE_OPTIONS_ ${NBL_COMPILE_OPTIONS})

			foreach(_NBL_CONFIG_IMPL_ ${CMAKE_CONFIGURATION_TYPES})
				string(TOUPPER "${_NBL_CONFIG_IMPL_}" NBL_MAP_CONFIGURATION_FROM)
				string(TOUPPER "${NBL_MAP_${NBL_MAP_CONFIGURATION_FROM}_ITEM}" NBL_MAP_CONFIGURATION_TO)
				set(NBL_TO_CONFIG_COMPILE_OPTIONS ${NBL_${NBL_MAP_CONFIGURATION_TO}_COMPILE_OPTIONS})
				
				# per configuration compile options with mapping
				list(APPEND _D_NBL_COMPILE_OPTIONS_ $<$<CONFIG:${NBL_MAP_CONFIGURATION_FROM}>:${NBL_TO_CONFIG_COMPILE_OPTIONS}>)
				string(APPEND _D_NBL_CONFIGURATION_MAP_ $<$<CONFIG:${NBL_MAP_CONFIGURATION_FROM}>:${NBL_MAP_CONFIGURATION_TO}>)
			endforeach()
			
			set_target_properties(${NBL_TARGET_ITEM} PROPERTIES
				NBL_CONFIGURATION_MAP ${_D_NBL_CONFIGURATION_MAP_}
			)
			unset(_D_NBL_CONFIGURATION_MAP_)
			
			set(MAPPED_CONFIG $<TARGET_GENEX_EVAL:${NBL_TARGET_ITEM},$<TARGET_PROPERTY:${NBL_TARGET_ITEM},NBL_CONFIGURATION_MAP>>)
			
			if(MSVC)
				if(NBL_SANITIZE_ADDRESS)
					set(NBL_TARGET_MSVC_DEBUG_INFORMATION_FORMAT "$<$<OR:$<STREQUAL:${MAPPED_CONFIG},DEBUG>,$<STREQUAL:${MAPPED_CONFIG},RELWITHDEBINFO>>:ProgramDatabase>")
				else()
					set(NBL_TARGET_MSVC_DEBUG_INFORMATION_FORMAT "$<$<STREQUAL:${MAPPED_CONFIG},DEBUG>:EditAndContinue>$<$<STREQUAL:${MAPPED_CONFIG},RELWITHDEBINFO>:ProgramDatabase>")
				endif()
				
				# test
				file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST/GEN/${NBL_TARGET_ITEM}/test.cmake" CONTENT "TEST\nNBL_TARGET_MSVC_DEBUG_INFORMATION_FORMAT: \"${NBL_TARGET_MSVC_DEBUG_INFORMATION_FORMAT}\"\nmapped config: \"${MAPPED_CONFIG}\"" CONDITION $<CONFIG:DEBUG>)
			endif()
			
			set_target_properties(${NBL_TARGET_ITEM} PROPERTIES
				MSVC_DEBUG_INFORMATION_FORMAT "${NBL_TARGET_MSVC_DEBUG_INFORMATION_FORMAT}"
			)
		
			target_compile_options(${NBL_TARGET_ITEM} PUBLIC # the old behaviour was "PUBLIC" anyway, but we could also make it a param of the bundle call
				${_D_NBL_COMPILE_OPTIONS_}
			)
			unset(_D_NBL_COMPILE_OPTIONS_)
			
			math(EXPR _NBL_ARG_I_ "${_NBL_ARG_I_} + 1")
		endwhile()		
	else() # DIRECTORY mode
		list(REMOVE_ITEM _NBL_OPTIONS_IMPL_ TARGET)
		
		# global compile options
		list(APPEND _D_NBL_COMPILE_OPTIONS_ ${NBL_COMPILE_OPTIONS})
		foreach(_NBL_OPTION_IMPL_ ${_NBL_OPTIONS_IMPL_})
			string(REPLACE "NBL_MAP_" "" NBL_MAP_CONFIGURATION_FROM "NBL_${_NBL_OPTION_IMPL_}")
			string(TOUPPER "${NBL_${_NBL_OPTION_IMPL_}}" NBL_MAP_CONFIGURATION_TO)
			set(NBL_TO_CONFIG_COMPILE_OPTIONS ${NBL_${NBL_MAP_CONFIGURATION_TO}_COMPILE_OPTIONS})
			
			# per configuration compile options with mapping
			list(APPEND _D_NBL_COMPILE_OPTIONS_ $<$<CONFIG:${NBL_MAP_CONFIGURATION_FROM}>:${NBL_TO_CONFIG_COMPILE_OPTIONS}>)
		endforeach()
		
		set_directory_properties(PROPERTIES COMPILE_OPTIONS ${_D_NBL_COMPILE_OPTIONS_})
	endif()
endfunction()