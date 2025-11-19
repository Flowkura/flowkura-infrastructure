#!/bin/bash
###############################################################################
# FLOWKURA BACKUP SCRIPT
# Sauvegarde complète de l'infrastructure RAGFlow + LLM
###############################################################################

set -e

BACKUP_DIR="${BACKUP_DIR:-/root/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/flowkura_backup_$TIMESTAMP"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🔒 FLOWKURA BACKUP - $(date '+%Y-%m-%d %H:%M:%S')        ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo ""

# Créer dossier backup
mkdir -p "$BACKUP_PATH"/{configs,docker,data,ssl}

echo "📦 Backup configurations..."
cp -r /root/ragflow/conf "$BACKUP_PATH/configs/"
cp -r /root/ragflow/docker "$BACKUP_PATH/docker/"
cp /root/renew-ssl.sh "$BACKUP_PATH/" 2>/dev/null || true

echo "📦 Backup SSL certificates..."
cp -r /etc/letsencrypt "$BACKUP_PATH/ssl/" 2>/dev/null || true

echo "📦 Backup MySQL..."
docker exec ragflow-mysql mysqldump -uroot -pinfini_rag_flow rag_flow \
  > "$BACKUP_PATH/data/ragflow_mysql.sql"

echo "📦 Backup MinIO data..."
docker exec ragflow-minio mc alias set local http://localhost:9000 rag_flow infini_rag_flow
docker exec ragflow-minio mc cp --recursive local/ragflow "$BACKUP_PATH/data/minio_ragflow/"

echo "📦 Backup Ollama models..."
docker run --rm -v ollama_data:/data -v "$BACKUP_PATH/data":/backup \
  alpine tar czf /backup/ollama_models.tar.gz -C /data .

echo "📦 Backup Huggingface cache (modèles LLM)..."
tar czf "$BACKUP_PATH/data/huggingface_cache.tar.gz" \
  -C /root/.cache huggingface 2>/dev/null || true

echo "📊 Créer résumé..."
cat > "$BACKUP_PATH/BACKUP_INFO.txt" << EOF
FLOWKURA BACKUP
===============

Date: $(date)
Serveur: $(hostname)
Backup path: $BACKUP_PATH

Contenu:
- Configurations RAGFlow
- Configurations Docker
- Base de données MySQL
- Données MinIO
- Modèles Ollama
- Cache Huggingface
- Certificats SSL

Restauration:
./scripts/restore.sh $BACKUP_PATH
EOF

echo "🗜️  Compression finale..."
cd "$BACKUP_DIR"
tar czf "flowkura_backup_$TIMESTAMP.tar.gz" "flowkura_backup_$TIMESTAMP/"
rm -rf "flowkura_backup_$TIMESTAMP/"

BACKUP_SIZE=$(du -h "flowkura_backup_$TIMESTAMP.tar.gz" | cut -f1)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ BACKUP TERMINÉ                                        ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "  📦 Fichier: flowkura_backup_$TIMESTAMP.tar.gz"
echo "  💾 Taille: $BACKUP_SIZE"
echo "  📍 Emplacement: $BACKUP_DIR"
echo "╚════════════════════════════════════════════════════════════╝"
