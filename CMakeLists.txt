cmake_minimum_required(VERSION 3.28)

if(CMAKE_CROSSCOMPILING AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    message(WARNING "Cross-compiling but CMAKE_TOOLCHAIN_FILE not set. Configure with -DCMAKE_TOOLCHAIN_FILE=<path to>/arm-none-eabi_mcuxpresso.cmake")
endif()
if(CMAKE_CROSSCOMPILING AND DEFINED CMAKE_TOOLCHAIN_FILE AND NOT EXISTS "${CMAKE_TOOLCHAIN_FILE}")
    message(FATAL_ERROR "Toolchain file does not exist: ${CMAKE_TOOLCHAIN_FILE}")
endif()

project(CMSIS_CORE_LPC11xx LANGUAGES C)
set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Enable verbose output from the build system" FORCE)
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(LPC11XX_ARM ${PROJECT_NAME}_arm)
set(LPC11XX_X86 ${PROJECT_NAME}_x86)
set(LPC11XX_X64 ${PROJECT_NAME}_x64)

include(LPC11xx_src.cmake) # list of all cmsis_core source code files (*.h, *.cpp, ...)

add_compile_definitions(${LPC11XX_ARM} PUBLIC
        __USE_CMSIS=CMSIS_CORE_LPC11xx
        # __REDLIB__
        # __CODE_RED
        # $<$<CONFIG:Debug>: TEST_SYMBOL_IN_DEBUG>
        # $<$<CONFIG:Release>: TEST_SYMBOL_IN_RELEASE>
)

# Check if cross-compiling for ARM target
if(CMAKE_CROSSCOMPILING)
    add_library(${LPC11XX_ARM} STATIC ${CMSIS_CORE_LPC11XX_SRC})
    target_include_directories(${LPC11XX_ARM} PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/inc
    )

    target_compile_options(${LPC11XX_ARM} PRIVATE
    $<$<CONFIG:Debug>: -O0 -DDEBUG>
    $<$<CONFIG:Release>: -Os>
    )
# Check if building for 32bit architecture
elseif(CMSIS_ARCHITECTURE STREQUAL "x86")
    add_library(${LPC11XX_X86} STATIC ${CMSIS_CORE_LPC11XX_SRC})
    target_include_directories(${LPC11XX_X86} PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/inc
    )

    target_compile_options(${LPC11XX_X86} PRIVATE
        -m32
        $<$<CONFIG:Debug>: -O0 -DDEBUG>
        $<$<CONFIG:Release>: -Os>
    )
# Check if building for 64bit architecture
elseif(CMSIS_ARCHITECTURE STREQUAL "x64")
    add_library(${LPC11XX_X64} STATIC ${CMSIS_CORE_LPC11XX_SRC})
    target_include_directories(${LPC11XX_X64} PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/inc
    )
            
    target_compile_options(${LPC11XX_X64} PRIVATE
        -m64
        $<$<CONFIG:Debug>: -O0 -DDEBUG>
        $<$<CONFIG:Release>: -Os>
    )
else()
    message(FATAL_ERROR "Unknown architecture. (project ${PROJECT_NAME})")
endif()