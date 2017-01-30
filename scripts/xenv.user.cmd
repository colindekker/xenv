@ECHO OFF

SETLOCAL
  ECHO XENV:USER
  CALL :USER xenv Password123
ENDLOCAL

EXIT /B %ERRORLEVEL%

:USER
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _XENV_USER=%~1
    SET _XENV_USER_PWD=%~2
    SET _XENV_USER_ACTION=%~3

    net user %_XENV_USER%>NUL 2>&1
    IF NOT ERRORLEVEL 1 (
      IF "%_XENV_USER_ACTION%"=="remove" (
        ECHO   - deleting user, user permissions and profile
        :: ADD LOOP 
        ECHO       removing permissions on "%XENV%"
        icacls %XENV% /remove:g "%_XENV_USER%" /T>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     removed granted read and execute permissions on "%XENV%" 
        )
        
        ECHO       removing permissions on "%XENV_DATA%"
        icacls %XENV_DATA% /remove:g "%_XENV_USER%" /T>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     removed granted full control permissions on "%XENV_DATA%"
        )

        ECHO       removing permissions on "%XENV_LOGS%"
        icacls %XENV_LOGS% /remove:g "%_XENV_USER%" /T>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     removed granted full control permissions on "%XENV_LOGS%"
        )
          
        net user "%_XENV_USER%" /DELETE
        "%XENVU%\delprof2\on\delprof2.exe" /u
      )
    )

    NET USER %_XENV_USER%>NUL 2>&1
    IF ERRORLEVEL 2 (
      ECHO   - Adding user and user permissions
      net user %_XENV_USER% %_XENV_USER_PWD% /add>NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO     user added
        
        ECHO       granting logon rights
        "%XENVU%\rktools\ntrights" +r SeServiceLogonRight -u %_XENV_USER%>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     user granted logon as a service permissions on "%XENV%" 
        )
        
        ECHO       granting permissions on "%XENV%"
        icacls "%XENV%" /grant "%ComputerName%\%_XENV_USER%:(OI)(CI)RX" /T>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     user granted read and execute permissions on "%XENV%" 
        )
        
        ECHO       granting permissions on "%XENV_DATA%"
        icacls "%XENV_DATA%" /grant "%ComputerName%\%_XENV_USER%:(OI)(CI)F" /T>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     user granted full control permissions on "%XENV_DATA%"
        )
        
        ECHO       granting permissions on "%XENV_LOGS%"
        icacls "%XENV_LOGS%" /grant "%ComputerName%\%_XENV_USER%:(OI)(CI)F" /T>NUL 2>&1
        IF NOT ERRORLEVEL 1 (
          ECHO     user granted full control permissions on "%XENV_LOGS%"
        )
      )
    )
    
    gpupdate /force
  ENDLOCAL
GOTO :EOF