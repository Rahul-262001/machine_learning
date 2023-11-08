#!/bin/bash

# Prompt for the HTML file name
read -p "Enter the name of the HTML file (including extension): " HTML_FILE

# Check if the HTML file path is provided
if [ -z "$HTML_FILE" ]; then
    echo "Please provide the name of the HTML file."
    exit 1
fi

# Prompt for the Dockerfile name
read -p "Enter the name of the Dockerfile (including extension, e.g., Dockerfile): " DOCKERFILE_NAME

# Check if the Dockerfile name is provided
if [ -z "$DOCKERFILE_NAME" ]; then
    echo "Please provide the name of the Dockerfile."
    exit 1
fi

# Generate Dockerfile content
DOCKERFILE_CONTENT="FROM nginx:latest\nRUN rm -rf /usr/share/nginx/html/*\nCOPY $HTML_FILE /usr/share/nginx/html\nEXPOSE 80\nCMD [\"nginx\", \"-g\", \"daemon off;\"]"

# Save Dockerfile content to the specified file
echo -e "$DOCKERFILE_CONTENT" > "$DOCKERFILE_NAME"

# Check if Dockerfile creation was successful
if [ $? -ne 0 ]; then
    echo "Error creating Dockerfile."
    exit 1
fi

echo "Dockerfile created successfully: $DOCKERFILE_NAME"

# Prompt for Docker Hub repository name
read -p "Enter a name for Docker Hub repository: " DOCKERHUB_REPO

# Check if Docker Hub repository name is provided
if [ -z "$DOCKERHUB_REPO" ]; then
    echo "Please provide a name for Docker Hub repository."
    exit 1
fi

# Build Docker image
docker build -t $DOCKERHUB_REPO:latest .

# Check if Docker build was successful
if [ $? -ne 0 ]; then
    echo "Error building Docker image."
    exit 1
fi

# Tag Docker image
docker tag $DOCKERHUB_REPO:latest serieswatcher/$DOCKERHUB_REPO:latest

# Push Docker image to Docker Hub
docker push serieswatcher/$DOCKERHUB_REPO:latest

# Check if Docker push was successful
if [ $? -ne 0 ]; then
    echo "Error pushing Docker image to Docker Hub."
    exit 1
fi

# Prompt for the name of the Kubernetes deployment
read -p "Enter the name of the Kubernetes deployment: " K8S_DEPLOYMENT_NAME

# Prompt for the NodePort value
read -p "Enter the NodePort value (e.g., 30000-32767): " NODE_PORT

# Check if NodePort is provided
if [ -z "$NODE_PORT" ]; then
    echo "Please provide a NodePort value."
    exit 1
fi

# Create deployment.yaml file
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: $K8S_DEPLOYMENT_NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $K8S_DEPLOYMENT_NAME
  template:
    metadata:
      labels:
        app: $K8S_DEPLOYMENT_NAME
    spec:
      containers:
      - name: $K8S_DEPLOYMENT_NAME
        image: serieswatcher/$DOCKERHUB_REPO:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: $K8S_DEPLOYMENT_NAME-service
spec:
  selector:
    app: $K8S_DEPLOYMENT_NAME
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: $NODE_PORT
  type: NodePort" > deployment.yaml

# Apply Kubernetes deployment
kubectl apply -f deployment.yaml

# Check if Kubernetes deployment was successful
if [ $? -ne 0 ]; then
    echo "Error applying Kubernetes deployment."
    exit 1
fi

echo "Workflow completed successfully!"

echo "The link is http://10.0.0.8:$NODE_PORT/$HTML_FILE"
