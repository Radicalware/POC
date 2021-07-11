cmake_minimum_required(VERSION 3.10)

SET(THIS RFirewall)

# -------------------------- PRE-CONFIG -------------------------------------------------

if(WIN32)
    set(RADICAL_PATH "C:/Source/CMake/Modules")
else()
    set(RADICAL_PATH "/opt/Radicalware/CMake_Modules")
endif()

include("${RADICAL_PATH}/Radical-App-Config.cmake")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# -------------------------- BUILD ------------------------------------------------------

project (${THIS})

set(build_all ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

find_package(
    Qt6  COMPONENTS 
        Widgets 
        Qml 
        Quick 
        QuickControls2
        QuickTemplates2
    REQUIRED
)

add_definitions(
    ${Qt6Widgets_DEFINITIONS} 
    ${QtQml_DEFINITIONS} 
    ${Qt6Quick_DEFINITIONS}
    ${Qt6Network_DEFINITIONS}
)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${Qt6Widgets_EXECUTABLE_COMPILE_FLAGS}")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

list(APPEND QML_DIRS "${SOLUTION}/view")
list(APPEND QML_DIRS "${SOLUTION}/view/Backend")
list(APPEND QML_DIRS "${SOLUTION}/view/Constants")
list(APPEND QML_DIRS "${SOLUTION}/view/Mods")
list(APPEND QML_DIRS "${SOLUTION}/view/Support")
set(QML_IMPORT_PATH  "${QML_DIRS}" CACHE STRING "Qt Creator extra qml import paths" FORCE)

set(SOLUTION "${CMAKE_SOURCE_DIR}/Solution")
qt6_add_resources(QT_RESOURCES "${SOLUTION}/files.qrc")
find_program_files(SOLUTION_FILES "${SOLUTION}")

# Build the app!
add_executable(${THIS}
    ${SOLUTION_FILES}
    ${QT_RESOURCES}
    ${SOLUTION}/resource/exe/pic.rc
)

# Link the app!
find_package(re2)
find_package(Nexus)
find_package(xvector)
find_package(xstring)
find_package(xmap)
find_package(OS)
find_package(SYS)
find_package(Timer)

target_include_directories(${THIS} PRIVATE
        ${installed_projects}
)

include_directories(
    ${SOLUTION}/controller/include
    ${Qt6Widgets_INCLUDE_DIRS} 
    ${QtQml_INCLUDE_DIRS}
)

target_link_libraries(${THIS}

    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickTemplates2
    
    Radical_Mod::re2
    Radical::Nexus
    Radical::xvector
    Radical::xstring
    Radical::xmap
)

# -------------------------- POST-CONFIG ------------------------------------------------

include("${RADICAL_PATH}/Radical-App-Install.cmake")
INSTALL_VISUAL_STUDIO_SOLUTION(${SOLUTION_FILES})
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# -------------------------- END --------------------------------------------------------
