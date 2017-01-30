@ECHO OFF
cls

SETLOCAL
  REM CALL :MAIN
  CALL :PROCESS_SSL_SITE "rtfd.xenv.dev"
  CALL :PROCESS_SSL_SITE "cv.xenv.dev"
ENDLOCAL

EXIT /B %ERRORLEVEL%

:NETWORK
  SETLOCAL ENABLEEXTENSIONS 
    for /f "delims=[] tokens=2" %%a in ('ping -4 %computername% -n 1 ^| findstr "["') do (set thisip=%%a)
    echo %thisip%
  ENDLOCAL & SET MACHINE_IP=%thisip%
GOTO :EOF

:MAIN
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    CALL %~dp0xenv.base.cmd
    
    cls

    ECHO XENV:CA
    SET CAROOT=%~dp0..\..\..\_ca

    CALL :PROCESS_CA "!CAROOT!" "" "" ""
    CALL :PROCESS_CA "!CAROOT!" "intermediate" "" ""
    CALL :PROCESS_CA "!CAROOT!" "intermediate" "server" "apache"

    CALL :PROCESS_CA_CRL "!CAROOT!" "" "" ""
    CALL :PROCESS_CA_CRL "!CAROOT!" "intermediate" "" ""
    CALL :PROCESS_CA_CRL "!CAROOT!" "intermediate" "server" "apache"

    CALL :PROCESS_CA_SSL "!CAROOT!" "" "" ""
    CALL :PROCESS_CA_SSL "!CAROOT!" "intermediate" "" ""
    CALL :PROCESS_CA_SSL "!CAROOT!" "intermediate" "server" "apache"
  ENDLOCAL
GOTO :EOF

:PROCESS_CA
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _CA_LOCATION=%~1
    SET _CA_LEVEL=%~2
    SET _CA_APPLICATION_TYPE=%~3
    SET _CA_APPLICATION=%~4

    ECHO ca dir structure
      ECHO - !_CA_LEVEL!
      ECHO - !_CA_APPLICATION_TYPE!
      ECHO - !_CA_APPLICATION!
        SET CA_LOCATION=!_CA_LOCATION!

        IF "!_CA_LEVEL!" NEQ "" (
          IF "!_CA_APPLICATION_TYPE!" NEQ "" (
            IF "!_CA_APPLICATION!" NEQ "" (
              SET CA_LOCATION=!_CA_LOCATION!\..\!_CA_APPLICATION_TYPE!\!_CA_APPLICATION!\_xenv\ssl
              SET CA_FILENAME=.!_CA_APPLICATION_TYPE!.!_CA_APPLICATION!
            ) ELSE (
              SET CA_LOCATION=!_CA_LOCATION!\..\!_CA_APPLICATION_TYPE!\_xenv\ssl
              SET CA_FILENAME=.!_CA_APPLICATION!
            )
          ) ELSE (
            SET CA_LOCATION=!CA_LOCATION!\!_CA_LEVEL!
            SET CA_FILENAME=.!_CA_LEVEL!
          )
        )

        CALL :PROCESS_CA_DIR !CA_LOCATION! ""
        CALL :PROCESS_CA_DIR !CA_LOCATION! crt
        CALL :PROCESS_CA_DIR !CA_LOCATION! crl
        CALL :PROCESS_CA_DIR !CA_LOCATION! csr
        CALL :PROCESS_CA_DIR !CA_LOCATION! new
        CALL :PROCESS_CA_DIR !CA_LOCATION! pvt
        CALL :PROCESS_CA_DIR !CA_LOCATION! val

        COPY "%~dp0..\conf\util\openssl\ca!CA_FILENAME!.conf" "!CA_LOCATION!\openssl.conf">NUL 2>&1
    ECHO ----------------
  ENDLOCAL
GOTO :EOF

