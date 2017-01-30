@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET XENV_SERVICE=mysql
SET XENV_SERVICE_TYPE=server
SET XENV_SERVICE_VERSION=%MYSQL_VERSION%

ECHO Working from XENV actual root drive
%XENVR:~0,2% & cd\

ECHO Service variables
  SET XENV_USER=%ComputerName%\xenv
  SET XENV_USERPWD=Password123
  SET XENV_SERVICE_ID=xenv-%XENV_SERVICE%
  SET XENV_SERVICE_DISPLAY_NAME=xenv-%XENV_SERVICE%

  ECHO  - generating %XENV_SERVICE% instance uuid
    FOR /f %%i IN ('%XENVU%\uuidgen\uuidgen') DO SET UUID=%%i
    SET UUID=%UUID:-=%
    ECHO    - using %UUID%

ECHO Working dirs
  ECHO - setting variables
    SET CONF_DIR=%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\_xenv\conf
    SET ROOT_DIR=%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%
    SET DATA_DIR=%XENV_DATA%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%
    SET LOG_DIR=%XENV_LOGS%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%
    SET TMP_DIR=%XENV_TMP%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%

  ECHO - translate working dir paths to linux format
    SET "CONF_DIR_UNIX=%CONF_DIR:\=/%"
    SET "ROOT_DIR_UNIX=%ROOT_DIR:\=/%"
    SET "DATA_DIR_UNIX=%DATA_DIR:\=/%"
    SET "LOG_DIR_UNIX=%LOG_DIR:\=/%"
    SET "TMP_DIR_UNIX=%TMP_DIR:\=/%"

  ECHO - checking existence of working dirs
    ECHO   - check log dir
      IF NOT EXIST %LOG_DIR% ( mkdir %LOG_DIR% )
    ECHO   - check tmp dir
      IF NOT EXIST %TMP_DIR% ( mkdir %TMP_DIR% )
    ECHO   - check data dir
      IF NOT EXIST %DATA_DIR% ( mkdir %DATA_DIR% )

ECHO Service
  ECHO - checking for existing service instance
    sc query state= all | findstr /C:"SERVICE_NAME: %XENV_SERVICE_ID%">NUL 2>&1
    IF NOT ERRORLEVEL 1 (
      ECHO   - stopping
      NET STOP "%XENV_SERVICE_ID%"
      ::>NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO     - stopped
      )

      ECHO   - removing
        CALL :DELETESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
        IF NOT ERRORLEVEL 1 (
          ECHO     - removed
        )
    )
  
  ECHO - setting %XENV_SERVICE_TYPE% specific environment variables

  ECHO - generating %XENV_SERVICE_TYPE% config files
    CALL :CONFIGURESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
    
  ECHO - initialize %XENV_SERVICE_TYPE% service
    CALL :INITIALIZESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"

  ECHO - install and start %XENV_SERVICE_TYPE% as a service
    ECHO   - install
    CALL :CREATESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
ENDLOCAL
GOTO :EOF

:DELETESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  
  SET XENV_SERVICE_ID=%~1
  SET XENV_SERVICE_TYPE=%~2
  SET XENV_SERVICE=%~3
  SET XENV_SERVICE_VERSION=%~4
  SET CONF_DIR_UNIX=%~5
  SET ROOT_DIR_UNIX=%~6
  SET DATA_DIR_UNIX=%~7
  SET LOG_DIR_UNIX=%~8
  SET TMP_DIR_UNIX=%~9

  ECHO      - using command "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\mysqld.exe" --remove "%XENV_SERVICE_ID%"
  "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\mysqld.exe" --remove "%XENV_SERVICE_ID%"
  ::>NUL 2>&1

  ENDLOCAL
GOTO :EOF

:CONFIGURESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  
  SET XENV_SERVICE_ID=%~1
  SET XENV_SERVICE_TYPE=%~2
  SET XENV_SERVICE=%~3
  SET XENV_SERVICE_VERSION=%~4
  SET CONF_DIR_UNIX=%~5
  SET ROOT_DIR_UNIX=%~6
  SET DATA_DIR_UNIX=%~7
  SET LOG_DIR_UNIX=%~8
  SET TMP_DIR_UNIX=%~9

  IF NOT EXIST "%ROOT_DIR_UNIX%/my.ini" (
    COPY "%CONF_DIR_UNIX%\my.ini" "%ROOT_DIR_UNIX%"
    ECHO basedir="%ROOT_DIR_UNIX%" >> "%ROOT_DIR_UNIX%/my.ini"
    ECHO datadir="%DATA_DIR_UNIX%" >> "%ROOT_DIR_UNIX%/my.ini"
    ECHO lc-messages-dir="%ROOT_DIR_UNIX%/share" >> "%ROOT_DIR_UNIX%/my.ini"
    ECHO log-error="%LOG_DIR_UNIX%/mysql.log" >> "%ROOT_DIR_UNIX%/my.ini"
  ) ELSE (
    ECHO   - already generated
  )

  ECHO      - done
  ENDLOCAL
GOTO :EOF

:INITIALIZESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  
  SET XENV_SERVICE_ID=%~1
  SET XENV_SERVICE_TYPE=%~2
  SET XENV_SERVICE=%~3
  SET XENV_SERVICE_VERSION=%~4
  SET CONF_DIR_UNIX=%~5
  SET ROOT_DIR_UNIX=%~6
  SET DATA_DIR_UNIX=%~7
  SET LOG_DIR_UNIX=%~8
  SET TMP_DIR_UNIX=%~9
  
  IF NOT EXIST "%DATA_DIR%\mysql" (
    "%ROOT_DIR_UNIX%/bin/mysqld.exe" --defaults-file="%ROOT_DIR_UNIX%/my.ini"  --initialize
  )
  
  IF NOT EXIST "%CONF_DIR%\my.password" (
    SET "LASTOCCUR="
    FOR /F "delims=" %%G IN ('FINDSTR /C:"root@localhost:" "%LOG_DIR%\mysql.log"') DO (
      SET "LASTOCCUR=%%G"
   )

    IF "!LASTOCCUR!" NEQ "" (
      ECHO   - found temporary password in log file
      FOR /f "tokens=1,2,3,4 delims=:" %%a IN ("!LASTOCCUR!") DO (
        SET PW=%%d
        SET PW=!PW:~1!
      )

      ECHO   - updating password for root
        ECHO     - starting %XENV_SERVICE_ID% config instance 
          START cmd /C "%ROOT_DIR_UNIX%/bin/mysqld.exe" --init-file="%CONF_DIR_UNIX%/my.ini.sql"
          IF NOT ERRORLEVEL 1 (
            ECHO   -   Updated, waiting 5s before killing %XENV_SERVICE_ID% config instance 
            PING 127.0.0.1 -n 6 > NUL
            TASKKILL /IM mysqld.exe /F
          )
    ) ELSE (
      "%ROOT_DIR_UNIX%/bin/mysql.exe" -u root -p
      Password123
      exit
      ECHO "%CD%"

      ECHO   - already initialized
    )
  )

  ECHO      - done
  ENDLOCAL
GOTO :EOF

:CREATESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  
  SET XENV_SERVICE_ID=%~1
  SET XENV_SERVICE_TYPE=%~2
  SET XENV_SERVICE=%~3
  SET XENV_SERVICE_VERSION=%~4
  SET CONF_DIR_UNIX=%~5
  SET ROOT_DIR_UNIX=%~6
  SET DATA_DIR_UNIX=%~7
  SET LOG_DIR_UNIX=%~8
  SET TMP_DIR_UNIX=%~9
  
  ECHO     - using command "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\mysqld.exe" --install "%XENV_SERVICE_ID%" --defaults-file="%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\my.ini"
    "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\mysqld.exe" --install "%XENV_SERVICE_ID%" --defaults-file="%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\my.ini"
    ::>NUL 2>&1

    IF NOT ERRORLEVEL 1 (
      ECHO     - installed
      ECHO   - start
      NET START %XENV_SERVICE_ID%
      ::>NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO     - started
      )
    )
  
  ECHO      - done
  ENDLOCAL
GOTO :EOF