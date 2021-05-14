# Copyright (c) 2019 DevSH Graphics Programming Sp. z O.O.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include(ProcessorCount)

# submodule managment
function(update_git_submodule _PATH)
	execute_process(COMMAND git submodule update --init --recursive ${_PATH}
			WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
	)
endfunction()


# TODO: REDO THIS WHOLE THING AS FUNCTIONS
# https://github.com/buildaworldnet/IrrlichtBAW/issues/311 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1

# Macro creating project for an executable
# Project and target get its name from directory when this macro gets executed (truncating number in the beginning of the name and making all lower case)
# Created because of common cmake code for examples and tools
macro(nbl_create_executable_project _EXTRA_SOURCES _EXTRA_OPTIONS _EXTRA_INCLUDES _EXTRA_LIBS)
	get_filename_component(EXECUTABLE_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
	string(REGEX REPLACE "^[0-9]+\." "" EXECUTABLE_NAME ${EXECUTABLE_NAME})
	string(TOLOWER ${EXECUTABLE_NAME} EXECUTABLE_NAME)

	project(${EXECUTABLE_NAME})

	add_executable(${EXECUTABLE_NAME} main.cpp ${_EXTRA_SOURCES})
	
	set_property(TARGET ${EXECUTABLE_NAME} PROPERTY
             MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
	
	# EXTRA_SOURCES is var containing non-common names of sources (if any such sources, then EXTRA_SOURCES must be set before including this cmake code)
	add_dependencies(${EXECUTABLE_NAME} Nabla)

	target_include_directories(${EXECUTABLE_NAME}
		PUBLIC ../../include
		PRIVATE ${_EXTRA_INCLUDES}
	)
	target_link_libraries(${EXECUTABLE_NAME} Nabla ${_EXTRA_LIBS}) # see, this is how you should code to resolve github issue 311

	add_compile_options(${_EXTRA_OPTIONS})
	
	if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
		# add_compile_options("-msse4.2 -mfpmath=sse") ????
		add_compile_options(
			"$<$<CONFIG:DEBUG>:-fstack-protector-all>"
		)
	
		set(COMMON_LINKER_OPTIONS "-msse4.2 -mfpmath=sse -fuse-ld=gold")
		set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${COMMON_LINKER_OPTIONS}")
		set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${COMMON_LINKER_OPTIONS} -fstack-protector-strong")
		if (NBL_GCC_SANITIZE_ADDRESS)
			set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -fsanitize=address")
		endif()
		if (NBL_GCC_SANITIZE_THREAD)
			set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -fsanitize=thread")
		endif()
		if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.1)
			add_compile_options(-Wno-error=ignored-attributes)
		endif()
	endif()

	# https://github.com/buildaworldnet/IrrlichtBAW/issues/298 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
	nbl_adjust_flags() # macro defined in root CMakeLists
	nbl_adjust_definitions() # macro defined in root CMakeLists
	add_definitions(-D_NBL_PCH_IGNORE_PRIVATE_HEADERS)

	set_target_properties(${EXECUTABLE_NAME} PROPERTIES DEBUG_POSTFIX _d)
	set_target_properties(${EXECUTABLE_NAME} PROPERTIES RELWITHDEBINFO_POSTFIX _rwdi)
	set_target_properties(${EXECUTABLE_NAME}
		PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/bin"
		RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_SOURCE_DIR}/bin"
		RUNTIME_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/bin"
		VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin" # for visual studio
	)
	if(MSVC)
		# nothing special
	else() # only set up for visual studio code
		set(VSCODE_LAUNCH_JSON "
{
    \"version\": \"0.2.0\",
    \"configurations\": [
        {
            \"name\": \"(gdb) Launch\",
            \"type\": \"cppdbg\",
            \"request\": \"launch\",
            \"program\": \"${PROJECT_SOURCE_DIR}/bin/${EXECUTABLE_NAME}\",
            \"args\": [],
            \"stopAtEntry\": false,
            \"cwd\": \"${PROJECT_SOURCE_DIR}/bin\",
            \"environment\": [],
            \"externalConsole\": false,
            \"MIMode\": \"gdb\",
            \"setupCommands\": [
                {
                    \"description\": \"Enable pretty-printing for gdb\",
                    \"text\": \"-enable-pretty-printing\",
                    \"ignoreFailures\": true
                }
            ],
            \"preLaunchTask\": \"build\" 
        }
    ]
}")
		file(WRITE "${PROJECT_BINARY_DIR}/.vscode/launch.json" ${VSCODE_LAUNCH_JSON})

		ProcessorCount(CPU_COUNT)
		set(VSCODE_TASKS_JSON "
{
    \"version\": \"0.2.0\",
    \"command\": \"\",
    \"args\": [],
    \"tasks\": [
        {
            \"label\": \"build\",
            \"command\": \"${CMAKE_MAKE_PROGRAM}\",
            \"type\": \"shell\",
            \"args\": [
                \"${EXECUTABLE_NAME}\",
                \"-j${CPU_COUNT}\"
            ],
            \"options\": {
                \"cwd\": \"${CMAKE_BINARY_DIR}\"
            },
            \"group\": {
                \"kind\": \"build\",
                \"isDefault\": true
            },
            \"presentation\": {
                \"echo\": true,
                \"reveal\": \"always\",
                \"focus\": false,
                \"panel\": \"shared\"
            },
            \"problemMatcher\": \"$msCompile\"
        }
    ]
}")
		file(WRITE "${PROJECT_BINARY_DIR}/.vscode/tasks.json" ${VSCODE_TASKS_JSON})
	endif()
