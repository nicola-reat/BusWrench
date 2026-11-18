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

# Windows: no console window in the Release version. In Debug the console stays,
# so the messages of the program (qDebug, QML warnings) can be read.
if(WIN32 AND NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE ON)
endif()

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

# --------------------------------------------------
# Deployment: after every build windeployqt copies next to the exe the Qt
# libraries, the plugins (platforms, canbus, ...) and the QML modules the app
# uses. So the exe in the build folder starts by double click, without Qt Creator.
# --------------------------------------------------
option(DEPLOY_QT_ON_BUILD "Run windeployqt after every build (Windows)" ON)

if(WIN32 AND DEPLOY_QT_ON_BUILD)
    # windeployqt.exe is in the same folder as qmake.exe of the Qt in use.
    get_target_property(_qmake_exe Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_exe}" DIRECTORY)
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt
                 PATHS "${_qt_bin_dir}" NO_DEFAULT_PATH)

    if(WINDEPLOYQT_EXECUTABLE)
        add_custom_command(TARGET ${CMAKE_PROJECT_NAME} POST_BUILD
            COMMAND "${WINDEPLOYQT_EXECUTABLE}"
                    --no-translations
                    --qmldir "${CMAKE_CURRENT_SOURCE_DIR}"
                    "$<TARGET_FILE:${CMAKE_PROJECT_NAME}>"
            COMMENT "windeployqt: copying the Qt libraries next to the exe"
        )
    else()
        message(WARNING "windeployqt not found: the Qt libraries are not copied")
    endif()
endif()

# The PCAN-Basic DLL goes next to the exe (the post-build copy above puts it only
# in the build folder).
if(WIN32)
    install(FILES "${PCAN_BASIC_DIR}/Bin/PCANBasic.dll"
            DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()
