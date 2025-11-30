import tensorflow as tf
import joblib
import numpy as np
import os

# Configurar paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "../modelos/modelo_invernadero.keras")
SCALER_PATH = os.path.join(BASE_DIR, "scaler.pkl")

print(f"📂 Cargando modelo desde: {MODEL_PATH}")
model = tf.keras.models.load_model(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)

clases = ['NORMAL', 'INCENDIO', 'FUGA_H2', 'FALLA_ELECTRICA', 'PLAGA']

# Casos de prueba (aproximados)
test_cases = [
    {
        "name": "Caso Normal",
        "data": [25.0, 55.0, 70.0, 70.0, 100.0, 100.0, 100.0, 50.0], # Valores moderados
        "expected": "NORMAL"
    },
    {
        "name": "Caso Incendio",
        "data": [65.0, 20.0, 10.0, 10.0, 800.0, 800.0, 200.0, 400.0], # Alta temp, humo
        "expected": "INCENDIO"
    },
    {
        "name": "Caso Fuga H2",
        "data": [25.0, 50.0, 60.0, 60.0, 150.0, 150.0, 900.0, 200.0], # MQ8 alto (Hidrógeno)
        "expected": "FUGA_H2"
    }
]

print("\n🧪 Iniciando pruebas automáticas...\n")

for case in test_cases:
    print(f"--- Probando: {case['name']} ---")
    X = np.array([case['data']])
    X_scaled = scaler.transform(X)
    
    pred_proba = model.predict(X_scaled, verbose=0)[0]
    pred_dict = {clase: float(prob) for clase, prob in zip(clases, pred_proba)}
    clase_predicha = max(pred_dict, key=pred_dict.get)
    
    print(f"Entrada: {case['data']}")
    print(f"Predicción: {clase_predicha} ({pred_dict[clase_predicha]:.4f})")
    print("Distribución:")
    for c, p in pred_dict.items():
        print(f"  {c}: {p:.4f}")
    
    if clase_predicha == case['expected']:
        print("✅ Resultado esperado")
    else:
        print(f"⚠️ Resultado inesperado (Esperaba {case['expected']})")
    print("\n")
