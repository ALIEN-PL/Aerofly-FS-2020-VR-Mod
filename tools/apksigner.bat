@echo off
setlocal
set "TOOL_DIR=%~dp0"
set "JAR=%TOOL_DIR%apksigner.jar"

rem 1. Check JAVA_HOME
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
        goto run
    )
)

rem 2. Check java in PATH
where java >nul 2>nul
if %ERRORLEVEL% equ 0 (
    set "JAVA_EXE=java"
    goto run
)

rem 3. Check common Java paths
for %%P in (
    "C:\Program Files (x86)\Common Files\Oracle\Java\javapath\java.exe"
    "C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
    "C:\Program Files\Android\Android Studio\jre\bin\java.exe"
    "C:\Program Files\Java\jdk*\bin\java.exe"
    "C:\Program Files\Java\jre*\bin\java.exe"
) do (
    if exist %%P (
        set "JAVA_EXE=%%~P"
        goto run
    )
)

echo ERROR: Java (java.exe) was not found on your system.
echo Please install Java or Android Studio to enable APK signing.
exit /b 1

:run
"%JAVA_EXE%" -jar "%JAR%" %*
exit /b %ERRORLEVEL%

