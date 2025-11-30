import csv
import random
import os


BASE_DIR = "../datos/datos_eventos_separados"
os.makedirs(BASE_DIR, exist_ok=True)

EVENTOS = ["NORMAL", "INCENDIO", "FUGA_H2", "FALLA_ELECTRICA", "PLAGA"]
FILAS_POR_EVENTO = 60_000_000
CHUNK_SIZE = 500_000 

print("Generador de datasets masivos iniciado...\n")


def generar_datos(evento):
    """Genera UNA fila basada en el tipo de evento."""
    if evento == "NORMAL":
        TEMP = random.uniform(18, 30)      # Rango ideal y estable
        HUM = random.uniform(50, 75)       # Humedad controlada
        SOIL1 = random.uniform(50, 80)
        SOIL2 = random.uniform(50, 80)
        MQ2 = random.uniform(50, 150)      # Aire limpio
        MQ5 = random.uniform(50, 150)
        MQ8 = random.uniform(50, 150)
        AQI = random.uniform(10, 50)       # Calidad de aire excelente

    elif evento == "INCENDIO":
        TEMP = random.uniform(35, 90)      # Empieza a subir desde el límite normal
        HUM = random.uniform(5, 30)        # El aire se seca
        SOIL1 = random.uniform(10, 50)     # El suelo se seca
        SOIL2 = random.uniform(10, 50)
        MQ2 = random.uniform(400, 1023)    # Mucho humo (MQ2 sensible a humo)
        MQ5 = random.uniform(300, 700)
        MQ8 = random.uniform(200, 500)
        AQI = random.uniform(150, 500)     # Calidad de aire pésima

    elif evento == "FUGA_H2":
        TEMP = random.uniform(20, 35)      # La temperatura puede ser normal
        HUM = random.uniform(40, 70)       # La humedad puede ser normal
        SOIL1 = random.uniform(40, 80)
        SOIL2 = random.uniform(40, 80)
        MQ2 = random.uniform(100, 350)
        MQ5 = random.uniform(100, 350)
        MQ8 = random.uniform(600, 1023)    # MQ8 muy sensible a Hidrógeno (H2)
        AQI = random.uniform(60, 150)      # El AQI puede subir un poco

    elif evento == "FALLA_ELECTRICA":
        # En una falla eléctrica, los sensores darían lecturas erráticas o cero.
        # Para simularlo, podemos usar rangos muy amplios o valores atípicos.
        TEMP = random.choice([random.uniform(0, 5), random.uniform(90, 100), 0])
        HUM = random.choice([random.uniform(0, 10), random.uniform(95, 100), 0])
        SOIL1 = random.choice([random.uniform(0, 10), random.uniform(95, 100), 0])
        SOIL2 = random.choice([random.uniform(0, 10), random.uniform(95, 100), 0])
        MQ2 = random.uniform(0, 1023) # Lectura totalmente impredecible
        MQ5 = random.uniform(0, 1023)
        MQ8 = random.uniform(0, 1023)
        AQI = random.uniform(0, 500)

    elif evento == "PLAGA":
        TEMP = random.uniform(25, 38)      # Ligeramente más cálido
        HUM = random.uniform(70, 95)       # Mucha humedad, ideal para hongos/plagas
        SOIL1 = random.uniform(60, 90)     # Suelo muy húmedo
        SOIL2 = random.uniform(60, 90)
        MQ2 = random.uniform(150, 400)     # Los compuestos orgánicos volátiles pueden aumentar
        MQ5 = random.uniform(150, 400)
        MQ8 = random.uniform(100, 300)
        AQI = random.uniform(50, 120)      # La calidad del aire empeora un poco

    return [TEMP, HUM, SOIL1, SOIL2, MQ2, MQ5, MQ8, AQI, evento]


for evento in EVENTOS:
    ruta_csv = f"{BASE_DIR}/{evento.lower()}.csv"

    print(f"\n📝 Generando dataset: {ruta_csv}")

    with open(ruta_csv, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["temp", "hum", "soil1", "soil2", "mq2", "mq5", "mq8", "aqi", "evento"])

        filas_generadas = 0
        buffer = []

        while filas_generadas < FILAS_POR_EVENTO:
            buffer.append(generar_datos(evento))
            filas_generadas += 1

            if len(buffer) >= CHUNK_SIZE:
                writer.writerows(buffer)
                buffer = []
                print(f" - {filas_generadas:,}/{FILAS_POR_EVENTO:,} filas ({evento})")

        if buffer:
            writer.writerows(buffer)

    print(f"✅ Dataset completado: {evento} ({FILAS_POR_EVENTO:,} filas)")


print("\n🎉 PROCESO COMPLETADO: Se generaron los 5 datasets por separado.")