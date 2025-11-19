#!/bin/bash
###############################################################################
# FLOWKURA HEALTH CHECK
# Vérifie l'état de tous les services
###############################################################################

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🏥 FLOWKURA HEALTH CHECK - $(date '+%H:%M:%S')           ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo ""

# Check SSH connection
echo "🔌 Connexion serveur..."
if ssh -o ConnectTimeout=5 root@136.243.41.162 'exit' 2>/dev/null; then
  echo "  ✅ SSH OK"
else
  echo "  ❌ SSH FAILED"
  exit 1
fi

# Check containers
echo ""
echo "🐳 Containers Docker..."
ssh root@136.243.41.162 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"' | grep -E "flowkura|ragflow" | while read line; do
  if echo "$line" | grep -q "Up"; then
    echo "  ✅ $line"
  else
    echo "  ❌ $line"
  fi
done

# Check VRAM
echo ""
echo "💾 VRAM GPU..."
ssh root@136.243.41.162 'nvidia-smi --query-gpu=memory.used,memory.free,utilization.gpu --format=csv,noheader' | while read line; do
  echo "  📊 $line"
done

# Check URLs
echo ""
echo "🌐 URLs accessibles..."

# RAGFlow HTTPS
if curl -s -k -o /dev/null -w "%{http_code}" https://ragflow.flowkura.com | grep -q "200\|301\|302"; then
  echo "  ✅ RAGFlow HTTPS: https://ragflow.flowkura.com"
else
  echo "  ❌ RAGFlow HTTPS inaccessible"
fi

# SGLang API
if ssh root@136.243.41.162 'curl -s http://localhost:8000/v1/models' | grep -q "Qwen"; then
  echo "  ✅ SGLang API: http://localhost:8000"
else
  echo "  ❌ SGLang API inaccessible"
fi

# Ollama API
if ssh root@136.243.41.162 'curl -s http://localhost:11434/api/tags' | grep -q "nomic"; then
  echo "  ✅ Ollama API: http://localhost:11434"
else
  echo "  ❌ Ollama API inaccessible"
fi

# Check SSL cert
echo ""
echo "🔒 Certificat SSL..."
CERT_EXPIRY=$(ssh root@136.243.41.162 'openssl x509 -enddate -noout -in /etc/letsencrypt/live/ragflow.flowkura.com/fullchain.pem 2>/dev/null | cut -d= -f2')
if [ -n "$CERT_EXPIRY" ]; then
  echo "  ✅ Expire le: $CERT_EXPIRY"
else
  echo "  ⚠️  Impossible de vérifier"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ HEALTH CHECK TERMINÉ                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
