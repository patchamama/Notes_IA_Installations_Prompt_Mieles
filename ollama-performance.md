# Ollama Local — Performance & Configuration Guide

Guía de referencia para maximizar el rendimiento de Ollama en local.
Aplica a cualquier proyecto que use la API de Ollama directamente desde el navegador o servidor.

---

## 1. Iniciar Ollama con máximo rendimiento

### macOS / Linux

```bash
# Mínimo requerido (CORS para browser)
OLLAMA_HOST=0.0.0.0:11434 \
OLLAMA_ORIGINS="*" \
ollama serve

# Recomendado: con KV cache cuantizado + paralelismo
OLLAMA_HOST=0.0.0.0:11434 \
OLLAMA_ORIGINS="*" \
OLLAMA_KV_CACHE_TYPE=q8_0 \
OLLAMA_NUM_PARALLEL=2 \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve
```

### Windows — PowerShell

```powershell
# Mínimo
$env:OLLAMA_HOST="0.0.0.0:11434"
$env:OLLAMA_ORIGINS="*"
ollama serve

# Recomendado
$env:OLLAMA_HOST="0.0.0.0:11434"
$env:OLLAMA_ORIGINS="*"
$env:OLLAMA_KV_CACHE_TYPE="q8_0"
$env:OLLAMA_NUM_PARALLEL="2"
$env:OLLAMA_KEEP_ALIVE="-1"
ollama serve
```

### Windows — CMD

```cmd
:: Mínimo
set OLLAMA_HOST=0.0.0.0:11434 && set OLLAMA_ORIGINS=* && ollama serve

:: Recomendado
set OLLAMA_HOST=0.0.0.0:11434 && ^
set OLLAMA_ORIGINS=* && ^
set OLLAMA_KV_CACHE_TYPE=q8_0 && ^
set OLLAMA_NUM_PARALLEL=2 && ^
set OLLAMA_KEEP_ALIVE=-1 && ^
ollama serve
```

### Detener instancia previa

```bash
# macOS / Linux
pkill -f ollama

# Windows PowerShell
Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue

# Windows CMD
taskkill /F /IM ollama.exe 2>nul
```

---

## 2. Variables de entorno — referencia completa

| Variable | Valores | Default | Efecto |
|---|---|---|---|
| `OLLAMA_HOST` | `0.0.0.0:11434` | `127.0.0.1:11434` | Permite conexiones externas (necesario para apps en navegador) |
| `OLLAMA_ORIGINS` | `*` o dominios separados por coma | vacío | CORS — permite requests desde el browser |
| `OLLAMA_KEEP_ALIVE` | `-1`, `0`, `5m`, `1h` | `5m` | Tiempo que el modelo permanece en VRAM tras el último request |
| `OLLAMA_KV_CACHE_TYPE` | `f16`, `q8_0`, `q4_0` | `f16` | Cuantización del KV cache (ver sección 3) |
| `OLLAMA_NUM_PARALLEL` | `1`, `2`, `4`… | auto (4 o 1) | Requests concurrentes al mismo modelo sin descargarlo |
| `OLLAMA_MAX_LOADED_MODELS` | `1`, `2`… | auto | Modelos cargados en VRAM simultáneamente |
| `OLLAMA_MAX_QUEUE` | número | `512` | Requests en cola antes de rechazar nuevos |
| `OLLAMA_FLASH_ATTENTION` | `1` | `0` | Activa Flash Attention (requerido para q8_0/q4_0 KV cache) |

---

## 3. KV Cache Quantization — reducir VRAM sin perder calidad

El KV cache almacena los estados intermedios de atención. Cuantizarlo reduce la VRAM necesaria sin afectar significativamente la calidad de las respuestas.

| Tipo | VRAM vs f16 | Precisión | Requisitos |
|---|---|---|---|
| `f16` | 100% (baseline) | Máxima | — |
| `q8_0` | ~50% | Mínima pérdida (imperceptible) | Flash Attention |
| `q4_0` | ~25% | Pérdida notable | Flash Attention |

**Recomendación**: `q8_0` es el mejor balance. La pérdida de calidad es prácticamente imperceptible.

Flash Attention es compatible con:
- Apple Silicon (Metal)
- NVIDIA Pascal+ (GTX 10xx en adelante)
- AMD ROCm

```bash
# Activar Flash Attention + KV cache q8_0
OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 ollama serve
```

---

## 4. keep_alive — mantener el modelo en memoria

**El problema**: por defecto Ollama descarga el modelo de VRAM a los 5 minutos de inactividad. En un pipeline multi-pass (corrección → vocabulario → ejercicios), si los passes tardan mucho, el modelo puede descargarse entre requests y recargarse, añadiendo 20-40 segundos de latencia.

**La solución**: `keep_alive: -1` en cada request mantiene el modelo cargado indefinidamente.

### Desde la API (en cada request)

```json
{
  "model": "translategemma:12b",
  "keep_alive": -1,
  "messages": [...]
}
```

