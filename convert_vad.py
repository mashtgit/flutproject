"""Simple ONNX model info viewer using onnxruntime"""
import os
import sys

# Get the correct site-packages path for Windows
venv_path = os.path.join(os.path.dirname(__file__), 'venv', 'Lib', 'site-packages')
if os.path.exists(venv_path):
    sys.path.insert(0, venv_path)

from onnxruntime import InferenceSession

def inspect_model(input_path):
    print(f"Loading ONNX model from: {input_path}")
    
    # Create session
    session = InferenceSession(input_path)
    
    # Get model info
    print("\n=== Model Inputs ===")
    for inp in session.get_inputs():
        print(f"  Name: {inp.name}")
        print(f"  Shape: {inp.shape}")
        print(f"  Type: {inp.type}")
    
    print("\n=== Model Outputs ===")
    for out in session.get_outputs():
        print(f"  Name: {out.name}")
        print(f"  Shape: {out.shape}")
        print(f"  Type: {out.type}")
    
    print("\n=== Model Ready ===")
    print("The model is valid and can be used with onnxruntime!")
    
    # Copy to output
    output_path = input_path.replace('.onnx', '_model.onnx')
    import shutil
    shutil.copy(input_path, output_path)
    print(f"\nModel copied to: {output_path}")
    print(f"Size: {os.path.getsize(output_path) / 1024:.1f} KB")

if __name__ == "__main__":
    input_file = "silero_vad.onnx"
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found!")
        sys.exit(1)
    
    inspect_model(input_file)
