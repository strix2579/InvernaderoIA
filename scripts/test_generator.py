import numpy as np
import pandas as pd
import os
import sys

# Asegurar que podemos importar entrenar_ia
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from entrenar_ia import interleaved_generator, DATASETS_DIR, DATASETS, ohe

def test_interleaved_generator():
    print("🧪 Iniciando prueba del generador entrelazado...")
    
    # Configuración de prueba
    BATCH_SIZE = 100
    dataset_paths = [os.path.join(DATASETS_DIR, fname) for fname in DATASETS]
    
    # Crear generador
    gen = interleaved_generator(dataset_paths, BATCH_SIZE)
    
    # Obtener un batch
    print("⏳ Obteniendo un batch...")
    X_batch, y_batch = next(gen)
    
    print(f"✅ Batch obtenido. Shape X: {X_batch.shape}, Shape y: {y_batch.shape}")
    
    # Decodificar etiquetas para ver las clases
    y_decoded = ohe.inverse_transform(y_batch)
    
    # Contar clases
    unique, counts = np.unique(y_decoded, return_counts=True)
    distribution = dict(zip(unique.flatten(), counts))
    
    print("\n📊 Distribución de clases en el batch (debería ser variada):")
    for clase, count in distribution.items():
        print(f"  - {clase}: {count}")
        
    # Verificación básica
    if len(distribution) > 1:
        print("\n✅ ÉXITO: El batch contiene múltiples clases.")
    else:
        print("\n❌ FALLO: El batch contiene solo una clase.")

if __name__ == "__main__":
    test_interleaved_generator()