Valores posibles:
- `-1` → indefinido (hasta que Ollama se detenga o necesite VRAM para otro modelo)
- `0` → descargar inmediatamente después del request
- `"5m"` → 5 minutos
- `"1h"` → 1 hora
- `3600` → 3600 segundos

### Via variable de entorno (global para todos los modelos)

```bash
OLLAMA_KEEP_ALIVE=-1 ollama serve
```

---

## 5. KV Cache automático por prefix matching

Ollama reutiliza automáticamente el KV cache cuando el inicio del prompt es idéntico entre requests. Esto significa que si el **system prompt no cambia**, el modelo no lo re-evalúa en requests sucesivos — ahorra tokens de prefill.

**Cómo aprovechar esto**:
- Usar strings de system prompt constantes (no interpolados dinámicamente)
- No agregar timestamps, IDs o datos cambiantes al system prompt
- Mantener el system prompt igual para todos los passes que usen el mismo modelo

```
Request 1: [system: "Eres un corrector..."] [user: "texto 1"]
Request 2: [system: "Eres un corrector..."] [user: "texto 2"]
                     ↑ KV cache reutilizado ↑
```

---

## 6. Requests concurrentes — OLLAMA_NUM_PARALLEL

Ollama puede procesar múltiples requests al mismo modelo en paralelo sin descargarlo.

```bash
OLLAMA_NUM_PARALLEL=2 ollama serve  # 2 requests en paralelo
```

**Caveat importante**: el contexto se multiplica por el número de requests paralelos.
`4 requests × 4096 tokens de contexto = 16.384 tokens en VRAM`

Si la VRAM es limitada, preferí `NUM_PARALLEL=1` con `keep_alive=-1`.

---

## 7. Verificar que Ollama funciona correctamente

```bash
# Ver modelos instalados
curl http://localhost:11434/api/tags

# Ping simple
curl http://localhost:11434/

# Ver modelo cargado actualmente
curl http://localhost:11434/api/ps

# Ver info de un modelo
curl http://localhost:11434/api/show -d '{"model":"translategemma:12b"}'
```

---

## 8. Instalar y gestionar modelos

```bash
# Descargar un modelo
ollama pull translategemma:12b
ollama pull gemma3:12b
ollama pull llama3.1:8b

# Listar modelos instalados
ollama list

# Eliminar un modelo
ollama rm nombre-del-modelo

# Ejecutar modelo en modo chat (terminal)
ollama run translategemma:12b

# Ver cuánta VRAM usa un modelo
ollama ps
```

---

## 9. Parámetros de inferencia — referencia

Estos parámetros van dentro del campo `options` de la API:

| Parámetro | Rango | Efecto |
|---|---|---|
| `temperature` | 0–1 | 0 = determinístico, 1 = creativo. Para corrección usar 0.1–0.3 |
| `top_p` | 0–1 | Nucleus sampling. 0.9 es un buen default |
| `top_k` | entero | Limita el vocabulario de muestreo. 40 = default |
| `num_ctx` | 512–128000+ | Ventana de contexto. Afecta directamente la VRAM usada |
| `num_predict` | -1, entero | Tokens máximos de respuesta. -1 = ilimitado |
| `seed` | entero | Fija la semilla para respuestas reproducibles |
| `repeat_penalty` | 0–2 | Penaliza la repetición. 1.1 es un buen default |

---

## 10. Novedades 2024-2025 relevantes

| Feature | Desde | Descripción |
|---|---|---|
| KV cache quantization | 2024 | `OLLAMA_KV_CACHE_TYPE`: q8_0 reduce VRAM a la mitad |
| Speculative decoding | 2024-2025 | ~2× speedup en modelos que lo soportan (Gemma 4) |
| MLX en Apple Silicon | Marzo 2025 | Más rápido en Mac M-series |
| Model scheduling mejorado | Sept 2025 | Menos crashes en multi-GPU |
| `/api/show` cacheado | 2024 | 6.7× menos latencia en metadata queries |

---

## 11. Configuración recomendada según hardware

### Mac Apple Silicon (M1/M2/M3/M4) — GPU unificada

```bash
OLLAMA_HOST=0.0.0.0:11434 \
OLLAMA_ORIGINS="*" \
OLLAMA_FLASH_ATTENTION=1 \
OLLAMA_KV_CACHE_TYPE=q8_0 \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve
```

### PC con GPU NVIDIA (8GB+ VRAM)

```bash
OLLAMA_HOST=0.0.0.0:11434 \
OLLAMA_ORIGINS="*" \
OLLAMA_FLASH_ATTENTION=1 \
OLLAMA_KV_CACHE_TYPE=q8_0 \
OLLAMA_NUM_PARALLEL=2 \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve
```

### PC sin GPU dedicada (solo CPU)

```bash
OLLAMA_HOST=0.0.0.0:11434 \
OLLAMA_ORIGINS="*" \
OLLAMA_KEEP_ALIVE=-1 \
ollama serve
# KV cache quantization no aplica sin GPU compatible con Flash Attention
# num_ctx bajo (1024-2048) para no agotar RAM
```

---

*Documentación basada en Ollama API docs, GitHub releases y testing en speak-mentor.*
*Última actualización: mayo 2026.*
