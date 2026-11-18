include("C:/Git/BusWrench/SW/BusWrenchApp-Release/.qt/QtDeploySupport.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/BusWrenchApp-plugins.cmake" OPTIONAL)
set(__QT_DEPLOY_I18N_CATALOGS "qtbase;qtdeclarative;qtserialport")

qt6_deploy_qml_imports(TARGET BusWrenchApp PLUGINS_FOUND plugins_found)
qt6_deploy_runtime_dependencies(
    EXECUTABLE "C:/Git/BusWrench/SW/BusWrenchApp-Release/BusWrenchApp.exe"
    ADDITIONAL_MODULES ${plugins_found}
    GENERATE_QT_CONF
    NO_TRANSLATIONS
)