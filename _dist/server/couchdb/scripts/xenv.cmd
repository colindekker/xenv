@ECHO OFF
cls
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  ECHO Service
  ECHO - initialize service
  ::ECHO   - default user db
  
  SET ADMIN_LOGIN_REQUIRED=
  
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
ENDLOCAL

EXIT /B %ERRORLEVEL%

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