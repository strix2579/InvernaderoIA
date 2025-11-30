import pandas as pd
import tensorflow as tf
import joblib
import numpy as np
import os

# Configurar paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "../modelos/modelo_invernadero.keras")
SCALER_PATH = os.path.join(BASE_DIR, "scaler.pkl")
DATA_DIR = os.path.join(BASE_DIR, "../datos/datos_eventos_separados")

print("📂 Cargando modelo y scaler...")
model = tf.keras.models.load_model(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)

clases = ['NORMAL', 'INCENDIO', 'FUGA_H2', 'FALLA_ELECTRICA', 'PLAGA']
FEATURES = ["temp", "hum", "soil1", "soil2", "mq2", "mq5", "mq8", "aqi"]

print("\n🔍 Extrayendo ejemplos reales de los datos de entrenamiento...\n")

# Leer 5 filas de cada archivo (ejemplos reales)
archivos = {
    "NORMAL": "normal.csv",
    "INCENDIO": "incendio.csv",
    "FUGA_H2": "fuga_h2.csv",
    "FALLA_ELECTRICA": "falla_electrica.csv",
    "PLAGA": "plaga.csv"
}

for evento, archivo in archivos.items():
    print(f"--- Probando con datos reales de: {evento} ---")
    ruta = os.path.join(DATA_DIR, archivo)
    
    # Leer solo 3 filas (saltando el header)
    df = pd.read_csv(ruta, nrows=3)
    
    for idx, row in df.iterrows():
        X = row[FEATURES].values.reshape(1, -1)
        X_scaled = scaler.transform(X)
        
        pred_proba = model.predict(X_scaled, verbose=0)[0]
        pred_dict = {clase: float(prob) for clase, prob in zip(clases, pred_proba)}
        clase_predicha = max(pred_dict, key=pred_dict.get)
        
        print(f"  Fila {idx+1}: {list(X[0][:4])}... -> Predicción: {clase_predicha} ({pred_dict[clase_predicha]:.4f})")
        
        if clase_predicha == evento:
            print(f"    ✅ Correcto")
        else:
            print(f"    ⚠️ Incorrecto (Esperaba {evento})")
            print(f"    Distribución: {pred_dict}")
    
    print()

print("\n✅ Prueba completada.")
