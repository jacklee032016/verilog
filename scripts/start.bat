@ECHO OFF

SET "PWD_DIR=%~dp0"
echo %PWD_DIR%

rem
rem set "SIM_HOME=C:\Aldec\Active-HDL-Student-Edition;"
rem Starter Verion
set "SIM_HOME=Z:\intelFPGA_pro\20.4\modelsim_ase\win32aloem;"
rem 
rem set "SIM_HOME=z:\intelfpga_pro\20.4\modelsim_ae\win32aloem;"


@ECHO ON
echo %SIM_HOME%

set "PATH=%SIM_HOME%\bin;%PATH%"

echo %PATH%
