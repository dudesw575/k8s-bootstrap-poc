#!/bin/bash
echo "🌐 Starting ArgoCD port-forward..."
echo "ArgoCD UI will be available at: http://localhost:8080"
echo ""
echo "🔑 Credentials:"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo "Press Ctrl+C to stop"
kubectl port-forward svc/argocd-server -n argocd 8080:80