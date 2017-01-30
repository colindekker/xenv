@ECHO OFF

SETLOCAL
  ::CALL :MAIN
  ::CALL :PATH
ENDLOCAL

EXIT /B %ERRORLEVEL%

:MAIN
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    CALL xenv.base.cmd

    ECHO.

    ECHO XENV (ENV)
      ECHO  - XENV (Root) !_XENV!
        SETX /M XENV   !_XENV!>nul 2>&1
      ECHO  - XENVR (Runtime) !_XENV!\runtime
        SETX /M XENVR  %%XENV%%\runtime >nul 2>&1
      ECHO  - XENVRA (Runtime App) !_XENV!\runtime.app
        SETX /M XENVRA %%XENV%%\runtime.app >nul 2>&1
      ECHO  - XENVS (Server App) !_XENV!\server
        SETX /M XENVS  %%XENV%%\server >nul 2>&1
      ECHO  - XENVRA (Server App) !_XENV!\server.app
        SETX /M XENVSA %%XENV%%\server.app >nul 2>&1
      ECHO  - XENVT (Tools) !_XENV!\tool
        SETX /M XENVT  %%XENV%%\tool >nul 2>&1
      ECHO  - XENVT (Utilities) !_XENV!\util
        SETX /M XENVU  %%XENV%%\util >nul 2>&1

    ECHO XENV:DATA (ENV)
      ECHO  - XENV_DATA (Data root) !_XENV!
        SETX /M XENV_DATA   !_XENV!.DATA >nul 2>&1

    ECHO XENV:TEMP (ENV)
      ECHO  - XENV_TMP (Temp root) !_XENV!
        SETX /M XENV_TMP !_XENV!.TMP >nul 2>&1

    ECHO XENV:TEMP:LOGS (ENV)
      ECHO  - XENV_LOGS (Temp: Logs root) !_XENV!
        SETX /M XENV_LOGS %%XENV_TMP%%\logs >nul 2>&1

    ECHO XENV:TEMP:CACHE (ENV)
      ECHO  - XENV_CACHE (Temp: Cache root) !_XENV!
        SETX /M XENV_CACHE %%XENV_TMP%%\cache >nul 2>&1

    ECHO XENV:BASE (ENV)
      ECHO Outputting all options plus selection to !_XENV!\versions.json
      
      DEL !_XENV!\versions.json
      ECHO 'xenv': { >>!_XENV!\versions.json

      PUSHD !_XENV!
      
      CALL :SECTION !_XENV!

      ECHO } >> !_XENV!\versions.json
  ENDLOCAL
GOTO :EOF


