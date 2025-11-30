import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, callbacks
from sklearn.preprocessing import OneHotEncoder
import joblib
from tqdm import tqdm
import os
import random


DATASETS_DIR = "../datos/datos_eventos_separados"

DATASETS = [
    "normal.csv",
    "incendio.csv",
    "fuga_h2.csv",
    "falla_electrica.csv",
    "plaga.csv"
]

SCALER_PATH = "scaler.pkl"
CHUNK = 500_000
FEATURES = ["temp", "hum", "soil1", "soil2", "mq2", "mq5", "mq8", "aqi"]
TARGET = "evento"

print("🔧 Cargando scaler global...")
scaler = joblib.load(SCALER_PATH)


print("🔧 Inicializando OneHotEncoder...")

ohe = OneHotEncoder(sparse_output=False, handle_unknown="ignore")

ohe.fit(np.array(["NORMAL", "INCENDIO", "FUGA_H2", "FALLA_ELECTRICA", "PLAGA"]).reshape(-1, 1))


print("🧠 Creando modelo...")

model = models.Sequential([
    layers.Input(shape=(8,)),
    layers.Dense(512, activation='relu'),
    layers.Dropout(0.3),
    layers.Dense(256, activation='relu'),
    layers.Dropout(0.3),
    layers.Dense(128, activation='relu'),
    layers.Dropout(0.2),
    layers.Dense(5, activation='softmax')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()


def interleaved_generator(files, batch_size):
    """
    Generador que lee de TODOS los archivos simultáneamente para asegurar batches balanceados.
    """
    num_files = len(files)
    samples_per_file = batch_size // num_files
    
    # Crear iteradores para cada archivo
    iterators = [pd.read_csv(f, chunksize=samples_per_file) for f in files]
    
    while True:
        chunks = []
        for i in range(num_files):
            try:
                chunk = next(iterators[i])
            except StopIteration:
                # Si se acaba un archivo, reiniciarlo
                iterators[i] = pd.read_csv(files[i], chunksize=samples_per_file)
                chunk = next(iterators[i])
            
            chunks.append(chunk)
            
        # Combinar todos los chunks
        full_batch = pd.concat(chunks, ignore_index=True)
        
        # Barajar el batch completo
        full_batch = full_batch.sample(frac=1).reset_index(drop=True)
        
        X_batch = full_batch[FEATURES].values
        y_batch = full_batch[TARGET].values.reshape(-1, 1)
        
        # Escalar y codificar
        X_scaled = scaler.transform(X_batch)
        y_encoded = ohe.transform(y_batch)
        
        yield X_scaled, y_encoded

if __name__ == "__main__":
    print("\n🚀 Cargando y combinando todos los datasets...")

    BATCH_SIZE = 1024
    dataset_paths = [os.path.join(DATASETS_DIR, fname) for fname in DATASETS]

    # Configuración para entrenamiento rápido y seguro
    STEPS_PER_EPOCH = 500  # 500 pasos * 1024 batch = ~500k muestras por época
    EPOCHS = 20 

    train_generator = interleaved_generator(dataset_paths, BATCH_SIZE)

    # Callbacks
    early_stopping = callbacks.EarlyStopping(monitor='accuracy', patience=5, restore_best_weights=True)
    
    # Guardar el modelo cada vez que mejore la precisión
    checkpoint = callbacks.ModelCheckpoint(
        filepath="../modelos/modelo_invernadero.keras",
        monitor='accuracy',
        save_best_only=True,
        verbose=1
    )

    print(f"🚀 Iniciando entrenamiento rápido ({STEPS_PER_EPOCH} pasos por época)...")
    model.fit(train_generator,
              epochs=EPOCHS,
              steps_per_epoch=STEPS_PER_EPOCH,
              callbacks=[early_stopping, checkpoint])


    OUTPUT_MODEL = "../modelos/modelo_invernadero.keras"

    print("\n💾 Guardando modelo final...")
    model.save(OUTPUT_MODEL)

    print(f"\n✅ Modelo guardado exitosamente en: {OUTPUT_MODEL}")