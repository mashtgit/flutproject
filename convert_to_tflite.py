"""Convert Silero VAD ONNX model to TensorFlow Lite"""
import os
import sys

venv_path = os.path.join(os.path.dirname(__file__), 'venv', 'Lib', 'site-packages')
if os.path.exists(venv_path):
    sys.path.insert(0, venv_path)

from onnxruntime import InferenceSession
import numpy as np
import tensorflow as tf

def convert_to_tflite(input_path, output_path):
    print(f"Loading ONNX model from: {input_path}")
    
    # Create ONNX Runtime session
    session = InferenceSession(input_path)
    
    # Get input/output names
    input_name = session.get_inputs()[0].name
    output_name = session.get_outputs()[0].name
    
    print(f"Input: {input_name}, Output: {output_name}")
    
    # Test inference to understand the model
    # Create dummy input (this model uses [1, 1, 256, 1] or similar)
    # Based on the model info, it takes variable length input
    
    # Try to understand the model structure
    print("\nTrying to trace model for TFLite conversion...")
    
    # Since model has dynamic input, we need representative dataset
    # For Silero VAD, typical input is [batch, 1, 256, 1] or [batch, 1, samples, 1]
    
    # Let's create a simple TF model that does the same thing
    # Actually, let's just try to use the ONNX file directly in Flutter
    
    print("\n=== Alternative Approach ===")
    print("Since TFLite conversion requires fixed input shape,")
    print("we have two options:")
    print("1. Use onnxruntime_flutter package in Flutter (recommended)")
    print("2. Try TFLite with dynamic shapes")
    
    # Let's try TFLite with representative dataset
    print("\nTrying TFLite conversion with dynamic shapes...")
    
    # Create a model wrapper
    class OnnxWrapper(tf.keras.Model):
        def __init__(self, sess, input_name, output_name):
            super().__init__()
            self.sess = sess
            self.input_name = input_name
            self.output_name = output_name
            
        def call(self, x):
            # Run ONNX inference
            output = self.sess.run([self.output_name], {self.input_name: x.numpy()})
            return tf.constant(output[0])
    
    try:
        # Create wrapper model
        wrapper = OnnxWrapper(session, input_name, output_name)
        
        # Build with concrete input
        wrapper.build(input_shape=(1, 1, 256, 1))
        
        # Convert
        converter = tf.lite.TFLiteConverter.from_concrete_functions(
            wrapper.call.get_concrete_function(tf.TensorSpec(shape=(1, 1, 256, 1), dtype=tf.float32))
        )
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        print(f"Saving TFLite model to: {output_path}")
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        print("Model converted successfully!")
        print(f"Output size: {os.path.getsize(output_path) / 1024:.1f} KB")
        
    except Exception as e:
        print(f"TFLite conversion failed: {e}")
        print("\nFalling back to ONNX format...")
        
        # Just copy the ONNX file
        import shutil
        onnx_output = output_path.replace('.tflite', '.onnx')
        shutil.copy(input_path, onnx_output)
        print(f"Copied ONNX model to: {onnx_output}")
        
        # Also keep a copy with proper name
        final_output = "speech_world/assets/models/silero_vad.onnx"
        os.makedirs(os.path.dirname(final_output), exist_ok=True)
        shutil.copy(input_path, final_output)
        print(f"Also copied to: {final_output}")

if __name__ == "__main__":
    input_file = "silero_vad.onnx"
    output_file = "silero_vad.tflite"
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found!")
        sys.exit(1)
    
    convert_to_tflite(input_file, output_file)