:USER
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _XENV_USER=%~1
    SET _XENV_USER_PWD=%~1

    NET USER %_XENV_USER%>NUL 2>&1
    IF NOT ERRORLEVEL 1 (
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

    NET USER %_XENV_USER%>NUL 2>&1
    IF ERRORLEVEL 2 (
      ECHO   - Adding user and user permissions
      net user %_XENV_USER% %_XENV_USER_PWD% /add>NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO     user added
        
        ECHO       granting logomn rights
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

:PATH
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    ECHO XENV:PATH
      ECHO - making backup
        ECHO %PATH% >> %~dp0log\path.backup
      ECHO XENV:PATH:USER (EXISTING)
        FOR /f "usebackq tokens=2,*" %%A IN (`reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH`) DO SET MACHINEPATH=%%B
        SET PATH_TMP=!MACHINEPATH!
        ::ECHO - existing path !PATH_TMP!
      ECHO XENV:PATH (SYS)
        SET PATH_TMP=%%SYSTEMROOT%%;%%SYSTEMROOT%%\System32;%%SYSTEMROOT%%\System32\Wbem;
      ::ECHO XENV:PATH (SYS:INTEL)
        ::SET PATH_TMP=!PATH_TMP!;C:\PROGRA~1\COMMON~1\Intel\WIRELE~1;C:\PROGRA~1\Intel\WiFi\bin";C:\PROGRA~1\Intel\INTEL(~2\DAL;C:\PROGRA~1\Intel\INTEL(~2\IPT;C:\PROGRA~2\Intel\INTEL(~2\DAL;C:\PROGRA~2\Intel\INTEL(~2\IPT;C:\PROGRA~2\NVIDIA~1\PhysX\Common
      ::ECHO XENV:PATH (SYS:SERVER)
        ::SET PATH_TMP=!PATH_TMP!;%%XENVS%%\apache\on\bin;%%XENVS%%\couchdb\on\bin;%%XENVS%%\elasticsearch\on\bin;%%XENVS%%\mariadb\on\bin;%%XENVS%%\mongodb\on\bin;%%XENVS%%\postgresql\on\bin;%%XENVS%%\tomcat\on\bin
      ::ECHO XENV:PATH (SYS:SERVER.APP)
      ECHO XENV:PATH (SYS:RUNTIME)
        SET PATH_TMP=!PATH_TMP!;%%XENVR%%\dotnet\on;%%XENVR%%\erlang\on;%%XENVR%%\go\on\bin;%%XENVR%%\java\on\bin;%%XENVR%%\node\on;%%XENVR%%\perl\on\bin;%%XENVR%%\php\on;%%XENVR%%\python\on\bin;%%XENVR%%\racket\on;%%XENVR%%\ruby\on\bin
      ECHO XENV:PATH (SYS:RUNTIME.APP)
        SET PATH_TMP=!PATH_TMP!;%%XENVRA%%\dotnet.dnx\on\dnvm;%%XENVRA%%\perl.pcre\on\bin
      ECHO XENV:PATH (UTIL)
        SET PATH_TMP=!PATH_TMP!;%%XENVU%%\gnu\on\bin;%%XENVU%%\openssl\on\bin
      ::ECHO XENV:PATH (TOOL)

      SETX /M PATH !PATH_TMP!>NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO   - system path set
      )

    ECHO XENV:PATH:USER
      ECHO XENV:PATH:USER (EXISTING)
        FOR /f "usebackq tokens=2,*" %%A IN (`reg query HKCU\Environment /v PATH`) DO SET USERPATH=%%B
        SET PATH_TMP_USER=%USERPATH%
      ECHO PATH:USER (UTIL)
        SET PATH_TMP_USER=!PATH_TMP_USER!;%%XENVU%%\git\on\bin;%%XENVU%%\git\on\cmd;%%XENVU%%\jq\on;%%XENVU%%\uuidgen\on\bin;%%XENVU%%\yarn\on\bin
      ECHO PATH:USER (TOOL)
        SET PATH_TMP_USER=!PATH_TMP_USER!;%%XENVT%%\docker\on\bin;%%XENVT%%\vagrant\on\bin;%%XENVT%%\vbox\on;%%XENVT%%\vim\on\bin;%%XENVT%%\vscode\on\bin

      SETX PATH !PATH_TMP_USER!>NUL 2>&1
      IF NOT ERRORLEVEL 1 (
        ECHO   - user path set
      )
  ENDLOCAL
GOTO :EOF

:SECTION
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _XENV=%~1
    
    FOR /D %%S IN (*) DO (
      SET _SECTION=%%S

      IF NOT "!_SECTION:~0,1!"=="_" (
        ECHO - !_SECTION!

        PUSHD "!_XENV!\!_SECTION!"

        CALL :TOOL !_XENV! !_SECTION!
      )
    )
  ENDLOCAL
GOTO :EOF

:TOOL
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _XENV=%~1
    SET _SECTION=%~2
    
    ECHO   '!_SECTION!s': [ >> !_XENV!\versions.json
    
    FOR /D %%T IN (*) DO (
      SET _TOOL=%%T

      IF NOT "!_TOOL:~0,1!"=="_" (
        ECHO   - !_SECTION!: !_TOOL!
        
        FOR /F %%A IN ('%~dp0util/ucase.bat !_TOOL!') DO (
          SET _TOOLU=%%A
        )
        
        IF NOT EXIST "!_XENV!\!_SECTION!\!_TOOL!\%_XD%" MKDIR "!_XENV!\!_SECTION!\!_TOOL!\%_XD%"
        IF NOT EXIST "!_XENV!\!_SECTION!\!_TOOL!\%_XD%\%_CONF%" MKDIR "!_XENV!\!_SECTION!\!_TOOL!\%_XD%\%_CONF%"
        IF NOT EXIST "!_XENV!\!_SECTION!\!_TOOL!\%_XD%\%_SCRIPT%" MKDIR "!_XENV!\!_SECTION!\!_TOOL!\%_XD%\%_SCRIPT%"
        
        PUSHD "!_XENV!\!_SECTION!\!_TOOL!"
        
        ECHO     '!_TOOL!': { >> !_XENV!\versions.json

        CALL :VERSIONLIST
        CALL :VERSION

        ECHO     }, >> !_XENV!\versions.json
      )
    )
    
    ECHO   ], >> !_XENV!\versions.json
  ENDLOCAL
GOTO :EOF

:VERSIONLIST
  SET _INDEX=1
  
  ECHO       'versions': [ >> !_XENV!\versions.json
  FOR /d %%V IN (*) DO (
    SET _VERSION=%%V
     
    IF NOT "!_VERSION:~0,1!"=="_" (
      IF NOT "!_VERSION!"=="on" (
        ECHO     - version: !_VERSION!
        
        ECHO         '!_VERSION!', >> !_XENV!\versions.json

        SET "_SUBFOLDERS[!_INDEX!]=!_VERSION!"          
        SET /a _INDEX!+=1
      )
    )
  )

  ECHO       ], >> !_XENV!\versions.json
GOTO :EOF

:VERSION
  SET /A _UBOUND=!_INDEX!-1
  
  ECHO       Found !_UBOUND! choice(s) for !_TOOL! in !_SECTION!
  
  IF !_UBOUND! GTR 1 (
    ECHO        - enter the entry's number to select the desired version
    
    FOR /l %%I IN (1,1,!_UBOUND!) DO (
      ECHO       !_SUBFOLDERS[%%I]! ^(%%I^)
    )

    CALL :CHOICELOOP !_UBOUND!
    SET CHOSEN=!_CHOSEN!
    FOR /L %%C IN (!_UBOUND!,-1,1) DO (
      IF "%%C"=="!CHOSEN!" (
        ECHO       selected !_SUBFOLDERS[%%C]! for !_TOOL! in !_SECTION!

        ECHO       'selected': '!_SUBFOLDERS[%%C]!' >>!XENV!\versions.json

        SET _TOOLVERSION="!_SUBFOLDERS[%%C]!"
      )
    )
  ) ELSE (
    ECHO        - selected only option !_SUBFOLDERS[1]!
    
    ECHO       'selected': '!_SUBFOLDERS[1]!' >>!XENV!\versions.json
    
    SET _TOOLVERSION="!_SUBFOLDERS[1]!"
  )
  
  FOR /f "tokens=1 delims=." %%M IN (!_TOOLVERSION!) DO ( SET _TOOLVERSION_MAJOR=%%M )
  ECHO       Creating symlink 'on' that points to the chosen version '!_TOOLVERSION!'
  IF EXIST %_SL% RMDIR %_SL%
  MKLINK /D on !_XENV!\!_SECTION!\!_TOOL!\!_TOOLVERSION!>NUL 2>&1

  ECHO       Storing selected version as environment variable '!_TOOLU!_VERSION' and '!_TOOLU!_MAJOR_VERSION'
  SETX /M !_TOOLU!_VERSION !_TOOLVERSION!>NUL 2>&1
  SETX /M !_TOOLU!_MAJOR_VERSION !_TOOLVERSION_MAJOR!>NUL 2>&1
GOTO :EOF

:CHOICELOOP
  SET MESSAGE="	Enter the number of your choice:"
  
  SET /p MAKECHOICE=
  IF "%MAKECHOICE%"=="" GOTO CHOICELOOP
  IF %MAKECHOICE% LSS 1 GOTO CHOICELOOP
  IF %MAKECHOICE% GTR %_UBOUND% GOTO CHOICELOOP
  
  SET _CHOSEN=%MAKECHOICE%
GOTO :EOF