:PROCESS_CA_CRL
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _CA_LOCATION=%~1
    SET _CA_LEVEL=%~2
    SET _CA_APPLICATION_TYPE=%~3
    SET _CA_APPLICATION=%~4

    ECHO ca crl
      ECHO - !_CA_LEVEL!
      ECHO - !_CA_APPLICATION_TYPE!
      ECHO - !_CA_APPLICATION!
        SET CA_LOCATION=!_CA_LOCATION!

        IF "!_CA_LEVEL!" NEQ "" (
          IF "!_CA_APPLICATION_TYPE!" NEQ "" (
            IF "!_CA_APPLICATION!" NEQ "" (
              SET CA_LOCATION=!_CA_LOCATION!\..\!_CA_APPLICATION_TYPE!\!_CA_APPLICATION!\_xenv\ssl
              SET CA_FILENAME=.!_CA_APPLICATION_TYPE!.!_CA_APPLICATION!
            ) ELSE (
              SET CA_LOCATION=!_CA_LOCATION!\..\!_CA_APPLICATION_TYPE!\_xenv\ssl
              SET CA_FILENAME=.!_CA_APPLICATION!
            )
          ) ELSE (
            SET CA_LOCATION=!CA_LOCATION!\!_CA_LEVEL!
            SET CA_FILENAME=.!_CA_LEVEL!
          )
        )

        ECHO   - crl db
          IF NOT EXIST "!CA_LOCATION!\index.txt.attr" (
            touch "!CA_LOCATION!\index.txt.attr"
            ECHO     - db created
          ) ELSE (
            ECHO     - db exists
          )
        ECHO   - crlnumber db
          IF NOT EXIST "!CA_LOCATION!\crlnumber" (
            touch "!CA_LOCATION!\crlnumber"
            ECHO     - db created
          ) ELSE (
            ECHO     - db exists
          )

        ECHO   - crl
          IF NOT EXIST "!CA_LOCATION!\crl\ca!CA_FILENAME!.crl.pem" (
            openssl ca -config "!CA_LOCATION!\openssl.conf" -gencrl -out "!CA_LOCATION!\crl\ca!CA_FILENAME!.crl.pem"
            REM >NUL 2>&1
          ) ELSE (
            ECHO     - ca.key exists
          )
          
          ECHO     - crl
          IF NOT EXIST "!CA_LOCATION!\val\ca!CA_FILENAME!.crl.val.txt" (
            openssl crl -in "!CA_LOCATION!\crl\ca!CA_FILENAME!.crl.pem" -noout -text > "!CA_LOCATION!\val\ca!CA_FILENAME!.crl.pem.val.txt"
          )

        COPY "%~dp0..\conf\util\openssl\ca!CA_FILENAME!.conf" "!CA_LOCATION!\openssl.conf">NUL 2>&1
    ECHO ----------------
  ENDLOCAL
GOTO :EOF