endmacro()

macro(nbl_create_ext_library_project EXT_NAME LIB_HEADERS LIB_SOURCES LIB_INCLUDES LIB_OPTIONS)
	set(LIB_NAME "NblExt${EXT_NAME}")
	project(${LIB_NAME})

	add_library(${LIB_NAME} ${LIB_SOURCES})
	# EXTRA_SOURCES is var containing non-common names of sources (if any such sources, then EXTRA_SOURCES must be set before including this cmake code)
	add_dependencies(${LIB_NAME} Nabla)

	target_include_directories(${LIB_NAME}
		PUBLIC ${CMAKE_BINARY_DIR}/include/nbl/config/debug
		PUBLIC ${CMAKE_BINARY_DIR}/include/nbl/config/release
		PUBLIC ${CMAKE_BINARY_DIR}/include/nbl/config/relwithdebinfo
		PUBLIC ${CMAKE_SOURCE_DIR}/include
		PUBLIC ${CMAKE_SOURCE_DIR}/src
		PUBLIC ${CMAKE_SOURCE_DIR}/source/Nabla
		PRIVATE ${LIB_INCLUDES}
	)
	add_dependencies(${LIB_NAME} Nabla)
	target_link_libraries(${LIB_NAME} PUBLIC Nabla)
	target_compile_options(${LIB_NAME} PUBLIC ${LIB_OPTIONS})
	set_target_properties(${LIB_NAME} PROPERTIES MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

	if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
		add_compile_options(
			"$<$<CONFIG:DEBUG>:-fstack-protector-all>"
		)

		set(COMMON_LINKER_OPTIONS "-msse4.2 -mfpmath=sse -fuse-ld=gold")
		set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${COMMON_LINKER_OPTIONS}")
		set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${COMMON_LINKER_OPTIONS} -fstack-protector-strong -fsanitize=address")
	endif()

	# https://github.com/buildaworldnet/IrrlichtBAW/issues/298 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
	nbl_adjust_flags() # macro defined in root CMakeLists
	nbl_adjust_definitions() # macro defined in root CMakeLists

	set_target_properties(${LIB_NAME} PROPERTIES DEBUG_POSTFIX _d)
	set_target_properties(${LIB_NAME} PROPERTIES RELWITHDEBINFO_POSTFIX _rwdb)
	set_target_properties(${LIB_NAME}
		PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin"
	)
	if(MSVC)
		set_target_properties(${LIB_NAME}
			PROPERTIES
			RUNTIME_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/bin"
			RUNTIME_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/bin"
			RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_SOURCE_DIR}/bin"
			VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin" # seems like has no effect
		)
	endif()

	install(
		FILES ${LIB_HEADERS}
		DESTINATION ./include/nbl/ext/${EXT_NAME}
		CONFIGURATIONS Release
	)
	install(
		FILES ${LIB_HEADERS}
		DESTINATION ./debug/include/nbl/ext/${EXT_NAME}
		CONFIGURATIONS Debug
	)
	install(
		FILES ${LIB_HEADERS}
		DESTINATION ./relwithdebinfo/include/nbl/ext/${EXT_NAME}
		CONFIGURATIONS RelWithDebInfo
	)
	install(
		TARGETS ${LIB_NAME}
		DESTINATION ./lib/nbl/ext/${EXT_NAME}
		CONFIGURATIONS Release
	)
	install(
		TARGETS ${LIB_NAME}
		DESTINATION ./debug/lib/nbl/ext/${EXT_NAME}
		CONFIGURATIONS Debug
	)
	install(
		TARGETS ${LIB_NAME}
		DESTINATION ./relwithdebinfo/lib/nbl/ext/${EXT_NAME}
		CONFIGURATIONS RelWithDebInfo
	)

	set("NBL_EXT_${EXT_NAME}_INCLUDE_DIRS"
		"${NBL_ROOT_PATH}/include/"
		"${NBL_ROOT_PATH}/src"
		"${NBL_ROOT_PATH}/source/Nabla"
		"${NBL_ROOT_PATH}/ext/${EXT_NAME}"
		"${LIB_INCLUDES}"
		PARENT_SCOPE
	)
	set("NBL_EXT_${EXT_NAME}_LIB"
		"${LIB_NAME}"
		PARENT_SCOPE
	)
