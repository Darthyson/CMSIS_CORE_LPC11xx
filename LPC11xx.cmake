cmake_minimum_required(VERSION 3.30)
    if(NOT TOOLCHAIN_PREFIX)
        message(FATAL_ERROR "No TOOLCHAIN_PREFIX specified.\
                Specify path to arm-none-eabi toolchain with e.g. --DTOOLCHAIN_PREFIX=C:/nxp/MCUXpressoIDE_24.12.148/ide/tools")
    endif()

    set(CMAKE_SYSTEM_NAME Generic)
    set(CMAKE_SYSTEM_VERSION 1)
    set(CMAKE_SYSTEM_PROCESSOR arm)
#    set(LPC11XX_CHAIN_INITIALIZED "yes" CACHE INTERNAL "Has the LPC11xx toolchain been pulled?")

    get_filename_component(BUILD_DIR_PREFIX ${CMAKE_BINARY_DIR} NAME CACHE)

    # MCUXpresso version check
    string(TOLOWER "${TOOLCHAIN_PREFIX}" LOWER_TOOLCHAIN_PREFIX)
    string(REGEX MATCH "mcuxpressoide" MATCH_STR TOLOWER ${LOWER_TOOLCHAIN_PREFIX})
    if(NOT ${MATCH_STR} STREQUAL "")
        # Get version from specified path prefix
        string(REGEX MATCH "([0-9]+.[0-9]+.[0-9]+)" MCUXPRESSO_VERSION ${TOOLCHAIN_PREFIX})
        if(NOT ${MCUXPRESSO_VERSION} STREQUAL "")
            message(STATUS "MCUXpresso detected: v" ${MCUXPRESSO_VERSION})
            # Check if version is supported
            if(${MCUXPRESSO_VERSION} VERSION_LESS "7.6.2")
                message(FATAL_ERROR "MCUXpresso version not supported: " ${MCUXPRESSO_VERSION})
            endif()
        else()
            message(NOTICE "Could not check MCUXpresso version. Build may not work correctly.")
        endif()
    else()
        message(NOTICE "Could find MCUXpresso in ${TOOLCHAIN_PREFIX}. Build may not work correctly.")
    endif()

    set(TARGET_TRIPLET "arm-none-eabi")

    # Where we find NXP tools for flashing and debugging
    get_filename_component(MCUX_IDE_BIN ${TOOLCHAIN_PREFIX}/../binaries/ REALPATH CACHE)
    set(BOOT_LINK1 ${MCUX_IDE_BIN}/boot_link1 CACHE FILEPATH "link1")
    set(BOOT_LINK2 ${MCUX_IDE_BIN}/boot_link2 CACHE FILEPATH "link2")
    set(REDLINK ${MCUX_IDE_BIN}/crt_emu_cm_redlink CACHE FILEPATH "redlink")

    get_filename_component(TOOLCHAIN_BIN_DIR ${TOOLCHAIN_PREFIX}/bin REALPATH CACHE)
    get_filename_component(TOOLCHAIN_INC_DIR ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/include REALPATH CACHE)
    get_filename_component(TOOLCHAIN_LIB_DIR ${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/lib REALPATH CACHE)

    if(NOT CMAKE_HOST_EXECUTABLE_SUFFIX) #todo CMAKE_HOST_EXECUTABLE_SUFFIX is added in CMake 3.31
        set(CMAKE_HOST_EXECUTABLE_SUFFIX ".exe" CACHE STRING "Host executable suffix")
    endif()

    set(TOOLS_PREFIX ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET})
    set(CMAKE_C_COMPILER ${TOOLS_PREFIX}-gcc${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "c compiler")
    set(CMAKE_CXX_COMPILER ${TOOLS_PREFIX}-g++${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "cxx compiler")
    set(CMAKE_ASM_COMPILER ${TOOLS_PREFIX}-as${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "asm compiler")
    set(CMAKE_OBJCOPY ${TOOLS_PREFIX}-objcopy${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "objcopy")
    set(CMAKE_OBJDUMP ${TOOLS_PREFIX}-objdump${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "objdump")
    set(CMAKE_AR ${TOOLS_PREFIX}-ar${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "archiver")
    set(CMAKE_STRIP ${TOOLS_PREFIX}-strip${CMAKE_EXECUTABLE_SUFFIX} CACHE FILEPATH "strip")
    set(CMAKE_SIZE ${TOOLS_PREFIX}-size${CMAKE_EXECUTABLE_SUFFIX} CACHE FILEPATH "size")

    # Adjust the default behaviour of the FIND_XXX() commands:
    # i)    Search headers and libraries in the target environment
    # ii)   Search programs in the host environment
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

    set(CMAKE_COMPILER_IS_GNUCC     1)
    set(CMAKE_C_COMPILER_ID         GNU)
    set(CMAKE_C_COMPILER_ID_RUN     TRUE)
    set(CMAKE_C_COMPILER_FORCED     TRUE)
    set(CMAKE_CXX_COMPILER_ID       GNU)
    set(CMAKE_CXX_COMPILER_ID_RUN   TRUE)
    set(CMAKE_CXX_COMPILER_FORCED   TRUE)


add_compile_definitions("__USE_CMSIS=CMSIS_CORE_LPC11xx")
add_compile_definitions("__LPC11XX__")
add_compile_definitions("__NEWLIB__")
add_compile_definitions("CORE_M0")

set(C_FLAGS
        -Wall -Wlogical-op -Wextra
        -std=c17
        -g3
        -gdwarf-4
        -c
        -fmessage-length=0 -fno-builtin -ffunction-sections -fdata-sections -fno-exceptions -fmerge-constants
        -mcpu=cortex-m0 -mthumb -fstack-usage -specs=nano.specs
)
#todo -fmacro-prefix-map doesn´t work as expected yet
#-fmacro-prefix-map="${CMAKE_SOURCE_DIR}/"=
set(C_FLAGS_DEBUG
        -DDEBUG
        -O0
)

set(C_FLAGS_RELEASE
        -DNDEBUG
        -Os
        -flto
        -ffat-lto-objects
)

string(JOIN " " C_FLAGS_STR ${C_FLAGS}) # Join C_FLAGS into a single space-separated string
string(JOIN " " C_FLAGS_DEBUG_STR ${C_FLAGS_DEBUG})
string(JOIN " " C_FLAGS_RELEASE_STR ${C_FLAGS_RELEASE})

set(CMAKE_C_FLAGS_INIT ${C_FLAGS_STR} CACHE INTERNAL "C compiler default flags")
set(CMAKE_C_FLAGS_DEBUG_INIT ${C_FLAGS_DEBUG_STR} CACHE INTERNAL "C compiler Debug flags")
set(CMAKE_C_FLAGS_RELEASE_INIT ${C_FLAGS_RELEASE_STR} CACHE INTERNAL "C compiler Release flags")

#todo -fmacro-prefix-map doesn´t work as expected yet
# -Wextra
set(CXX_FLAGS
        -Wall -Wlogical-op -Woverloaded-virtual
        -std=c++17
        -g3
        -gdwarf-4
        -c
        -fmessage-length=0 -fno-builtin -ffunction-sections -fdata-sections -fno-exceptions -fmerge-constants
        -mcpu=cortex-m0 -mthumb -fstack-usage -specs=nano.specs
        -fno-rtti
)

set(CXX_FLAGS_DEBUG
        -DDEBUG
        -O0
)

set(CXX_FLAGS_RELEASE
        -DNDEBUG
        -Os
        -flto
        -ffat-lto-objects
)

string(JOIN " " CXX_FLAGS_STR ${CXX_FLAGS}) # Join CXX_FLAGS into a single space-separated string
string(JOIN " " CXX_FLAGS_DEBUG_STR ${CXX_FLAGS_DEBUG})
string(JOIN " " CXX_FLAGS_RELEASE_STR ${CXX_FLAGS_RELEASE})
set(CMAKE_CXX_FLAGS_INIT ${CXX_FLAGS_STR} CACHE INTERNAL "C++ compiler default flags")
set(CMAKE_CXX_FLAGS_DEBUG_INIT ${CXX_FLAGS_DEBUG_STR} CACHE INTERNAL "C++ compiler Debug flags")
set(CMAKE_CXX_FLAGS_RELEASE_INIT ${CXX_FLAGS_RELEASE_STR} CACHE INTERNAL "C++ compiler Release flags")