:PROCESS_CA_SSL
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _CA_LOCATION=%~1
    SET _CA_LEVEL=%~2
    SET _CA_APPLICATION_TYPE=%~3
    SET _CA_APPLICATION=%~4

    ECHO ca 
      ECHO - !_CA_LEVEL!
      ECHO - !_CA_APPLICATION_TYPE!
      ECHO - !_CA_APPLICATION!

        SET CA_LOCATION=!_CA_LOCATION!
        SET CA_PARENT_LOCATION=!_CA_LOCATION!
        SET CA_FILENAME=
        
        IF "!_CA_LEVEL!" NEQ "" (
          IF "!_CA_APPLICATION_TYPE!" NEQ "" (
            IF "!_CA_APPLICATION!" NEQ "" (
              SET CA_LOCATION=!_CA_LOCATION!\..\!_CA_APPLICATION_TYPE!\!_CA_APPLICATION!\_xenv\ssl
              SET CA_PARENT_LOCATION=!_CA_LOCATION!\!_CA_LEVEL!
              SET CA_FILENAME=.!_CA_APPLICATION_TYPE!.!_CA_APPLICATION!
            ) ELSE (
              SET CA_LOCATION=!_CA_LOCATION!\..\!_CA_APPLICATION_TYPE!\_xenv\ssl
              SET CA_PARENT_LOCATION=!_CA_LOCATION!\!_CA_LEVEL!
              SET CA_FILENAME=.!_CA_APPLICATION!
            )
          ) ELSE (
            SET CA_LOCATION=!_CA_LOCATION!\!_CA_LEVEL!
            SET CA_PARENT_LOCATION=!_CA_LOCATION!
            SET CA_FILENAME=.!_CA_LEVEL!
          )
        )

        REM SET OPENSSL_CONF="!_CA_LOCATION!\openssl.conf"

        ECHO   - cert db
          IF NOT EXIST "!CA_LOCATION!\index.txt" (
            touch "!CA_LOCATION!\index.txt"
            ECHO     - db created
          ) ELSE (
            ECHO     - db exists
          )
        
        ECHO   - serial db
          IF NOT EXIST "!CA_LOCATION!\serial" (
            ECHO 1000 > "!CA_LOCATION!\serial"
            ECHO     - db created
          ) ELSE (
            ECHO     - db exists
          )
        ECHO   - key
          IF NOT EXIST "!CA_LOCATION!\pvt\ca!CA_FILENAME!.key.pem" (
            openssl genrsa -out "!CA_LOCATION!\pvt\ca!CA_FILENAME!.key.pem" 4096>NUL 2>&1
            REM  -aes256 REM DOES NOT WORK ON WINDOWS
          ) ELSE (
            ECHO     - ca.key exists
          )
          
        ECHO   - csr
          IF "!CA_LOCATION!" NEQ "!CA_PARENT_LOCATION!" (
            IF NOT EXIST "!CA_LOCATION!\csr\ca!CA_FILENAME!.csr.pem" (
              SET IP=192.168.111.129
              SET FQDN=xenv.dev
              SET SAN=IP:!IP!, DNS:!FQDN!, DNS:dev.!FQDN!, DNS:tst.!FQDN!, DNS:stg.!FQDN!, DNS:www.!FQDN!, DNS:mx.!FQDN!, DNS:mail.!FQDN!, DNS:support.!FQDN!
              openssl req -config "!CA_LOCATION!\openssl.conf" -new -sha256 -key "!CA_LOCATION!\pvt\ca!CA_FILENAME!.key.pem" -out "!CA_LOCATION!\csr\ca!CA_FILENAME!.csr.pem"
            ) ELSE (
              ECHO     - csr for !_CA_APPLICATION_TYPE!:!_CA_APPLICATION! exists
            )
          )
        
        ECHO   - crt
          IF NOT EXIST "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem" (
            IF "!CA_LOCATION!" == "!CA_PARENT_LOCATION!" (
              openssl req -config "!CA_LOCATION!\openssl.conf" -key "!CA_LOCATION!\pvt\ca!CA_FILENAME!.key.pem" -new -x509 -days 7300 -sha256 -extensions v3_ca -out "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem"
              certutil -f -addstore "Root" "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem"
            ) ELSE (
              openssl ca -config "!CA_PARENT_LOCATION!\openssl.conf" -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in "!CA_LOCATION!\csr\ca!CA_FILENAME!.csr.pem" -out "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem"
              certutil -f -addstore "CA" "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem"
            )
            
          ) ELSE (
            ECHO     - crt for !_CA_APPLICATION_TYPE!:!_CA_APPLICATION! exists
          )

        ECHO   - chain
          IF NOT EXIST "!CA_LOCATION!\crt\ca.chain.crt.pem" (
            IF "!CA_LOCATION!" == "!CA_PARENT_LOCATION!" (
              ECHO     - creating ca chain validation cert from !CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem
              COPY /Y "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem" "!CA_LOCATION!\crt\ca.chain.crt.pem"
            ) ELSE (
              ECHO     - creating ca chain validation cert 
              ECHO       using !CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem and
              ECHO       !CA_PARENT_LOCATION!\crt\ca.chain.crt.pem
              "%XENVU%\gnu\on\bin\cat" "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem" "!CA_PARENT_LOCATION!\crt\ca.chain.crt.pem" > "!CA_LOCATION!\crt\ca.chain.crt.pem"
              REM >NUL 2>&1
              IF ERRORLEVEL 1 (
                ECHO     error creating ca chain
              )
            )
            ECHO       - ca chain cert created at !CA_LOCATION!\crt\ca.chain.crt.pem
          )

        ECHO   - validate
          ECHO     - csr
          IF NOT EXIST "!CA_LOCATION!\val\ca!CA_FILENAME!.csr.val.txt" (
            REM openssl req -in "!CA_LOCATION!\csr\ca!CA_FILENAME!.csr.pem" -noout -text > "!CA_LOCATION!\val\ca!CA_FILENAME!.csr.pem.val.txt"
          )

          ECHO     - crt
          IF NOT EXIST "!CA_LOCATION!\val\ca!CA_FILENAME!.crt.val.txt" (
            openssl x509 -noout -text -in "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem" > "!CA_LOCATION!\val\ca!CA_FILENAME!.crt.pem.val.txt"
          )

          ECHO     - crt.chain
          IF NOT EXIST "!CA_LOCATION!\val\ca!CA_FILENAME!.crt.validated.chain.txt" (
            IF "!CA_LOCATION!" NEQ "!CA_PARENT_LOCATION!" (
              openssl verify -CAfile "!CA_LOCATION!\crt\ca.chain.crt.pem" "!CA_LOCATION!\crt\ca!CA_FILENAME!.crt.pem" > "!CA_LOCATION!\val\ca!CA_FILENAME!.crt.validated.chain.txt"
            )
          )
    ECHO ----------------
  ENDLOCAL
