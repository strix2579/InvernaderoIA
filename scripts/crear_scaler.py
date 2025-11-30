import pandas as pd
from sklearn.preprocessing import StandardScaler
import joblib
from tqdm import tqdm
import os

BASE_PATH = "../datos/datos_eventos_separados"

datasets = [
    "normal.csv",
    "incendio.csv",
    "fuga_h2.csv",
    "falla_electrica.csv",
    "plaga.csv"
]

COLUMNAS_NUM = [
    "temp", "hum", "soil1", "soil2",
    "mq2", "mq5", "mq8", "aqi"
]

COLUMNAS = COLUMNAS_NUM + ["evento"]

scaler = StandardScaler()

CHUNK = 500_000

print("\n🔧 Generando scaler global...\n")

for archivo in datasets:
    ruta = os.path.join(BASE_PATH, archivo)

    with open(ruta, "r") as f:
        total_filas = sum(1 for _ in f) - 1

    total_chunks = total_filas // CHUNK + 1

    print(f"\n📌 Procesando: {archivo}   ({total_filas:,} filas)\n")

    for chunk in tqdm(
        pd.read_csv(ruta, chunksize=CHUNK, usecols=COLUMNAS),
        total=total_chunks,
        desc=f"Fit {archivo}",
        ncols=100
    ):
        scaler.partial_fit(chunk[COLUMNAS_NUM])

print("\n💾 Guardando scaler global en 'scaler.pkl' ...")
joblib.dump(scaler, "scaler.pkl")
print("✅ Scaler generado exitosamente.\n")