endmacro()

# End of TODO, rest are all functions

function(nbl_get_conf_dir _OUTVAR _CONFIG)
	string(TOLOWER ${_CONFIG} CONFIG)
	set(${_OUTVAR} "${CMAKE_BINARY_DIR}/include/nbl/config/${CONFIG}" PARENT_SCOPE)
endfunction()


# function for installing header files preserving directory structure
# _DEST_DIR is directory relative to CMAKE_INSTALL_PREFIX
function(nbl_install_headers _HEADERS _BASE_HEADERS_DIR)
	foreach (file ${_HEADERS})
		file(RELATIVE_PATH dir ${_BASE_HEADERS_DIR} ${file})
		get_filename_component(dir ${dir} DIRECTORY)
		install(FILES ${file} DESTINATION include/${dir} CONFIGURATIONS Release)
		install(FILES ${file} DESTINATION debug/include/${dir} CONFIGURATIONS Debug)
		install(FILES ${file} DESTINATION relwithdebinfo/include/${dir} CONFIGURATIONS RelWithDebInfo)
	endforeach()
endfunction()

function(nbl_install_config_header _CONF_HDR_NAME)
	nbl_get_conf_dir(dir_deb Debug)
	nbl_get_conf_dir(dir_rel Release)
	nbl_get_conf_dir(dir_relWithDebInfo RelWithDebInfo)
	set(file_deb "${dir_deb}/${_CONF_HDR_NAME}")
	set(file_rel "${dir_rel}/${_CONF_HDR_NAME}")
	set(file_relWithDebInfo "${dir_relWithDebInfo}/${_CONF_HDR_NAME}")
	install(FILES ${file_rel} DESTINATION include CONFIGURATIONS Release)
	install(FILES ${file_deb} DESTINATION debug/include CONFIGURATIONS Debug)
	install(FILES ${file_relWithDebInfo} DESTINATION relwithdebinfo/include CONFIGURATIONS RelWithDebInfo)
endfunction()