GOTO :EOF

:PROCESS_CA_DIR
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET _CA_LOCATION=%~1
    SET _CA_STAGE=%~2
    
    SET CLEAN=!_CA_LOCATION!
    SET CLEANSTAGE=!CLEAN!
    
    IF DEFINED _CA_STAGE (
      SET CLEANSTAGE=%CLEAN%!_CA_STAGE:\=!
    )
    
    IF "!_CA_STAGE!" NEQ "" (
      SET _CA_STAGE=\!_CA_STAGE!
    )
    
    ECHO     - checking root
    IF NOT EXIST "!_CA_LOCATION!" (
      MKDIR "!_CA_LOCATION!">NUL 2>&1
      ECHO      - !_CA_LOCATION! created
    ) ELSE (
      ECHO      - !_CA_LOCATION! exists
    )
    
    IF "!CLEANSTAGE!" NEQ "!CLEAN!" (
      ECHO      - checking stage
      IF NOT EXIST "!_CA_LOCATION!!_CA_STAGE!" (
        MKDIR "!_CA_LOCATION!!_CA_STAGE!">NUL 2>&1
        ECHO       - !_CA_LOCATION!!_CA_STAGE! created
      ) ELSE (
        ECHO       - !_CA_LOCATION!!_CA_STAGE! exists
      )
    )
  ENDLOCAL
GOTO :EOF

:PROCESS_SSL_SITE
  SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
    SET FQDN=%~1 

    CALL :NETWORK
    ECHO !MACHINE_IP!
    SET IP=!MACHINE_IP!

    SET CA_SSL=%XENV:\=/%/_ca
    SET IM_SSL=%CA_SSL:\=/%/intermediate
    SET AP_SSL=%XENVS:\=/%/apache/_xenv/ssl
    
    SET SAN=IP:%IP%, DNS:%FQDN%, DNS:dev.%FQDN%, DNS:tst.%FQDN%, DNS:stg.%FQDN%, DNS:www.%FQDN%, DNS:mx.%FQDN%, DNS:mail.%FQDN%, DNS:support.%FQDN%

    IF NOT EXIST "%AP_SSL%/csr/%FQDN%.csr.pem" (
      ECHO   - csr
      openssl req -config "%AP_SSL%/openssl.conf" -key "%AP_SSL%/pvt/ca.server.apache.key.pem" -new -sha256      -out "%AP_SSL%/csr/%FQDN%.csr.pem"
    )

    IF NOT EXIST "%AP_SSL%/crt/%FQDN%.crt.pem" (
      ECHO   - crt
      openssl ca  -config "%IM_SSL%/openssl.conf" -days 365 -notext -md sha256 -in "%AP_SSL%/csr/%FQDN%.csr.pem" -out "%AP_SSL%/crt/%FQDN%.crt.pem"
    )
    REM openssl ca  -config "%IM_SSL%/openssl.conf" -revoke "%AP_SSL%/crt/%FQDN%.crt.pem"
    ECHO   - validate
    IF NOT EXIST "%AP_SSL%/val/%FQDN%.csr.pem.validated.txt" (
      ECHO     - csr
      openssl req -in     "%AP_SSL%/csr/%FQDN%.csr.pem" -noout -text > "%AP_SSL%/val/%FQDN%.csr.pem.validated.txt"
    )
    IF NOT EXIST "%AP_SSL%/val/%FQDN%.crt.pem.validated.txt" (
      ECHO     - crt
      openssl x509 -noout -text -in "%AP_SSL%/crt/%FQDN%.crt.pem" > "%AP_SSL%/val/%FQDN%.crt.pem.validated.txt"
    )
    IF NOT EXIST "%AP_SSL%/val/%FQDN%.crt.pem.validated.chain.txt" (
      ECHO     - crt.chain
      openssl verify -CAfile "%IM_SSL%/crt/ca.chain.crt.pem" "%AP_SSL%/crt/%FQDN%.crt.pem" > "%AP_SSL%/val/%FQDN%.crt.pem.validated.chain.txt"
    )
  ENDLOCAL
GOTO :EOF

REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.example.com.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.dcubed.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.d-cubed.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.grav.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.craft.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.keystone.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.beautypointmaarssen.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.beautypoint-maarssen.dev.key.pem" 2048
REM openssl genrsa -aes256 -out "%CAROOT%\intermediate\pvt\www.domipal.dev.key.pem" 2048