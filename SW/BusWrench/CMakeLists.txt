cmake_minimum_required(VERSION 3.21.1)

option(LINK_INSIGHT "Link Qt Insight Tracker library" ON)
option(BUILD_QDS_COMPONENTS "Build design studio components" ON)

project(BusWrenchApp LANGUAGES CXX)

# Needed so CMake can compile the .rc file (icon of the .exe) on Windows
if(WIN32)
    enable_language(RC)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)
set(QML_IMPORT_PATH ${QT_QML_OUTPUT_DIRECTORY}
    CACHE STRING "Import paths for Qt Creator's code model"
    FORCE
)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickTimeline ShaderTools SerialBus)
qt_standard_project_setup()

qt_add_executable(${CMAKE_PROJECT_NAME}
    App/canbackend.h
    App/canbackend.cpp
    App/devicemodel.h App/devicemodel.cpp
    App/updatemanager.h App/updatemanager.cpp
    App/appsettings.h App/appsettings.cpp
    App/nodeconfig.h App/nodeconfig.cpp
)

# Icon of the .exe (Windows only)
if(WIN32)
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE appicon.rc)
endif()

# PNG icon used for the window and the taskbar
qt_add_resources(${CMAKE_PROJECT_NAME} "icons"
    PREFIX "/icons"
    FILES icon-256.png
)

# --------------------------------------------------
# PCAN-Basic API
# --------------------------------------------------

set(PCAN_BASIC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/External/PCANBasic")

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    "${PCAN_BASIC_DIR}/Include"
)

target_link_directories(${CMAKE_PROJECT_NAME} PRIVATE
    "${PCAN_BASIC_DIR}/Lib/x64"
)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    PCANBasic
)

add_custom_command(TARGET ${CMAKE_PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${PCAN_BASIC_DIR}/Bin/PCANBasic.dll"
    "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>"
)


qt_add_resources(${CMAKE_PROJECT_NAME} "configuration"
    PREFIX "/"
    FILES
        qtquickcontrols2.conf
)

include(qds)

if (BUILD_QDS_COMPONENTS)
    include(qmlcomponents OPTIONAL)
endif()

if (LINK_INSIGHT)
    include(insight OPTIONAL)
endif()

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    Qt6::SerialBus
)

include(GNUInstallDirs)

install(TARGETS ${CMAKE_PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

