call "%VC_ROOT%\vcvarsall.bat" x64
mkdir ..\build\glm
cd ..\build\glm
set PMLS_DIR=%PMLS_INSTALL_DIR:\=/%

cmake -A x64 -T v141 -DCMAKE_CONFIGURATION_TYPES:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH="%PMLS_DIR%/glm"^
 ..\..\pmls4matlab\glm

devenv /build "Release|x64" /project ALL_BUILD glm.sln
devenv /build "Release|x64" /project INSTALL glm.sln
 