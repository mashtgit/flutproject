# Silero VAD Setup Instructions

## Overview

This project includes Silero VAD (Voice Activity Detection) integration for better speech detection in Dialogue Mode. The system automatically falls back to amplitude-based VAD if the Silero model is not available.

## Silero VAD vs Amplitude-Based VAD

### Why Silero VAD is Better:
- **Noise Rejection**: Silero is trained on vast datasets and can distinguish human speech from background noise (keyboard, AC, paper rustling)
- **Quiet Speech Detection**: Recognizes whisper that may be quieter than background noise
- **Local Processing**: Model is only ~2MB and runs on-device without internet

## Download Silero VAD Model

### Step 1: Download the Model

Download the Silero VAD ONNX model from the official repository:

```bash
# Option 1: Using wget
wget https://github.com/snakers4/silero-vad/raw/master/src/silero_vad/files/silero_vad.onnx -O silero_vad.onnx

# Option 2: Using curl
curl -L https://github.com/snakers4/silero-vad/raw/master/src/silero_vad/files/silero_vad.onnx -o silero_vad.onnx
```

### Step 2: Convert to TensorFlow Lite (Optional)

The Silero VAD model works with ONNX format. For TFLite conversion:

```python
# Install dependencies
pip install onnx onnx-tf tensorflow

# Convert ONNX to TFLite
python << 'EOF'
import onnx
from onnx_tf.backend import prepare
import tensorflow as tf

# Load ONNX model
onnx_model = onnx.load('silero_vad.onnx')

# Convert to TensorFlow
tf_rep = prepare(onnx_model)

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_concrete_functions(
    tf_rep.signatures.values()
)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save
with open('silero_vad.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model converted to TFLite!")
EOF
```

### Step 3: Add Model to Project

Place the model file in the Flutter assets folder:

```
speech_world/
└── assets/
    └── models/
        └── silero_vad.tflite   # Or silero_vad.onnx
```

### Step 4: Update pubspec.yaml

Add the assets to your pubspec.yaml:

```yaml
flutter:
  assets:
    - assets/svg/icons/
    - assets/images/logo/
    # ... existing assets ...
    - assets/models/
```

### Step 5: Update SileroVadService

The current implementation looks for the model in the app documents directory. Update the path in `silero_vad_service.dart` to load from assets:

```dart
Future<String?> _getModelPath() async {
  // Option 1: Load from assets
  return 'assets/models/silero_vad.tflite';
  
  // Option 2: Check documents directory
  // final appDir = await getApplicationDocumentsDirectory();
  // return '${appDir.path}/silero_vad.tflite';
}
```

## Configuration Parameters

The VAD parameters can be adjusted in `vad_controller.dart`:

### VadConfig
| Parameter | Default | Description |
|-----------|---------|-------------|
| `vadThreshold` | 0.5 | Speech detection threshold (0.0-1.0) |
| `minSpeechDurationMs` | 250ms | Min speech to trigger gate open |
| `minSilenceDurationMs` | 800ms | Silence to close gate |
| `gateCloseTimeout` | 800ms | Timeout before closing gate |

### SileroVadConfig
| Parameter | Default | Description |
|-----------|---------|-------------|
| `threshold` | 0.5 | Silero probability threshold |
| `minSpeechDurationMs` | 250ms | Min speech frames |
| `minSilenceDurationMs` | 800ms | Min silence frames |
| `chunkDurationMs` | 30ms | Processing chunk size |

## Tuning Recommendations

### For Noisy Environments
- Increase `vadThreshold` to 0.6-0.8
- Increase `minSpeechDurationMs` to 300ms

### For Quiet Speech / Whisper
- Decrease `vadThreshold` to 0.3-0.4
- Decrease `minSpeechDurationMs` to 200ms

### For Natural Conversation
- Keep defaults: threshold=0.5, minSpeech=250ms, minSilence=800ms

## Troubleshooting

### Model Not Loading
If Silero VAD doesn't load, the app automatically uses amplitude-based VAD as fallback. Check logs for:
- `[SileroVadService] Model not found in assets`
- `[SileroVadService] Failed to load model: ...`

### Poor Detection
1. Check microphone is working
2. Adjust threshold based on environment
3. Ensure AudioSession is configured for voiceChat mode

## Testing

To test Silero VAD integration:
1. Build and run the app
2. Check logs for `[VADController] Silero VAD loaded successfully`
3. If you see `[VADController] Silero VAD not available`, the model is missing but fallback works

## Performance Notes

- Silero VAD inference: ~5-10ms per chunk on modern devices
- Amplitude-based VAD: ~1ms per chunk
- Both run on-device without network calls
