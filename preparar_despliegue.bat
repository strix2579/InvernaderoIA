@echo off
echo ===================================================
echo 🚀 PREPARANDO DESPLIEGUE A RAILWAY Y GITHUB
echo ===================================================

echo.
echo 1. Inicializando repositorio Git...
git init
git add .
git commit -m "Preparacion para despliegue en Railway con PostgreSQL"

echo.
echo 2. Construyendo App Flutter Web...
cd app_invernadero
call flutter build web --release --base-href "/InvernaderoIA/"
cd ..

echo.
echo ===================================================
echo ✅ PREPARACION COMPLETADA
echo ===================================================
echo.
echo SIGUIENTES PASOS (Manuales):
echo 1. Crea un repositorio en GitHub.com
echo 2. Sube este codigo:
echo    git remote add origin <URL_DE_TU_REPO>
echo    git push -u origin master
echo.
echo 3. En Railway.app:
echo    - Crea nuevo proyecto desde GitHub
echo    - Selecciona este repo
echo    - Agrega servicio PostgreSQL
echo.
echo 4. En GitHub Pages:
echo    - Sube el contenido de 'app_invernadero/build/web' a la rama gh-pages
echo.
pause
