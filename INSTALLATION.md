# 🚀 Installation Flowkura RAGFlow

## 📋 Prérequis

- Ubuntu Server 22.04
- NVIDIA GPU (Tesla T4 ou supérieure)
- Docker & Docker Compose
- Nginx avec Let's Encrypt
- Au moins 32GB RAM
- 100GB espace disque

## 🔧 Installation Rapide

### 1. Cloner le repository

```bash
cd /root
git clone https://github.com/Flowkura/flowkura-infrastructure.git ragflow
cd ragflow/ragflow/docker
```

### 2. Configuration de l'environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer le fichier .env
nano .env
```

Variables importantes à modifier :
```env
HF_TOKEN=votre_token_huggingface
RAGFLOW_IMAGE=infiniflow/ragflow:v0.15.0-slim
```

### 3. Démarrer les services

```bash
# Lancer avec GPU
docker compose -f docker-compose-gpu.yml up -d

# Vérifier les logs
docker compose -f docker-compose-gpu.yml logs -f
```

### 4. Configuration Ollama (Embedding)

```bash
# Se connecter au container Ollama
docker exec -it flowkura-ollama bash

# Télécharger le modèle bge-m3
ollama pull bge-m3

# Vérifier
ollama list
```

### 5. Configuration SGLang (LLM)

Le modèle Qwen3-8B se télécharge automatiquement au démarrage de SGLang.

Vérifier les logs :
```bash
docker logs flowkura-sglang-qwen3
```

### 6. Accès à l'interface

- **Local** : http://localhost:9380
- **Production** : https://ragflow.flowkura.com

Identifiants par défaut :
- Email : `admin@flowkura.com`
- Password : (voir `.env` - `RAGFLOW_PASSWORD`)

## 🔐 Configuration Nginx + SSL

### Fichier Nginx : `/etc/nginx/sites-available/ragflow`

```nginx
upstream ragflow_backend {
    server 127.0.0.1:9380;
}

