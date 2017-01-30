@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET XENV_SERVICE=elasticsearch

SET SERVICE_ID=xenv-%XENV_SERVICE%
SET SERVICE_DISPLAY_NAME=xenv-%XENV_SERVICE%

ECHO SERVICE: %XENV_SERVICE%
ECHO SERVICE:ID: %SERVICE_ID%
ECHO SERVICE:NAME: %SERVICE_DISPLAY_NAME%

SET CONF_DIR=%XENVS%\%XENV_SERVICE%\_shared\conf
SET DATA_DIR=%XENV_DATA%\server\%XENV_SERVICE%\%ELASTICSEARCH_VERSION%
SET LOG_DIR=%XENV_LOGS%\server\%XENV_SERVICE%\%ELASTICSEARCH_VERSION%

SET ES_HOME=%XENVS%\%XENV_SERVICE%\%ELASTICSEARCH_VERSION%
SET ES_START_TYPE=auto

%XENVR:~0,2% & cd\
cd %XENVS%\%XENV_SERVICE%\on

ECHO Delete existing service if found
sc query state= all | findstr /C:"SERVICE_NAME: %SERVICE_ID%"
if not ERRORLEVEL 1 (net stop %SERVICE_ID% & "%XENVS%\%XENV_SERVICE%\on\bin\elasticsearch-service.bat" remove %SERVICE_ID%)

%XENVR:~0,2% & cd\

ECHO If data dir has not been initialized yet, do so.
IF NOT EXIST "%DATA_DIR%" (
  ECHO - initialize
  mkdir "%DATA_DIR%" 
)

ECHO If data dir has not been initialized yet, do so.
IF NOT EXIST %LOG_DIR% (
  ECHO - initialize
  mkdir %LOG_DIR%
)

ECHO If data dir symlink has not been initialized yet, do so.
IF NOT EXIST %XENV_DATA%\server\%XENV_SERVICE%\on (
  ECHO - create symlink
  mklink /D %XENV_DATA%\server\%XENV_SERVICE%\on "%DATA_DIR%"
)

echo %XENVS%\%XENV_SERVICE%\%ELASTICSEARCH_VERSION%\bin\elasticsearch-service.bat

%XENVS%\%XENV_SERVICE%\%ELASTICSEARCH_VERSION%\bin\elasticsearch-service.bat install %SERVICE_ID% & net start %SERVICE_ID%

ENDLOCAL