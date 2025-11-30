import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, callbacks
from sklearn.preprocessing import OneHotEncoder
import joblib
import os

# Configuración mejorada
DATASETS_DIR = "../datos/datos_eventos_separados"
DATASETS = ["normal.csv", "incendio.csv", "fuga_h2.csv", "falla_electrica.csv", "plaga.csv"]
SCALER_PATH = "scaler.pkl"
OUTPUT_MODEL = "../modelos/modelo_invernadero.keras"
BATCH_SIZE = 1024
EPOCHS = 20 # Aumentado de 10
FEATURES = ["temp", "hum", "soil1", "soil2", "mq2", "mq5", "mq8", "aqi"]
TARGET = "evento"

print("🔧 Cargando scaler global...")
if not os.path.exists(SCALER_PATH):
    raise FileNotFoundError("No se encontró scaler.pkl. Asegúrate de que exista.")
scaler = joblib.load(SCALER_PATH)

print("🔧 Inicializando OneHotEncoder...")
ohe = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
ohe.fit(np.array(["NORMAL", "INCENDIO", "FUGA_H2", "FALLA_ELECTRICA", "PLAGA"]).reshape(-1, 1))

print("🧠 Creando modelo OPTIMIZADO...")
# Arquitectura más profunda y ancha
model = models.Sequential([
    layers.Input(shape=(8,)),
    layers.Dense(256, activation='relu'), # Aumentado de 128
    layers.Dropout(0.3), # Aumentado dropout para evitar overfitting con más neuronas
    layers.Dense(128, activation='relu'), # Aumentado de 64
    layers.Dropout(0.3),
    layers.Dense(64, activation='relu'),
    layers.Dense(5, activation='softmax')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001), # Learning rate más bajo para ajuste fino
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()

def interleaved_generator(files, batch_size):
    num_files = len(files)
    samples_per_file = batch_size // num_files
    iterators = [pd.read_csv(f, chunksize=samples_per_file) for f in files]
    
    while True:
        chunks = []
        for i in range(num_files):
            try:
                chunk = next(iterators[i])
            except StopIteration:
                iterators[i] = pd.read_csv(files[i], chunksize=samples_per_file)
                chunk = next(iterators[i])
            chunks.append(chunk)
            
        full_batch = pd.concat(chunks, ignore_index=True)
        full_batch = full_batch.sample(frac=1).reset_index(drop=True)
        
        X_batch = full_batch[FEATURES].values
        y_batch = full_batch[TARGET].values.reshape(-1, 1)
        
        X_scaled = scaler.transform(X_batch)
        y_encoded = ohe.transform(y_batch)
        
        yield X_scaled, y_encoded

if __name__ == "__main__":
    print("\n🚀 Iniciando entrenamiento optimizado...")
    dataset_paths = [os.path.join(DATASETS_DIR, fname) for fname in DATASETS]
    
    # Estimación de pasos
    total_rows = 5 * 10_000_000 # Asumiendo un tamaño considerable, ajustar según real
    steps_per_epoch = total_rows // BATCH_SIZE

    train_generator = interleaved_generator(dataset_paths, BATCH_SIZE)

    early_stopping = callbacks.EarlyStopping(monitor='accuracy', patience=5, restore_best_weights=True)

    model.fit(train_generator,
              epochs=EPOCHS,
              steps_per_epoch=steps_per_epoch,
              callbacks=[early_stopping])

    print("\n💾 Guardando modelo optimizado...")
    model.save(OUTPUT_MODEL)
    print(f"\n✅ Modelo optimizado guardado en: {OUTPUT_MODEL}")
