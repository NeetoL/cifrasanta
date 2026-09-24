@echo off
chcp 65001 > nul
echo ====================================================
echo      Gerando APK do Cifra Santa (Debug)
echo ====================================================

:: Configura o JDK 21 compativel com o Gradle
set "JAVA_HOME=C:\Users\Neto_\.jdks\jbr-21.0.11"
set "PATH=%JAVA_HOME%\bin;%PATH%"

:: Limpa variavel conflitante do Android Studio
set ANDROID_PREFS_ROOT=

:: Executa o build do APK via Flutter
echo.
echo Compilando o APK...
call "C:\Users\Neto_\source\repos\cifrasanta\.work\flutter\bin\flutter.bat" build apk --debug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ====================================================
    echo [SUCESSO] APK gerado com sucesso!
    echo Local do arquivo:
    echo %~dp0build\app\outputs\flutter-apk\app-debug.apk
    echo ====================================================
) else (
    echo.
    echo ====================================================
    echo [ERRO] Ocorreu uma falha ao gerar o APK.
    echo ====================================================
)

pause
