@ECHO OFF

SETLOCAL
  CALL :MAIN
ENDLOCAL

EXIT /B %ERRORLEVEL%

:MAIN
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET XENV_SERVICE=postgresql
    SET XENV_SERVICE_TYPE=server
    SET XENV_SERVICE_VERSION=%POSTGRESQL_VERSION%

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

    ECHO Service
      ECHO - checking for existing service instance
        sc query state= all | findstr /C:"SERVICE_NAME: %XENV_SERVICE_ID%">NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO   - stopping
          NET STOP "%XENV_SERVICE_ID%">NUL 2>&1
          IF NOT ERRORLEVEL 1 (
            ECHO     - stopped
          )

          ECHO   - removing
            CALL :DELETESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
        )
      
      ECHO - setting %XENV_SERVICE_TYPE% specific environment variables

      ECHO - generating %XENV_SERVICE_TYPE% config files
        CALL :CONFIGURESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR%" "%ROOT_DIR%" "%DATA_DIR%" "%LOG_DIR%" "%TMP_DIR%"

      ECHO - initialize %XENV_SERVICE_TYPE% service
        CALL :INITIALIZESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR%" "%ROOT_DIR%" "%DATA_DIR%" "%LOG_DIR%" "%TMP_DIR%"

      ECHO - install and start %XENV_SERVICE_TYPE% as a service
        CALL :CREATESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR%" "%ROOT_DIR%" "%DATA_DIR%" "%LOG_DIR%" "%TMP_DIR%"
  ENDLOCAL
GOTO :EOF

:DELETESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET XENV_SERVICE_ID=%~1
    SET XENV_SERVICE_TYPE=%~2
    SET XENV_SERVICE=%~3
    SET XENV_SERVICE_VERSION=%~4
    SET CONF_DIR=%~5
    SET ROOT_DIR=%~6
    SET DATA_DIR=%~7
    SET LOG_DIR=%~8
    SET TMP_DIR=%~9

    ECHO      - using command   "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\pg_ctl.exe" unregister -N %XENV_SERVICE_ID%
    "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\pg_ctl.exe" unregister -N %XENV_SERVICE_ID% >NUL 2>&1
    IF NOT ERRORLEVEL 1 (
      ECHO     - removed
    )
  ENDLOCAL
GOTO :EOF

:CONFIGURESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET XENV_SERVICE_ID=%~1
    SET XENV_SERVICE_TYPE=%~2
    SET XENV_SERVICE=%~3
    SET XENV_SERVICE_VERSION=%~4
    SET CONF_DIR=%~5
    SET ROOT_DIR=%~6
    SET DATA_DIR=%~7
    SET LOG_DIR=%~8
    SET TMP_DIR=%~9

    ECHO      - done
  ENDLOCAL
GOTO :EOF

:INITIALIZESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET XENV_SERVICE_ID=%~1
    SET XENV_SERVICE_TYPE=%~2
    SET XENV_SERVICE=%~3
    SET XENV_SERVICE_VERSION=%~4
    SET CONF_DIR=%~5
    SET ROOT_DIR=%~6
    SET DATA_DIR=%~7
    SET LOG_DIR=%~8
    SET TMP_DIR=%~9
    
    SET PGUSER=%XENV_USER%
    SET PGPASSWORD=%XENV_USER_PWD%
    SET PGPORT=5432
    SET PGLOCALEDIR=%ROOT_DIR%\share\locale
    SET PGDATABASE=postgres
    SET PGDATA=%DATA_DIR%

    ECHO checking for existing data in "%DATA_DIR%\base"
    IF NOT EXIST "%DATA_DIR%\base" (
      ECHO initializing using command "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\pg_ctl.exe" init -D "%DATA_DIR%" -l "%LOG_DIR%\postgresql.log"
      "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\pg_ctl.exe" init -D "%DATA_DIR%" -l "%LOG_DIR%\postgresql.log" -U %XENV_USER% -P %XENV_USERPWD%
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
    SET CONF_DIR=%~5
    SET ROOT_DIR=%~6
    SET DATA_DIR=%~7
    SET LOG_DIR=%~8
    SET TMP_DIR=%~9
    
    SET PGUSER=%XENV_USER%
    SET PGPASSWORD=%XENV_USER_PWD%
    SET PGPORT=5432
    SET PGLOCALEDIR=%ROOT_DIR%\share\locale
    SET PGDATABASE=postgres
    SET PGDATA=%DATA_DIR%

    ECHO   - install
      "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\pg_ctl.exe" register -N %XENV_SERVICE_ID% -S auto -U %XENV_USER% -P %XENV_USERPWD% >NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO     - installed
        ECHO   - start
        NET START %XENV_SERVICE_ID% >NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     - started
        )
      )
    
    ECHO      - done
  ENDLOCAL
GOTO :EOF