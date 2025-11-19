# 🚀 Flowkura RAGFlow - Guide de Déploiement

## 📋 Prérequis

- Ubuntu 22.04 LTS
- Docker & Docker Compose V2
- NVIDIA GPU avec drivers + nvidia-container-toolkit
- 32 GB RAM minimum
- 100 GB espace disque

## 🔧 Installation Initiale

### 1. Cloner le repository

```bash
cd /root
git clone https://github.com/Flowkura/flowkura-infrastructure.git
cd flowkura-infrastructure/ragflow/docker
```

### 2. Configurer les variables d'environnement

Copier le fichier `.env` et ajuster les valeurs :

```bash
cp .env .env.local
nano .env
```

Variables importantes :
- `HF_TOKEN` : Token Hugging Face
- `TIMEZONE` : Europe/Paris
- `RAGFLOW_IMAGE` : infiniflow/ragflow:latest (GPU version)

### 3. Première installation

```bash
# Lancer tous les services
docker compose -f docker-compose-gpu.yml up -d

# Vérifier que tout tourne
docker compose -f docker-compose-gpu.yml ps

# Suivre les logs
docker compose -f docker-compose-gpu.yml logs -f
```

### 4. Télécharger le modèle d'embedding dans Ollama

```bash
# Entrer dans le container Ollama
docker exec -it flowkura-ollama ollama pull bge-m3

# Vérifier
docker exec -it flowkura-ollama ollama list
```

## 🔄 Opérations Courantes

### Redémarrer tous les services

```bash
cd /root/flowkura-infrastructure/ragflow/docker
docker compose -f docker-compose-gpu.yml restart
```

### Redémarrer un service spécifique

```bash
# RAGFlow uniquement
docker compose -f docker-compose-gpu.yml restart ragflow

# SGLang LLM uniquement
docker compose -f docker-compose-gpu.yml restart sglang-qwen3

# Ollama uniquement
docker compose -f docker-compose-gpu.yml restart ollama
```

### Voir les logs

```bash
# Tous les services
docker compose -f docker-compose-gpu.yml logs -f

# Service spécifique
docker compose -f docker-compose-gpu.yml logs -f ragflow
docker compose -f docker-compose-gpu.yml logs -f sglang-qwen3
docker compose -f docker-compose-gpu.yml logs -f ollama
```

### Arrêter les services

```bash
# Arrêt complet
docker compose -f docker-compose-gpu.yml down

# Arrêt avec suppression des volumes (⚠️ ATTENTION : perte de données)
docker compose -f docker-compose-gpu.yml down -v
```

## 🎯 Architecture des Services

### Services principaux

1. **RAGFlow** (Port 9380, 8081)
   - Interface web principale
   - API REST
   - GPU : Partagé avec tous les services

2. **MySQL** (Port 3306)
   - Base de données principale
   - Stockage des métadonnées

3. **Elasticsearch** (Port 9200)
   - Index de recherche
   - Stockage des embeddings

4. **Redis** (Port 6379)
   - Cache
   - Queue de tâches

5. **SGLang - Qwen3-8B** (Port 30000)
   - Modèle LLM principal
   - API compatible OpenAI
   - GPU : 70% VRAM

6. **Ollama - BGE-M3** (Port 11434)
   - Modèle d'embedding multilingue
   - Optimisé pour le français
   - GPU : Partagé

### Répartition GPU

- **SGLang (Qwen3-8B)** : ~70% VRAM (18-20 GB)
- **Ollama (BGE-M3)** : ~20% VRAM (4-5 GB)
- **RAGFlow parsers** : ~10% VRAM (2-3 GB)

## 🔐 Configuration RAGFlow

### 1. Premier accès

- URL : `http://[IP_SERVEUR]:9380`
- Créer un compte admin

### 2. Configurer les modèles

Dans RAGFlow > Settings > Model Providers :

#### LLM (SGLang - Qwen3-8B)
- **Type** : VLLM
- **Model Name** : Qwen/Qwen3-8B
- **Base URL** : http://sglang-qwen3:30000/v1
- **API Key** : (laisser vide)
- **Max Tokens** : 8192

#### Embedding (Ollama - BGE-M3)
- **Type** : Ollama
- **Model Name** : bge-m3
- **Base URL** : http://ollama:11434
- **API Key** : (laisser vide)

### 3. Créer un Dataset

- Aller dans Datasets > Create
- Nom : Ex. "Fiches Métiers ONISEP"
- Embedding Model : **bge-m3@Ollama**
- Chunk Method : **naive**
- Parser Config :
  ```json
  {
    "chunk_token_num": 512,
    "delimiter": "\\n!?。",
    "layout_recognize": "DeepDOC",
    "raptor": {"use_raptor": false},
    "graphrag": {"use_graphrag": false}
  }
  ```

### 4. Upload et Parser des documents

```bash
# Depuis la machine locale
cd ~/Workspace/Flowkura/llm
python upload_to_ragflow.py
```

## 🔍 Monitoring & Debug

### Vérifier la santé des services

```bash
# Status de tous les containers
docker compose -f docker-compose-gpu.yml ps

# Utilisation GPU
nvidia-smi

# Espace disque
df -h

# Mémoire RAM
free -h
```

### Logs importants

```bash
# RAGFlow logs
tail -f /root/flowkura-infrastructure/ragflow/docker/ragflow-logs/api.log

# MySQL logs
docker compose -f docker-compose-gpu.yml logs mysql | tail -100

# Elasticsearch logs
docker compose -f docker-compose-gpu.yml logs es01 | tail -100
```

### Problèmes courants

#### SGLang ne démarre pas
```bash
# Vérifier la VRAM disponible
nvidia-smi

# Réduire mem-fraction-static dans docker-compose-gpu.yml si nécessaire
```

#### Ollama model non trouvé
```bash
# Re-télécharger le modèle
docker exec -it flowkura-ollama ollama pull bge-m3
```

#### RAGFlow : Connection Error aux models
```bash
# Vérifier que les services sont sur le même network
docker network inspect ragflow_ragflow

# Redémarrer RAGFlow
docker compose -f docker-compose-gpu.yml restart ragflow
```

## 📊 Optimisations Base de Données

Les optimisations suivantes sont déjà configurées dans `.env` :

### MySQL
- `innodb_buffer_pool_size=8G` : Cache des données
- `innodb_log_file_size=1G` : Taille des logs
- `max_connections=500` : Connexions simultanées

### Elasticsearch
- Heap size : 4GB (ES_JAVA_OPTS)
- Indices shards : 1 shard par défaut

### Redis
- `maxmemory=4gb`
- `maxmemory-policy=allkeys-lru`

## 🔄 Mise à Jour

```bash
cd /root/flowkura-infrastructure/ragflow/docker

# Pull dernières images
docker compose -f docker-compose-gpu.yml pull

# Redémarrer
docker compose -f docker-compose-gpu.yml up -d

# Vérifier
docker compose -f docker-compose-gpu.yml ps
```

## 🆘 Support

- Documentation RAGFlow : https://ragflow.io/docs
- GitHub Issues : https://github.com/Flowkura/flowkura-infrastructure/issues

## 📝 Changelog

### 2025-11-19
- ✅ Optimisations MySQL, Elasticsearch, Redis
- ✅ Migration de vLLM vers SGLang pour Qwen3-8B
- ✅ Ajout Ollama pour BGE-M3 (embedding multilingue)
- ✅ Configuration GPU optimisée
- ✅ Documentation complète

---

**Flowkura Team** - Powered by RAGFlow + SGLang + Ollama
