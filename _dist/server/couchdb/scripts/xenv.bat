@ECHO OFF

:MAIN
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  SET XENV_SERVICE=couchdb
  SET XENV_SERVICE_TYPE=server
  SET XENV_SERVICE_VERSION=%COUCHDB_VERSION%

  ECHO Working from XENV actual root drive
  %XENVR:~0,2% & cd\

  ECHO Service variables
    SET XENV_USER_PWD=Password123
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
    ECHO - working from erlang bin dir
      pushd %XENVS%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\erts-*\bin

    ECHO - checking for existing service instance
      sc query state= all | findstr /C:"SERVICE_NAME: %XENV_SERVICE_ID%" >NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO   - stopping
        NET STOP "%XENV_SERVICE_ID%" >NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     - stopped
        )

        ECHO   - removing
          CALL :DELETESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
      )
    
    ECHO - setting %XENV_SERVICE_TYPE% specific environment variables

    ECHO - generating %XENV_SERVICE_TYPE% config files
      CALL :CONFIGURESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"

    ECHO - install and start %XENV_SERVICE_TYPE% as a service
      CALL :CREATESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
      
    ECHO - initialize %XENV_SERVICE_TYPE% service
      CALL :INITIALIZESERVICE "%XENV_SERVICE_ID%" "%XENV_SERVICE_TYPE%" "%XENV_SERVICE%" "%XENV_SERVICE_VERSION%" "%CONF_DIR_UNIX%" "%ROOT_DIR_UNIX%" "%DATA_DIR_UNIX%" "%LOG_DIR_UNIX%" "%TMP_DIR_UNIX%"
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

  ECHO      - using command "%CD%\erlsrv.exe" remove %XENV_SERVICE_ID%
  "%CD%\erlsrv.exe" remove %XENV_SERVICE_ID% >NUL 2>&1
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

  ECHO   - vm.args
    COPY /Y "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\_xenv\conf\vm.args" "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc"
    ECHO -sname %XENV_SERVICE_ID% >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\vm1.args"
    ECHO -setcookie %XENV_SERVICE_ID% >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\vm1.args"
    TYPE "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\vm.args" >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\vm1.args"
    DEL "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\vm.args"
    PUSHD "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc"
    REN vm1.args vm.args
    POPD

  ECHO   - local.ini
    COPY /Y "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\_xenv\conf\local.ini" "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc"
    ECHO [couchdb] >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\local.ini"
    ECHO uuid = %UUID% >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\local.ini"
    ECHO database_dir = %DATA_DIR% >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\local.ini"
    ECHO [log] >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\local.ini"
    ECHO file = %LOG_DIR%/couch.log >> "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\etc\local.ini"

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
  
  ECHO Copy library DLLs to root dir
    COPY /Y "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\*.dll" "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%" >NUL 2>&1
  ::ECHO   - starting "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\couchdb.cmd
  ::  START cmd /C "%XENV%\%XENV_SERVICE_TYPE%\%XENV_SERVICE%\%XENV_SERVICE_VERSION%\bin\couchdb.cmd
  ::ECHO   - wait 5s 
  ::  PING 127.0.0.1 -n 6 > nul
  
  SET ADMIN_LOGIN_REQUIRED=
  SET ADMIN_EXISTS=
  SET USER_ADMIN_LOGIN_REQUIRED=
  SET USER_ADMIN_EXISTS=
  SET DB_LOGIN_REQUIRED=
  SET DB_EXISTS=
  
  ECHO   - admin
    ECHO       creating

    CURL -s -X PUT http://127.0.0.1:5986/_config/admins/admin -d "\"Password123\"" > E:\XENV\temp.txt
    CALL :CHECKCURL errorunauthorized
    SET ADMIN_LOGIN_REQUIRED=%CHECKCURL_RESULT%
    ECHO       ADMIN_LOGIN_REQUIRED %ADMIN_LOGIN_REQUIRED%
    IF "!ADMIN_LOGIN_REQUIRED!"=="1" (
      ECHO       retrying with credentials
      CURL -s -X PUT http://admin:Password123@127.0.0.1:5986/_config/admins/admin -d "\"Password123\"" > E:\XENV\temp.txt
      CALL :CHECKCURL pbkdf2
      SET ADMIN_EXISTS=%CHECKCURL_RESULT%
      ECHO         ADMIN_EXISTS !ADMIN_EXISTS!
      IF "!ADMIN_EXISTS!"=="1" (
        ECHO       admin exists
      )
    ) ELSE (
      CURL -s -X PUT http://127.0.0.1:5986/_config
    )
  
  ECHO   - default user
    ECHO       creating
    CURL -s -X PUT "http://127.0.0.1:5986/_users/org.couchdb.user:admin" ^
      -H "Accept: application/json" ^
      -H "Content-Type: application/json" ^
      -d "{\"name\": \"admin\", \"password\": \"Password123\", \"roles\": [], \"type\": \"user\"}" > E:\XENV\temp.txt
    CALL :CHECKCURL errorunauthorized
    SET USER_ADMIN_LOGIN_REQUIRED=%CHECKCURL_RESULT%
    ECHO         USER_ADMIN_LOGIN_REQUIRED !USER_ADMIN_LOGIN_REQUIRED!

    IF "!USER_ADMIN_LOGIN_REQUIRED!" == "1" (
      ECHO       retrying with credentials
      CURL -s -X PUT "http://admin:Password123@127.0.0.1:5986/_users/org.couchdb.user:admin" ^
        -H "Accept: application/json" ^
        -H "Content-Type: application/json" ^
        -d "{\"name\": \"admin\", \"password\": \"Password123\", \"roles\": [], \"type\": \"user\"}" > E:\XENV\temp.txt
      CALL :CHECKCURL errorconflict
      SET USER_ADMIN_EXISTS=%CHECKCURL_RESULT%
      ECHO         USER_ADMIN_EXISTS !USER_ADMIN_EXISTS!
      IF "!USER_ADMIN_EXISTS!" == "1" (
        ECHO       user admin exists
      )
    )

  ECHO   - default database
    CURL -s -X PUT "http://127.0.0.1:5984/xenv" > E:\XENV\temp.txt
    CALL :CHECKCURL errorunauthorized
    SET DB_LOGIN_REQUIRED=%CHECKCURL_RESULT%
    ECHO         DB_LOGIN_REQUIRED !DB_LOGIN_REQUIRED!

    IF "!DB_LOGIN_REQUIRED!" == "1" (
      ECHO       retrying with credentials
      CURL -s -X PUT http://admin:Password123@127.0.0.1:5984/xenv > E:\XENV\temp.txt
      CALL :CHECKCURL errorconflict
      SET DB_EXISTS=%CHECKCURL_RESULT%
      ECHO         DB_EXISTS !DB_EXISTS!
      IF "!DB_EXISTS!" == "1" (
        ECHO       default db exists
      ) ELSE (
        ECHO       default db created
      )
    )

  ::ECHO   - config complete, killing couchdb config instance
    ::TASKKILL /IM erl.exe /F 

  ENDLOCAL
