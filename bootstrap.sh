#!/bin/bash

set -euo pipefail

echo "🔍 Pre-flight checks..."

# Check dependencies
for cmd in kubectl helm curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ '$cmd' is required but not installed. Aborting."
        exit 1
    fi
done

# Check cluster connection
echo "🔌 Checking Kubernetes context..."
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 Current context: $CURRENT_CONTEXT"

read -p "❓ Is this the correct cluster context? (y/n): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborting. Switch to the correct context and re-run the script."
    exit 1
fi

if ! kubectl get nodes &>/dev/null; then
    echo "❌ Cannot connect to the cluster or insufficient permissions."
    exit 1
fi

# Step 1: Create namespace
echo "📁 Creating namespace 'argocd'..."
kubectl create namespace argocd 2>/dev/null || echo "ℹ️ Namespace already exists."

# Step 2: Add Helm repo and install ArgoCD
echo "📦 Adding Argo Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "🚀 Installing ArgoCD via Helm..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP

# Step 3: Wait for ArgoCD server to be ready
echo "⏳ Waiting for ArgoCD server to become available..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=600s

# Step 4: Get ArgoCD admin password
echo "🔐 Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "✅ ArgoCD admin password: $ARGOCD_PASSWORD"

# # Step 5: Install ArgoCD CLI
# if ! command -v argocd &> /dev/null; then
#     echo "📥 Installing ArgoCD CLI..."
    
#     OS=$(uname | tr '[:upper:]' '[:lower:]')
#     ARCH=$(uname -m)
#     if [[ "$ARCH" == "x86_64" ]]; then ARCH="amd64"; fi
#     if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then ARCH="arm64"; fi

#     VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
#     CLI_URL="https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-$OS-$ARCH"

#     curl -sSL -o /usr/local/bin/argocd "$CLI_URL"
#     chmod +x /usr/local/bin/argocd
#     echo "✅ ArgoCD CLI installed at /usr/local/bin/argocd"
# else
#     echo "✅ ArgoCD CLI already installed"
# fi

# Step 6: Output access instructions
echo ""
echo "🌐 Access the ArgoCD UI by port-forwarding in another terminal:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "🔑 Login to the UI:"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "🎉 Done!"

# Step 7: Deploy App of Apps
echo "🚀 Deploying App of Apps..."
kubectl apply -f apps/app-of-apps.yaml

echo "⏳ Waiting for App of Apps to be created..."
kubectl wait --for=condition=available --timeout=60s application/bootstrap-apps -n argocd || echo "ℹ️ App of Apps created, sync may take a moment"

# Step 8: Show application status
echo "📊 Checking application status..."
sleep 5  # Give it a moment to start syncing
kubectl get applications -n argocd

# Step 9: Output access instructions
echo ""
echo "🌐 Access the ArgoCD UI by port-forwarding in another terminal:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "🔑 Login to the UI:"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "📱 Monitor your applications:"
echo "kubectl get applications -n argocd -w"
echo ""
echo "🌍 Once Traefik is ready, test hello-world at:"
echo "http://hello.localhost (add '127.0.0.1 hello.localhost' to /etc/hosts)"
echo ""
echo "🎉 Bootstrap complete! Check ArgoCD UI to monitor deployments."