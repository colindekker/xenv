@ECHO OFF

ECHO SET:XENV (Prep)
	::ECHO %~dp0..\..\
	SET _XENV_SCRIPT=%~p0
	SET _XENV_DRIVE=%~d0
	SET _XENV_TEMP=%~d0\XENV.TMP

	CD /D %~dp0..\..\..\
	SET _XENV=%CD%
	SET _SL=\on
  SET _XD=_xenv
  SET _CONF=conf
  SET _SCRIPT=scripts
	CD /D %_XENV_SCRIPT%

	ECHO - Using folders
		ECHO - - Root: %_XENV%
		ECHO - - Drive: %_XENV_DRIVE%
		ECHO - - Install: %_XENV_SCRIPT%
		ECHO - - Temp: %_XENV_TEMP%
