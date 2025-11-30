# InvernaderoIA/api/model_loader.py
import os, joblib, json
import numpy as np
import tensorflow as tf

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
MODEL_PATH = os.path.join(BASE_DIR, 'modelos', 'modelo_invernadero.keras')
SCALER_PATH = os.path.join(BASE_DIR, 'modelos', 'scaler.pkl')
LE_PATH = os.path.join(BASE_DIR, 'modelos', 'label_encoder.pkl')

FEATURES = ["TEMP","HUM","SOIL1","SOIL2","MQ2","MQ5","MQ8","AQI"]

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(MODEL_PATH + " no existe.")
if not os.path.exists(SCALER_PATH):
    raise FileNotFoundError(SCALER_PATH + " no existe.")
if not os.path.exists(LE_PATH):
    raise FileNotFoundError(LE_PATH + " no existe.")

print("🔄 Cargando modelo, scaler y label encoder...")
model = tf.keras.models.load_model(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
le = joblib.load(LE_PATH)
print("✅ Cargado.")

def predecir(datos: dict):
    # Aceptar claves en mayúscula o minúscula
    row = []
    for f in FEATURES:
        if f in datos:
            row.append(float(datos[f]))
        elif f.lower() in datos:
            row.append(float(datos[f.lower()]))
        else:
            raise KeyError(f"Falta feature '{f}' en datos de entrada.")
    X = np.array([row])
    Xs = scaler.transform(X)
    proba = model.predict(Xs, verbose=0)[0]
    clases = list(le.classes_)
    return {clase: float(prob) for clase, prob in zip(clases, proba)}