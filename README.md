# 🚀 Flowkura Infrastructure - RAGFlow Production

Infrastructure complète pour déployer RAGFlow en production avec SGLang, Ollama et Traefik.

## 📋 Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation rapide](#installation-rapide)
- [Configuration](#configuration)
- [Services](#services)
- [Modèles utilisés](#modèles-utilisés)
- [Commandes utiles](#commandes-utiles)
- [Troubleshooting](#troubleshooting)
- [Optimisations](#optimisations)

---

## 🏗️ Architecture

\`\`\`
┌─────────────────────────────────────────────┐
│           Internet (HTTPS)                  │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│      Traefik Reverse Proxy (443/80)        │
│    SSL via Let's Encrypt                   │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│           RAGFlow Server                    │
│       (ragflow.flowkura.com)                │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
┌──────▼──────┐ ┌─▼─────┐ ┌──▼─────┐
│  SGLang     │ │Ollama │ │ MySQL  │
│  Qwen3-8B   │ │bge-m3 │ │ Redis  │
│  (Chat LLM) │ │(Embed)│ │ ES     │
└─────────────┘ └───────┘ └────────┘
\`\`\`

---

## ⚙️ Prérequis

### Matériel
- **GPU NVIDIA** (minimum 24GB VRAM recommandé pour Qwen3-8B)
- **RAM** : 32GB minimum
- **Stockage** : 100GB minimum

### Logiciels
- Ubuntu 22.04 LTS
- Docker 24.0+
- Docker Compose V2
- NVIDIA Docker Runtime
- Git

---

## 🚀 Installation rapide

### 1. Clone du repository

\`\`\`bash
cd /root
git clone https://github.com/Flowkura/infrastructure.git flowkura-infrastructure
cd flowkura-infrastructure/ragflow/docker
\`\`\`

### 2. Configuration de l'environnement

\`\`\`bash
# Le fichier .env est déjà configuré
# Modifier les variables si nécessaire
nano .env
\`\`\`

**Variables importantes :**
\`\`\`bash
# Domaine
RAGFLOW_DOMAIN=ragflow.flowkura.com

# Email pour Let's Encrypt
ACME_EMAIL=contact.lenne@gmail.com

# Désactiver l'inscription
ENABLE_REGISTER=false

# Mot de passe MySQL/Redis
MYSQL_PASSWORD=infini_rag_flow
REDIS_PASSWORD=infini_rag_flow
\`\`\`

### 3. Téléchargement des modèles

**Sur le serveur :**

\`\`\`bash
# 1. Lancer Ollama temporairement
docker run -d --name ollama-temp \\
  --gpus all \\
  -v ~/.ollama:/root/.ollama \\
  ollama/ollama:latest

# 2. Télécharger bge-m3 (embedding)
docker exec ollama-temp ollama pull bge-m3

# 3. Arrêter et supprimer le container temporaire
docker stop ollama-temp && docker rm ollama-temp
\`\`\`

### 4. Lancement de l'infrastructure

\`\`\`bash
cd /root/flowkura-infrastructure/ragflow/docker

# Lancer tous les services
docker compose -f docker-compose-gpu.yml up -d

# Vérifier que tout est UP
docker compose -f docker-compose-gpu.yml ps
\`\`\`

### 5. Configuration initiale RAGFlow

Accéder à : \`https://ragflow.flowkura.com\`

1. **Se connecter** avec les credentials existants
2. **Les modèles sont déjà configurés** :
   - **SGLang/Qwen3-8B** : Chat LLM
   - **Ollama/bge-m3** : Embedding

3. **Les datasets sont prêts** :
   - Fiches Métiers ONISEP
   - Fiches Formations ONISEP

---

## 🔧 Configuration

### Fichiers principaux

\`\`\`
ragflow/
├── docker/
│   ├── docker-compose-gpu.yml    # Compose principal GPU
│   ├── docker-compose-base.yml   # Services de base
│   ├── .env                      # Variables d'environnement
│   ├── nginx/
│   │   └── ragflow.conf          # Config Nginx
│   └── ragflow-logs/             # Logs des tâches
└── README.md                     # Cette documentation
\`\`\`

### docker-compose-gpu.yml

Services inclus :
- \`ragflow\` : Serveur principal RAGFlow
- \`mysql\` : Base de données
- \`redis\` : Cache et file de tâches
- \`es01\` : Elasticsearch (indexation)
- \`minio\` : Stockage S3
- \`sglang-qwen3\` : LLM de chat (Qwen3-8B)
- \`ollama-bge-m3\` : Modèle d'embedding

---

## 📦 Services

### RAGFlow Server
- **Ports** : 80 (HTTP), 443 (HTTPS via Nginx interne)
- **Image** : \`infiniflow/ragflow:latest-slim\`
- **GPU** : Activé
- **Restart** : \`unless-stopped\`

### SGLang (Chat LLM)
- **Port** : 30000
- **Modèle** : \`Qwen/Qwen3-8B\`
- **VRAM** : ~16GB
- **URL interne** : \`http://sglang-qwen3:30000/v1\`

### Ollama (Embedding)
- **Port** : 11434
- **Modèle** : \`bge-m3\`
- **VRAM** : ~2GB
- **URL interne** : \`http://ollama-bge-m3:11434\`

### MySQL
- **Port** : 5455
- **User** : \`root\`
- **Password** : \`infini_rag_flow\` (voir \`.env\`)
- **Database** : \`rag_flow\`

### Redis
- **Port** : 6379
- **Password** : \`infini_rag_flow\` (voir \`.env\`)

### Elasticsearch
- **Port** : 1200
- **Version** : 8.11.3
- **Index** : Chunks et documents

### MinIO (S3)
- **Console** : 9001
- **API** : 9000
- **Access Key** : voir \`.env\`

---

## 🤖 Modèles utilisés

### 1. **Qwen3-8B** (Chat LLM)
- **Provider** : Alibaba Cloud (Qwen Team)
- **Taille** : 8 milliards de paramètres
- **Langue** : Multilingue (excellent en français)
- **Use case** : Génération de réponses RAG
- **VRAM** : ~16GB
- **Format** : FP16

### 2. **bge-m3** (Embedding)
- **Provider** : BAAI (Beijing Academy of AI)
- **Dimensions** : 1024
- **Langue** : Multilingue (128 langues)
- **Use case** : Vectorisation de documents
- **VRAM** : ~2GB
- **Max tokens** : 8192

---

## 🛠️ Commandes utiles

### Gestion des services

\`\`\`bash
# Démarrer tous les services
docker compose -f docker-compose-gpu.yml up -d

# Arrêter tous les services
docker compose -f docker-compose-gpu.yml down

# Redémarrer RAGFlow uniquement
docker compose -f docker-compose-gpu.yml restart ragflow

# Voir les logs
docker compose -f docker-compose-gpu.yml logs -f ragflow

# Voir l'utilisation GPU
watch -n 1 nvidia-smi
\`\`\`

### Gestion des modèles

\`\`\`bash
# Télécharger un nouveau modèle dans Ollama
docker exec ollama-bge-m3 ollama pull <model-name>

# Lister les modèles Ollama
docker exec ollama-bge-m3 ollama list

# Tester SGLang
curl -X POST http://localhost:30000/v1/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "Qwen/Qwen3-8B",
    "messages": [{"role": "user", "content": "Bonjour!"}]
  }'
\`\`\`

### Debugging

\`\`\`bash
# Entrer dans le container RAGFlow
docker exec -it ragflow-server bash

# Vérifier Redis (arrêter le parsing bloqué)
docker exec ragflow-redis redis-cli -a infini_rag_flow FLUSHALL

# Vérifier MySQL
docker exec -it ragflow-mysql mysql -uroot -pinfini_rag_flow rag_flow

# Vérifier Elasticsearch
curl -X GET "http://localhost:1200/_cat/indices?v"
\`\`\`

### Maintenance

\`\`\`bash
# Nettoyer les logs
rm -rf /root/flowkura-infrastructure/ragflow/docker/ragflow-logs/*

# Backup de la base de données
docker exec ragflow-mysql mysqldump -uroot -pinfini_rag_flow rag_flow > backup.sql

# Restaurer la base
docker exec -i ragflow-mysql mysql -uroot -pinfini_rag_flow rag_flow < backup.sql
\`\`\`

---

## �� Troubleshooting

### Problème : Parsing bloqué

**Solution :**
\`\`\`bash
# Flusher Redis
docker exec ragflow-redis redis-cli -a infini_rag_flow FLUSHALL

# Redémarrer RAGFlow
docker compose -f docker-compose-gpu.yml restart ragflow
\`\`\`

### Problème : Out of Memory (GPU)

**Solutions :**
1. Utiliser un modèle plus petit : \`Qwen3-4B\` au lieu de \`Qwen3-8B\`
2. Activer le chunked prefill dans SGLang
3. Réduire \`max_total_tokens\` dans SGLang

### Problème : Connexion refusée aux modèles

**Vérifier :**
\`\`\`bash
# SGLang est accessible ?
curl http://localhost:30000/health

# Ollama est accessible ?
curl http://localhost:11434/api/version

# Les containers sont sur le même réseau ?
docker network inspect ragflow_ragflow
\`\`\`

### Problème : SSL/HTTPS ne fonctionne pas

**Vérifier :**
1. Le domaine pointe bien vers le serveur
2. Les ports 80/443 sont ouverts
3. Les certificats Let's Encrypt sont dans \`/root/flowkura-infrastructure/ragflow/docker/nginx/ssl/\`

---

## ⚡ Optimisations

### 1. Base de données (déjà appliquées)

**MySQL** :
\`\`\`ini
innodb_buffer_pool_size = 4G
innodb_log_file_size = 512M
max_connections = 500
\`\`\`

**Redis** :
\`\`\`ini
maxmemory = 4gb
maxmemory-policy = allkeys-lru
\`\`\`

### 2. Parsing plus rapide

**Chunking optimisé** :
- \`chunk_token_num\` : 512 (bon équilibre)
- \`task_page_size\` : 12 (parallélisme PDF)
- \`layout_recognize\` : DeepDOC (précis)

**Parser par type de document** :
- PDF : \`naive\` ou \`paper\`
- Markdown : \`naive\`
- Excel : Activer \`html4excel\`

### 3. Requêtes RAG optimisées

**Paramètres recommandés** :
\`\`\`json
{
  "similarity_threshold": 0.2,
  "vector_similarity_weight": 0.3,
  "top_n": 6,
  "top_k": 1024
}
\`\`\`

---

## 📚 Ressources

- [RAGFlow Documentation](https://ragflow.io/docs)
- [SGLang Documentation](https://sgl-project.github.io/)
- [Ollama Models](https://ollama.com/library)
- [Qwen3 Model Card](https://huggingface.co/Qwen/Qwen3-8B)
- [BGE-M3 Model Card](https://huggingface.co/BAAI/bge-m3)

---

## 🤝 Support

Pour toute question ou problème :
1. Vérifier les logs : \`docker compose logs -f\`
2. Consulter cette documentation
3. Contacter l'équipe Flowkura

---

## 📝 Licence

Propriété de **Flowkura** - Tous droits réservés.

---

**Dernière mise à jour** : 19 novembre 2025
