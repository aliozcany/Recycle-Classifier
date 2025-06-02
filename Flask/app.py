from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
from PIL import Image
import io

app = Flask(__name__)

# Model ve labels yükleniyor
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Label'ları oku
with open("labels.txt", "r") as f:
    labels = [line.strip() for line in f.readlines()]

def preprocess_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    image = image.resize((224, 224))  # Modeline göre değişebilir
    image = np.array(image, dtype=np.float32) / 255.0
    image = np.expand_dims(image, axis=0)
    return image

@app.route("/predict", methods=["POST"])
def predict():
    if 'image' not in request.files:
        return jsonify({"error": "Dosya eksik"}), 400

    file = request.files['image']
    image_bytes = file.read()
    input_data = preprocess_image(image_bytes)

    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])

    predicted_index = np.argmax(output_data[0])
    confidence = float(np.max(output_data[0]))
    predicted_label = labels[predicted_index]

    return jsonify({
        "prediction": predicted_label,
        "confidence": confidence
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
