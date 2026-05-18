@echo off
REM BoardVault API Testing Script (Windows)
REM Make sure backend is running on http://localhost:3030

setlocal enabledelayedexpansion

set BASE_URL=http://localhost:3030
set API_URL=%BASE_URL%/api/v1
set PASSWORD=nishu3126

echo.
echo ========================================
echo BoardVault API Testing Script
echo ========================================
echo.
echo Base URL: %BASE_URL%
echo API URL: %API_URL%
echo.

REM Test 1: Ping
echo 1. Testing Ping Endpoint...
curl -X GET %API_URL%/ping
echo.
echo.

REM Test 2: Get All Boards
echo 2. Getting All Boards...
curl -X GET %API_URL%/findOne
echo.
echo.

REM Test 3: Create Raspberry Pi Board (if images exist)
echo 3. Creating Raspberry Pi 4 Board...
set PHOTO=..\..\boards\raspberry pi4 modelb.jpg
set DIAGRAM=..\..\boards\raspberry pi4 modelb pin.jpg

if exist "%PHOTO%" (
  if exist "%DIAGRAM%" (
    curl -X POST %API_URL%/create ^
      -F "name=Raspberry Pi 4 Model B" ^
      -F "type=SBC" ^
      -F "description=Powerful SBC with quad-core ARM processor, perfect for media centers and IoT" ^
      -F "password=%PASSWORD%" ^
      -F "photoFront=@%PHOTO%" ^
      -F "pinDiagram=@%DIAGRAM%"
  ) else (
    echo Diagram not found: %DIAGRAM%
  )
) else (
  echo Photo not found: %PHOTO%
)
echo.
echo.

REM Test 4: Create Arduino Board
echo 4. Creating Arduino Uno Board...
set PHOTO=..\..\boards\ATmega328p.jpg
set DIAGRAM=..\..\boards\ATmega328p pin.jpg

if exist "%PHOTO%" (
  if exist "%DIAGRAM%" (
    curl -X POST %API_URL%/create ^
      -F "name=Arduino Uno" ^
      -F "type=MC" ^
      -F "description=Classic microcontroller board, ideal for learners and embedded projects" ^
      -F "password=%PASSWORD%" ^
      -F "photoFront=@%PHOTO%" ^
      -F "pinDiagram=@%DIAGRAM%"
  ) else (
    echo Diagram not found: %DIAGRAM%
  )
) else (
  echo Photo not found: %PHOTO%
)
echo.
echo.

REM Test 5: Get All Boards Again
echo 5. Getting All Boards Again...
curl -X GET %API_URL%/findOne
echo.
echo.

REM Test 6: Find Board by Name
echo 6. Finding Board by Name (Raspberry Pi 4 Model B)...
curl -X GET "%API_URL%/find/Raspberry%%20Pi%%204%%20Model%%20B"
echo.
echo.

echo ========================================
echo Testing Complete!
echo ========================================
echo.

pause
