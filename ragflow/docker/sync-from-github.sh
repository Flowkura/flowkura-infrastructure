set -e

echo '🔄 Synchronisation RAGFlow depuis GitHub...'

# Backup actuel
BACKUP_DIR="/root/ragflow-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📦 Backup dans $BACKUP_DIR"
cp .env "$BACKUP_DIR/.env.backup"

# Pull depuis GitHub
cd /root
if [ -d "flowkura-infrastructure" ]; then
    cd flowkura-infrastructure
    git pull
else
    git clone https://github.com/Flowkura/flowkura-infrastructure.git
    cd flowkura-infrastructure
fi

# Copier les fichiers
echo "📂 Copie des fichiers..."
rsync -av --exclude='volumes/' --exclude='.git' ragflow/docker/ /root/ragflow/docker/

# Restaurer .env personnel
if [ -f "$BACKUP_DIR/.env.backup" ]; then
    echo "🔐 Restauration .env personnel"
    cp "$BACKUP_DIR/.env.backup" /root/ragflow/docker/.env
fi

echo ""
echo "Pour appliquer les changements :"
echo "  cd /root/ragflow/docker"
echo "  docker compose -f docker-compose-gpu.yml up -d"
