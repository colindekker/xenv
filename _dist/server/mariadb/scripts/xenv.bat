@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET XENV_SERVICE=mariadb

SET SERVICE_ID=xenv-%XENV_SERVICE%
SET SERVICE_DISPLAY_NAME=xenv-%XENV_SERVICE%

ECHO SERVICE: %XENV_SERVICE%
ECHO SERVICE:ID: %SERVICE_ID%
ECHO SERVICE:NAME: %SERVICE_DISPLAY_NAME%

SET CONF_DIR=%XENVS%\%XENV_SERVICE%\_shared\conf
SET DATA_DIR=%XENV_DATA%\server\%XENV_SERVICE%\%MARIADB_VERSION%
SET LOG_DIR=%XENV_LOGS%\server\%XENV_SERVICE%\%MARIADB_VERSION%
SET TMP_DIR=%XENV_TMP%\server\%XENV_SERVICE%\%MARIADB_VERSION%

SET MYSQL_HOME=%XENVS%\%XENV_SERVICE%\%MARIADB_VERSION%

SET "MYSQL_HOME_UNIX=%MYSQL_HOME:\=/%"
SET "DATA_DIR_UNIX=%DATA_DIR:\=/%"
SET "LOG_DIR_UNIX=%LOG_DIR:\=/%"

%XENVR:~0,2% & cd\

ECHO If log dir has not been initialized yet, do so.
IF NOT EXIST %LOG_DIR% (  ECHO "- initialize" & mkdir "%LOG_DIR%" )

ECHO If tmp dir has not been initialized yet, do so.
IF NOT EXIST %TMP_DIR% (  ECHO "- initialize" & mkdir "%TMP_DIR%" )

ECHO If data dir has not been initialized yet, do so.
IF NOT EXIST "%DATA_DIR%" (   ECHO "- initialize" & mkdir "%DATA_DIR%" )

copy %CONF_DIR%\my.ini %MYSQL_HOME%
echo basedir="%MYSQL_HOME_UNIX%" >> %MYSQL_HOME%\my.ini
echo datadir="%DATA_DIR_UNIX%" >> %MYSQL_HOME%\my.ini
echo log-error="%LOG_DIR_UNIX%/mariadb.log" >> %MYSQL_HOME%\my.ini

ECHO Delete existing service if found
sc query state= all | findstr /C:"SERVICE_NAME: %SERVICE_ID%"
if not ERRORLEVEL 1 (net stop %SERVICE_ID% & "%XENVS%\%XENV_SERVICE%\%MARIADB_VERSION%\bin\mysqld.exe" --remove %SERVICE_ID%)

ECHO If data dir has not been initialized yet, do so.
IF NOT EXIST %LOG_DIR% ( ECHO "- initialize" & mkdir %LOG_DIR% )

ECHO If MariaDB data dir has not been initialized yet, do so.
IF NOT EXIST "%XENV_DATA%\server\%XENV_SERVICE%\%MARIADB_VERSION%" (
  ECHO - initialize
  mkdir "%XENV_DATA%\server\%XENV_SERVICE%\%MARIADB_VERSION%"
  %XENVS%\%XENV_SERVICE%\%MARIADB_VERSION%\bin\mysql_install_db.exe --datadir=%XENV_DATA%\server\%XENV_SERVICE%\%MARIADB_VERSION% --password=p@$$w0rd --port=3307
)

ECHO If MariaDB data dir symlink has not been initialized yet, do so.
IF NOT EXIST %XENV_DATA%\server\%XENV_SERVICE%\on (
  ECHO - create symlink
  mklink /D %XENV_DATA%\server\%XENV_SERVICE%\on %XENV_DATA%\server\%XENV_SERVICE%\%MARIADB_VERSION%
)

%MYSQL_HOME%\bin\mysqld.exe --install %SERVICE_ID% --defaults-file="%MYSQL_HOME%\my.ini"
net start %SERVICE_ID%

ENDLOCAL