function(nbl_android_create_apk _TARGET _GLES_VER_MAJOR _GLES_VER_MINOR)
	get_target_property(TARGET_NAME ${_TARGET} NAME)
	# TARGET_NAME_IDENTIFIER is identifier that can be used in code
	string(MAKE_C_IDENTIFIER ${TARGET_NAME} TARGET_NAME_IDENTIFIER)

	math(EXPR GLES_VER "(${_GLES_VER_MAJOR}<<16) | ${_GLES_VER_MINOR}" OUTPUT_FORMAT HEXADECIMAL)

	set(APK_FILE_NAME ${TARGET_NAME}.apk)
	set(APK_FILE ${CMAKE_CURRENT_BINARY_DIR}/bin/${APK_FILE_NAME})

	add_custom_target(${TARGET_NAME}_apk ALL DEPENDS ${APK_FILE})

	set(PACKAGE_NAME "eu.devsh.${TARGET_NAME_IDENTIFIER}")
	set(APP_NAME ${TARGET_NAME_IDENTIFIER})
	set(SO_NAME ${TARGET_NAME})
	configure_file(${CMAKE_SOURCE_DIR}/android/Loader.java ${CMAKE_CURRENT_BINARY_DIR}/src/eu/devsh/${TARGET_NAME}/Loader.java)
	configure_file(${CMAKE_SOURCE_DIR}/android/AndroidManifest.xml ${CMAKE_CURRENT_BINARY_DIR}/AndroidManifest.xml)
	# configure_file(android/icon.png ${CMAKE_CURRENT_BINARY_DIR}/res/drawable/icon.png COPYONLY)

	# need to sign the apk in order for android device not to refuse it
	set(KEYSTORE_FILE ${CMAKE_CURRENT_BINARY_DIR}/debug.keystore)
	set(KEY_ENTRY_ALIAS ${TARGET_NAME_IDENTIFIER}_apk_key)
	add_custom_command(
		OUTPUT ${KEYSTORE_FILE}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMAND ${ANDROID_JAVA_BIN}/keytool -genkey -keystore ${KEYSTORE_FILE} -storepass android -alias ${KEY_ENTRY_ALIAS} -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=, OU=, O=, L=, S=, C="
	)
	
	add_custom_command(
		OUTPUT ${APK_FILE}
		DEPENDS ${_TARGET}
		DEPENDS ${KEYSTORE_FILE}
		DEPENDS ${CMAKE_SOURCE_DIR}/android/AndroidManifest.xml
		DEPENDS ${CMAKE_SOURCE_DIR}/android/Loader.java
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Creating ${APK_FILE_NAME} ..."
		COMMAND ${CMAKE_COMMAND} -E make_directory lib/x86_64
		COMMAND ${CMAKE_COMMAND} -E make_directory obj
		COMMAND ${CMAKE_COMMAND} -E make_directory bin
		COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${_TARGET}> lib/x86_64/$<TARGET_FILE_NAME:${_TARGET}>
		COMMAND ${ANDROID_BUILD_TOOLS}/aapt package -f -m -J src -M AndroidManifest.xml -I ${ANDROID_JAR} # -S res
		COMMAND ${ANDROID_JAVA_BIN}/javac -d ./obj -source 1.7 -target 1.7 -bootclasspath ${ANDROID_JAVA_RT_JAR} -classpath "${ANDROID_JAR}:obj" -sourcepath src src/eu/devsh/${TARGET_NAME}/Loader.java
		COMMAND ${ANDROID_BUILD_TOOLS}/dx --dex --output=bin/classes.dex ./obj
		COMMAND ${ANDROID_BUILD_TOOLS}/aapt package -f -M AndroidManifest.xml -I ${ANDROID_JAR} -F ${TARGET_NAME}-unaligned.apk bin lib/x86_64 # --version-code SOME-VERSION-CODE -S res
		COMMAND ${ANDROID_BUILD_TOOLS}/zipalign -f 4 ${TARGET_NAME}-unaligned.apk ${APK_FILE_NAME}
		COMMAND ${ANDROID_BUILD_TOOLS}/apksigner sign --ks ${KEYSTORE_FILE} --ks-pass pass:android --key-pass pass:android --ks-key-alias ${KEY_ENTRY_ALIAS} ${APK_FILE_NAME}
		COMMAND ${CMAKE_COMMAND} -E copy ${APK_FILE_NAME} ${APK_FILE}
		VERBATIM
	)
endfunction()

# Start to track variables for change or adding.
# Note that variables starting with underscore are ignored.
macro(start_tracking_variables_for_propagation_to_parent)
    get_cmake_property(_fnvtps_cache_vars CACHE_VARIABLES)
    get_cmake_property(_fnvtps_old_vars VARIABLES)
    
    foreach(_i ${_fnvtps_old_vars})
        if (NOT "x${_i}" MATCHES "^x_.*$")
            list(FIND _fnvtps_cache_vars ${_i} _fnvtps_is_in_cache)
            if(${_fnvtps_is_in_cache} EQUAL -1)
                set("_fnvtps_old${_i}" ${${_i}})
                #message(STATUS "_fnvtps_old${_i} = ${_fnvtps_old${_i}}")
            endif()
        endif()
    endforeach()
endmacro()

# forward_changed_variables_to_parent_scope([exclusions])
# Forwards variables that was added/changed since last call to start_track_variables() to the parent scope.
# Note that variables starting with underscore are ignored.
macro(propagate_changed_variables_to_parent_scope)
    get_cmake_property(_fnvtps_cache_vars CACHE_VARIABLES)
    get_cmake_property(_fnvtps_vars VARIABLES)
    set(_fnvtps_cache_vars ${_fnvtps_cache_vars} ${ARGN})
    
    foreach(_i ${_fnvtps_vars})
        if (NOT "x${_i}" MATCHES "^x_.*$")
            list(FIND _fnvtps_cache_vars ${_i} _fnvtps_is_in_cache)
            
            if (${_fnvtps_is_in_cache} EQUAL -1)
                list(FIND _fnvtps_old_vars ${_i} _fnvtps_is_old)
                
                if(${_fnvtps_is_old} EQUAL -1 OR NOT "${${_i}}" STREQUAL "${_fnvtps_old${_i}}")
                    set(${_i} ${${_i}} PARENT_SCOPE)
                    #message(STATUS "forwarded var ${_i}")
                endif()
            endif()
        endif()
    endforeach()
endmacro()