GOTO :EOF

:CHECKCURL
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET TXT=%~1

    SET /p CURL_OUTPUT=<E:\XENV\temp.txt
    ::ECHO output !CURL_OUTPUT!
    DEL E:\XENV\temp.txt
    SET CURL_OUTPUT=!CURL_OUTPUT:"=!
    SET CURL_OUTPUT=!CURL_OUTPUT:,=!
    SET CURL_OUTPUT=!CURL_OUTPUT::=!
    SET CURL_OUTPUT=!CURL_OUTPUT:{=!
    SET CURL_OUTPUT=!CURL_OUTPUT:}=!
    SET CURL_OUTPUT=!CURL_OUTPUT:.=!

    SET LEFT=x!CURL_OUTPUT:%TXT%=!
    SET RIGHT=x!CURL_OUTPUT!

    SET _CHECKCURL_RESULT=
    if NOT "!LEFT!"=="!RIGHT!" (
      SET _CHECKCURL_RESULT=1
    ) ELSE (
      SET _CHECKCURL_RESULT=0
    )

    SET CHECKCURL_RESULT=
  ENDLOCAL & SET CHECKCURL_RESULT=%_CHECKCURL_RESULT%
GOTO :EOF

:CREATESERVICE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  
  SET XENV_SERVICE_ID=%~1
  SET XENV_SERVICE_TYPE=%~2
  SET XENV_SERVICE=%~3
  SET XENV_SERVICE_VERSION=%~4
  
  ECHO   - install
  ECHO     - using command "%CD%\erlsrv.exe" add %XENV_SERVICE_ID% -WorkDir "%ROOT_DIR%" -sname "%XENV_SERVICE_ID%" -debugtype new -args "-boot "%ROOT_DIR%/releases/%COUCHDB_VERSION%/couchdb" -args_file \"%ROOT_DIR%/etc/vm.args\" -config \"%ROOT_DIR%/releases/%COUCHDB_VERSION%/sys.config\""
    "%CD%\erlsrv.exe" add %XENV_SERVICE_ID% -WorkDir "%ROOT_DIR%" -sname "%XENV_SERVICE_ID%" -debugtype new -args "-boot "%ROOT_DIR%/releases/%COUCHDB_VERSION%/couchdb" -args_file \"%ROOT_DIR%/etc/vm.args\" -config \"%ROOT_DIR%/releases/%COUCHDB_VERSION%/sys.config\"" >NUL 2>&1

    IF NOT ERRORLEVEL 1 (
      ECHO     - installed
      ECHO   - start
      "%CD%\erlsrv.exe" start %XENV_SERVICE_ID% >NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO     - started
      )
    )
  
  ECHO      - done
  ENDLOCAL
GOTO :EOF