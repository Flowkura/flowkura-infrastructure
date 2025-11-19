# 🚀 Flowkura Infrastructure

Infrastructure complète pour déployer RAGFlow avec SGLang (Qwen3-8B) et Ollama (bge-m3).

## 📋 Prérequis

- Ubuntu 22.04+ avec Docker et Docker Compose
- GPU NVIDIA avec drivers + NVIDIA Container Toolkit
- Domaine pointant vers le serveur (pour Traefik + Let's Encrypt)
- 32GB+ RAM recommandé

## 🔧 Installation Rapide

### 1. Sur le serveur

```bash
git clone https://github.com/Flowkura/flowkura-infrastructure.git
cd flowkura-infrastructure/ragflow
```

### 2. Configuration

Créer le fichier `.env` (copier depuis `.env` existant ou créer) :

```env
# RAGFlow Core
SECRET_KEY=infiniflowinfiniflow
MYSQL_PASSWORD=infiniflow
TIMEZONE=Europe/Paris
SVR_HTTP_PORT=80

# Hugging Face (pour téléchargement des modèles)
HF_ENDPOINT=https://hf-mirror.com
HUGGING_FACE_HUB_TOKEN=votre_token_ici

# Désactiver l'enregistrement
REGISTRATION_ENABLED=False
```

### 3. Démarrer les services

```bash
docker compose -f docker-compose-gpu.yml up -d
```

### 4. Télécharger les modèles

#### Ollama - bge-m3 (Embedding)
```bash
docker exec -it ollama-bge-m3 ollama pull bge-m3
```

#### SGLang - Qwen3-8B (LLM)
Le modèle se télécharge automatiquement au premier démarrage.

### 5. Configuration RAGFlow

1. Accéder à `http://votre-ip`
2. Se connecter avec le compte créé
3. **Settings** → **Model Providers** → Ajouter :

**LLM - SGLang (Qwen3-8B)** :
```
Factory: VLLM
Base URL: http://sglang-qwen3:8000/v1
Model name: Qwen/Qwen3-8B
Max tokens: 8192
```

**Embedding - Ollama (bge-m3)** :
```
Factory: Ollama
Base URL: http://ollama-bge-m3:11434
Model name: bge-m3
```

## 🏗️ Architecture

```
ragflow/
├── docker-compose-gpu.yml    # Configuration principale GPU
├── .env                      # Variables d'environnement
├── conf/                     # Configs RAGFlow
│   ├── service_conf.yaml
│   └── .env
└── volumes/                  # Données persistantes
    ├── mysql/
    ├── redis/
    ├── es/
    └── minio/
```

## 📊 Services

| Service | Port | GPU | Description |
|---------|------|-----|-------------|
| **ragflow** | 80 | ✅ | Interface web + API |
| **sglang-qwen3** | 8000 | ✅ | LLM (Qwen3-8B) |
| **ollama-bge-m3** | 11434 | ✅ | Embedding (bge-m3) |
| mysql | 3306 | ❌ | Base de données |
| redis | 6379 | ❌ | Cache |
| elasticsearch | 9200 | ❌ | Moteur de recherche |
| minio | 9001 | ❌ | Stockage S3 |

## 🔄 Commandes Essentielles

```bash
# Démarrer
docker compose -f docker-compose-gpu.yml up -d

# Arrêter
docker compose -f docker-compose-gpu.yml down

# Logs
docker compose -f docker-compose-gpu.yml logs -f ragflow
docker compose -f docker-compose-gpu.yml logs -f sglang-qwen3

# Redémarrer un service
docker compose -f docker-compose-gpu.yml restart ragflow

# Status
docker compose -f docker-compose-gpu.yml ps
```

## ⚙️ Optimisations Appliquées

### MySQL (4GB RAM alloué)
```yaml
innodb_buffer_pool_size: 4G
max_connections: 500
query_cache_size: 128M
```

### Redis (2GB RAM alloué)
```yaml
maxmemory: 2gb
maxmemory-policy: allkeys-lru
```

### Elasticsearch (4GB heap)
```yaml
ES_JAVA_OPTS: "-Xms4g -Xmx4g"
```

### RAGFlow Parsing
```python
# Configuration optimale des datasets
{
    "chunk_token_num": 512,
    "task_page_size": 24,  # 2x la valeur par défaut
    "delimiter": "\\n!?;。；！？"
}
```

## 🐛 Dépannage

### Modèle non accessible
```bash
# Vérifier SGLang
curl http://localhost:8000/v1/models

# Vérifier Ollama
docker exec ollama-bge-m3 ollama list
```

### Parsing lent
- Augmenter `task_page_size` à 24+ dans la config du dataset
- Vérifier GPU : `nvidia-smi`

### Out of Memory
- Réduire `max_tokens` dans la config du modèle
- Limiter les requêtes parallèles

## 📦 Maintenance

### Backup
```bash
# MySQL
docker exec ragflow-mysql mysqldump -uroot -pinfiniflow rag > backup.sql

# Volumes
docker run --rm -v ragflow_mysql:/data -v $(pwd):/backup alpine tar czf /backup/mysql.tar.gz /data
```

### Mise à jour
```bash
git pull
docker compose -f docker-compose-gpu.yml pull
docker compose -f docker-compose-gpu.yml up -d
```

## 🔐 Sécurité

⚠️ **Avant mise en production** :
1. Changer `SECRET_KEY` et `MYSQL_PASSWORD` dans `.env`
2. Configurer Traefik + Let's Encrypt
3. Activer le firewall
4. Limiter l'accès SSH

## 🤝 Support

- Issues : [GitHub Issues](https://github.com/Flowkura/flowkura-infrastructure/issues)
- RAGFlow Docs : [ragflow.io/docs](https://ragflow.io/docs)
- SGLang Docs : [sgl-project.github.io](https://sgl-project.github.io)

## 📜 Licence

MIT - Voir LICENSE
