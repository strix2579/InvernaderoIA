import subprocess
import time
import os
import sys

# Configuración
VERIFICAR_SCRIPT = "verificar_modelo.py"
RETRAIN_SCRIPT = "entrenar_optimizado.py"
API_CMD = ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
MODEL_FILE = "../modelos/modelo_invernadero.keras"

def is_training_running():
    """Verifica si entrenar_ia.py está corriendo usando wmic en Windows."""
    try:
        # wmic process where "name='python.exe'" get commandline
        output = subprocess.check_output('wmic process where "name=\'python.exe\'" get commandline', shell=True).decode()
        return "entrenar_ia.py" in output
    except Exception as e:
        print(f"⚠️ No se pudo verificar procesos: {e}")
        return False

def run_script(script_name):
    """Ejecuta un script de python y devuelve el código de salida."""
    print(f"▶ Ejecutando {script_name}...")
    result = subprocess.run(["python", script_name], capture_output=False)
    return result.returncode

def start_api():
    """Inicia la API."""
    print("\n🚀 Iniciando API...")
    # Asumimos que estamos en la carpeta scripts, la API está en ../api
    # Necesitamos ejecutar uvicorn desde el directorio raíz del proyecto para que los imports funcionen
    project_root = os.path.abspath(os.path.join(os.getcwd(), ".."))
    
    print(f"📂 Directorio base: {project_root}")
    try:
        subprocess.run(API_CMD, cwd=project_root, check=True)
    except KeyboardInterrupt:
        print("\n🛑 API detenida por el usuario.")

def main():
    print("🤖 Iniciando Pipeline de Despliegue InvernaderoIA")
    
    # 1. Esperar a que termine el entrenamiento actual
    if is_training_running():
        print("⏳ Detectado entrenamiento en curso (entrenar_ia.py). Esperando a que termine...")
        while is_training_running():
            time.sleep(60) # Revisar cada minuto
            print(".", end="", flush=True)
        print("\n✅ Entrenamiento finalizado.")
    else:
        print("ℹ️ No se detectó entrenamiento en curso. Procediendo a verificación.")

    # 2. Verificar modelo
    print("\n🔍 Verificando modelo...")
    exit_code = run_script(VERIFICAR_SCRIPT)

    if exit_code == 0:
        print("\n✅ Verificación EXITOSA. El modelo está listo.")
        start_api()
    else:
        print("\n❌ Verificación FALLIDA. La precisión es insuficiente.")
        print("⚙️ Iniciando protocolo de optimización (FACTORIZACIÓN)...")
        
        # 3. Reentrenar si falla
        retrain_code = run_script(RETRAIN_SCRIPT)
        
        if retrain_code == 0:
            print("\n✅ Reentrenamiento completado. Verificando nuevamente...")
            exit_code_retry = run_script(VERIFICAR_SCRIPT)
            
            if exit_code_retry == 0:
                print("\n✅ Segunda verificación EXITOSA. Modelo optimizado listo.")
                start_api()
            else:
                print("\n❌ La verificación falló nuevamente incluso después de optimizar.")
                print("⚠️ Se requiere intervención manual.")
                sys.exit(1)
        else:
            print("\n❌ Error durante el reentrenamiento.")
            sys.exit(1)

if __name__ == "__main__":
    main()
