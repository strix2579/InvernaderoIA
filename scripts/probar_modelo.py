import tensorflow as tf
import joblib
import numpy as np

# ---- Cargar modelo y scaler ----
MODEL_PATH = "../modelos/modelo_invernadero.keras"
SCALER_PATH = "../scripts/scaler.pkl"

print("📦 Cargando modelo y scaler...\n")
model = tf.keras.models.load_model(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)

# Nombre de clases en el orden correcto
clases = ['NORMAL', 'INCENDIO', 'FUGA_H2', 'FALLA_ELECTRICA', 'PLAGA']

# Función para colorear texto en consola
def color(txt, c):
    colores = {
        "green": "\033[92m",
        "red": "\033[91m",
        "yellow": "\033[93m",
        "cyan": "\033[96m",
        "blue": "\033[94m",
        "reset": "\033[0m",
    }
    return colores.get(c, "") + txt + colores["reset"]

print(color("=== Prueba interactiva de la IA del invernadero ===", "cyan"))
print("Ingresa los valores de los sensores cuando te los pida.\n")

def predecir(datos):
    """Recibe un array de 8 valores, escala y predice."""
    datos = np.array([datos])
    datos_scaled = scaler.transform(datos)
    pred_proba = model.predict(datos_scaled, verbose=0)[0]
    pred_dict = {clase: float(prob) for clase, prob in zip(clases, pred_proba)}
    clase_mas_probable = max(pred_dict, key=pred_dict.get)
    return pred_dict, clase_mas_probable

while True:
    try:
        # ---- Entrada de datos ----
        TEMP = float(input("Temperatura (°C): "))
        HUM = float(input("Humedad relativa (%): "))
        SOIL1 = float(input("Humedad suelo planta 1 (%): "))
        SOIL2 = float(input("Humedad suelo planta 2 (%): "))
        MQ2 = float(input("Lectura MQ-2 (0-1023): "))
        MQ5 = float(input("Lectura MQ-5 (0-1023): "))
        MQ8 = float(input("Lectura MQ-8 (0-1023): "))
        AQI = float(input("AQI (0-500): "))

        datos = [TEMP, HUM, SOIL1, SOIL2, MQ2, MQ5, MQ8, AQI]
        pred_dict, clase_mas_probable = predecir(datos)

        # ---- Mostrar resultados ----
        print("\n" + color("📊 Predicción de la IA:", "yellow"))
        for c, p in pred_dict.items():
            col = "blue"
            print(color(f"{c}: {p:.4f}", col))
        print(color(f"\n➡ Clase más probable: {clase_mas_probable}\n", "green"))

        # ---- Continuar o terminar ----
        seguir = input("¿Deseas ingresar otro conjunto de valores? (s/n): ").strip().lower()
        if seguir != 's':
            print(color("\n👋 Finalizando prueba. ¡Hasta luego!", "cyan"))
            break

    except ValueError:
        print(color("⚠️ Entrada inválida, por favor ingresa números válidos.\n", "red"))