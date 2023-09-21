import os
import librosa
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.externals import joblib  # for model persistence

# Define a function to extract audio features from an MP3 file
def extract_features(mp3_path):
    y, sr = librosa.load(mp3_path, sr=None)  # Load the audio file
    mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)  # Extract MFCC features
    chroma = librosa.feature.chroma_stft(y=y, sr=sr)  # Extract Chroma features
    features = np.vstack((mfccs, chroma))
    return features


# Path to the directory containing the training MP3 files
training_data_dir = 'music'

# Collect the feature vectors and corresponding labels from training data
X_train = []
y_train = []

# Iterate through the MP3 files in the training directory
for root, _, files in os.walk(training_data_dir):
    for file in files:
        if file.endswith(".mp3"):
            mp3_path = os.path.join(root, file)
            label = os.path.basename(root)  # Use the directory name as the label
            features = extract_features(mp3_path)
            X_train.append(features)
            y_train.append(label)

# Convert the lists to NumPy arrays
X_train = np.array(X_train)
y_train = np.array(y_train)

# Split the training data into training and validation sets
X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.2, random_state=42)

# Initialize and train a RandomForestClassifier (you can use other classifiers as well)
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

# Make predictions on the validation set for evaluation
y_val_pred = clf.predict(X_val)

# Calculate accuracy on the validation set
validation_accuracy = accuracy_score(y_val, y_val_pred)
print(f"Validation Accuracy: {validation_accuracy * 100:.2f}%")

# Save the trained model to a file for future use
model_filename = 'music_recognition_model.pkl'
joblib.dump(clf, model_filename)

# Path to the new music file you want to test
new_music_file_path = 'test.mp3'

# Extract features from the new music file
new_music_features = extract_features(new_music_file_path)

# Reshape the features to match the shape used during training
new_music_features = new_music_features.reshape(1, -1)

# Load the trained model
loaded_model = joblib.load(model_filename)

# Use the trained model to predict the label for the new music file
predicted_label = loaded_model.predict(new_music_features)[0]

# Calculate the probability of the prediction
prediction_probabilities = loaded_model.predict_proba(new_music_features)
predicted_probability = prediction_probabilities.max() * 100

print(f"Predicted Song: {predicted_label}")
print(f"Match Confidence: {predicted_probability:.2f}%")
