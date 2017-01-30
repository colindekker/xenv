@ECHO OFF

SETLOCAL
  START /WAIT CMD /C %~dp0xenv.env.cmd & START /WAIT CMD /C %~dp0util\env.refresh.cmd
  REM START /WAIT CMD /C %~dp0xenv.user.cmd & START /WAIT CMD /C %~dp0util\env.refresh.cmd
  START /WAIT CMD /C %~dp0xenv.install.cmd
ENDLOCAL

EXIT /B %ERRORLEVEL%