import pandas as pd
import numpy as np
import tensorflow as tf
import joblib
import os
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import OneHotEncoder

# Configuración
DATASETS_DIR = "../datos/datos_eventos_separados"
MODEL_PATH = "../modelos/modelo_invernadero.keras"
SCALER_PATH = "scaler.pkl"
DATASETS = [
    "normal.csv",
    "incendio.csv",
    "fuga_h2.csv",
    "falla_electrica.csv",
    "plaga.csv"
]
FEATURES = ["temp", "hum", "soil1", "soil2", "mq2", "mq5", "mq8", "aqi"]
TARGET = "evento"
SAMPLE_SIZE_PER_FILE = 10000 # Evaluar con 10k muestras por clase para ser rápido pero representativo

def verificar():
    print("🔍 Iniciando verificación del modelo...")
    
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Error: No se encontró el modelo en {MODEL_PATH}")
        return False

    if not os.path.exists(SCALER_PATH):
        print(f"❌ Error: No se encontró el scaler en {SCALER_PATH}")
        return False

    # Cargar recursos
    print("🔧 Cargando modelo y scaler...")
    try:
        model = tf.keras.models.load_model(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)
    except Exception as e:
        print(f"❌ Error cargando recursos: {e}")
        return False

    # Preparar OHE (debe coincidir con el entrenamiento)
    ohe = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
    ohe.fit(np.array(["NORMAL", "INCENDIO", "FUGA_H2", "FALLA_ELECTRICA", "PLAGA"]).reshape(-1, 1))

    # Cargar datos de prueba
    print("📊 Cargando datos de prueba...")
    dfs = []
    for file in DATASETS:
        path = os.path.join(DATASETS_DIR, file)
        if os.path.exists(path):
            try:
                # Cargar una muestra aleatoria si el archivo es muy grande
                df = pd.read_csv(path)
                if len(df) > SAMPLE_SIZE_PER_FILE:
                    df = df.sample(n=SAMPLE_SIZE_PER_FILE, random_state=42)
                dfs.append(df)
            except Exception as e:
                print(f"⚠️ Advertencia: No se pudo leer {file}: {e}")
        else:
            print(f"⚠️ Advertencia: Archivo no encontrado {path}")

    if not dfs:
        print("❌ Error: No se cargaron datos para probar.")
        return False

    full_df = pd.concat(dfs, ignore_index=True)
    
    X = full_df[FEATURES].values
    y_true_str = full_df[TARGET].values

    # Preprocesar
    X_scaled = scaler.transform(X)
    
    # Predecir
    print("🧠 Realizando predicciones...")
    y_pred_proba = model.predict(X_scaled, verbose=0)
    
    # Decodificar predicciones
    # OHE classes_ están en orden alfabético o de aparición? 
    # En entrenar_ia.py se hizo fit con una lista fija.
    # Recuperamos las etiquetas desde el OHE
    clases = ohe.categories_[0]
    y_pred_indices = np.argmax(y_pred_proba, axis=1)
    y_pred_str = clases[y_pred_indices]

    # Calcular métricas
    acc = accuracy_score(y_true_str, y_pred_str)
    print(f"\n🏆 Precisión Global: {acc:.4f}")
    print("\n📄 Reporte de Clasificación:")
    print(classification_report(y_true_str, y_pred_str))

    if acc > 0.80:
        print("✅ El modelo cumple con el criterio de éxito (>80%).")
        return True
    else:
        print("❌ El modelo NO cumple con el criterio de éxito (<80%).")
        return False

if __name__ == "__main__":
    exito = verificar()
    exit(0 if exito else 1)