server {
    listen 80;
    server_name ragflow.flowkura.com;
    
    # Redirection HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ragflow.flowkura.com;

    # SSL Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/ragflow.flowkura.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ragflow.flowkura.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Upload size
    client_max_body_size 500M;

    location / {
        proxy_pass http://ragflow_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
```

### Activer et recharger Nginx

```bash
# Créer le lien symbolique
ln -s /etc/nginx/sites-available/ragflow /etc/nginx/sites-enabled/

# Obtenir le certificat SSL
certbot --nginx -d ragflow.flowkura.com

# Tester la configuration
nginx -t

# Recharger
systemctl reload nginx
```

## 📊 Configuration des modèles dans RAGFlow

### 1. Se connecter à l'interface web

### 2. Aller dans Settings → System Model Settings

### 3. Ajouter SGLang (LLM)

- **Type** : OpenAI-API-Compatible
- **Model Name** : `Qwen/Qwen3-8B`
- **Base URL** : `http://flowkura-sglang-qwen3:30000/v1`
- **API Key** : `EMPTY` (ou n'importe quoi)
- **Max Tokens** : `8192`

### 4. Ajouter Ollama (Embedding)

- **Type** : Ollama
- **Model Name** : `bge-m3`
- **Base URL** : `http://flowkura-ollama:11434`
- **Max Tokens** : `8192`

## 🗂️ Création d'un Dataset

1. Aller dans **Datasets** → **Create Dataset**
2. Nom : `Fiches Métiers ONISEP`
3. Embedding Model : `bge-m3@Ollama`
4. Chunk Method : `naive` (General)
5. Parser Config :
   - chunk_token_num : `512`
   - similarity_threshold : `0.2`
   - top_n : `6`

## 📤 Upload de documents

### Via l'interface

Glisser-déposer les fichiers dans le dataset

### Via API

```bash
curl --request POST \
     --url http://localhost:9380/api/v1/datasets/{dataset_id}/documents \
     --header 'Content-Type: multipart/form-data' \
     --header 'Authorization: Bearer YOUR_API_KEY' \
     --form 'file=@./document.pdf'
```

## 🔄 Parsing des documents

### Via l'interface

Sélectionner les documents → **Parse**

### Via API

```bash
curl --request POST \
     --url http://localhost:9380/api/v1/datasets/{dataset_id}/chunks \
     --header 'Content-Type: application/json' \
     --header 'Authorization: Bearer YOUR_API_KEY' \
     --data '{
          "document_ids": ["doc_id_1", "doc_id_2"]
     }'
```

## 🤖 Créer un Chat Assistant

1. **Chats** → **Create Chat**
2. Nom : `Assistant Orientation`
3. Datasets : Sélectionner vos datasets
4. LLM : `Qwen/Qwen3-8B@VLLM`
5. Temperature : `0.1`
6. Prompt : Personnaliser selon vos besoins

## 🛠️ Commandes utiles

### Voir les logs

```bash
# RAGFlow
docker logs -f ragflow-server

# SGLang Qwen3
docker logs -f flowkura-sglang-qwen3

# Ollama
docker logs -f flowkura-ollama

# MySQL
docker logs -f ragflow-mysql

# Redis
docker logs -f ragflow-redis
```

### Redémarrer les services

```bash
cd /root/ragflow/ragflow/docker

# Tout redémarrer
docker compose -f docker-compose-gpu.yml restart

# Service spécifique
docker compose -f docker-compose-gpu.yml restart ragflow
```

### Arrêter les services

```bash
docker compose -f docker-compose-gpu.yml down
```

### Nettoyer les volumes (⚠️ ATTENTION : perte de données)

```bash
docker compose -f docker-compose-gpu.yml down -v
```

## 📈 Monitoring

### Utilisation GPU

```bash
nvidia-smi -l 1
```

### Utilisation Mémoire/CPU

```bash
docker stats
```

### Espace disque

```bash
df -h
du -sh /root/ragflow/
```

## 🐛 Troubleshooting

### Problème de connexion Ollama

```bash
# Vérifier que le service tourne
docker ps | grep ollama

# Redémarrer
docker restart flowkura-ollama

# Vérifier les logs
docker logs flowkura-ollama
```

### Problème de parsing lent

1. Vérifier l'utilisation GPU : `nvidia-smi`
2. Augmenter `task_page_size` dans la config du dataset
3. Réduire le nombre de workers dans RAGFlow

### Erreur "Out of Memory"

1. Réduire `mem-fraction-static` dans docker-compose-gpu.yml
2. Redémarrer les services
3. Considérer un modèle plus petit (Qwen3-4B ou Qwen3-1.8B)

## 🔐 Sécurité

### Changer le mot de passe admin

1. Se connecter
2. Profile → Change Password

### Désactiver l'enregistrement

Dans `.env` :
```env
RAGFLOW_REGISTER_ENABLED=false
```

### API Key

Générer une clé API : Settings → API Keys → Create

## 📝 Backup

### Backup automatique

```bash
# Créer un script backup
cat > /root/backup-ragflow.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR

# Backup MySQL
docker exec ragflow-mysql mysqldump -uroot -pragflow ragflow > $BACKUP_DIR/ragflow_$DATE.sql

# Backup volumes
tar czf $BACKUP_DIR/es_data_$DATE.tar.gz /root/ragflow/ragflow/docker/es_data
tar czf $BACKUP_DIR/ollama_data_$DATE.tar.gz $(docker volume inspect flowkura-ollama_ollama-data --format '{{ .Mountpoint }}')

# Garder seulement les 7 derniers jours
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /root/backup-ragflow.sh

# Cron quotidien à 2h du matin
(crontab -l 2>/dev/null; echo "0 2 * * * /root/backup-ragflow.sh >> /var/log/ragflow-backup.log 2>&1") | crontab -
```

## 📚 Ressources

- Documentation RAGFlow : https://ragflow.io/docs
- API Reference : https://ragflow.io/docs/api
- GitHub : https://github.com/infiniflow/ragflow
- Ollama : https://ollama.com
- SGLang : https://github.com/sgl-project/sglang

## 🆘 Support

- Email : support@flowkura.com
- GitHub Issues : https://github.com/Flowkura/flowkura-infrastructure/issues
