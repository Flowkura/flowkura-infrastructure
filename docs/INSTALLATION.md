# 📦 Guide d'Installation Flowkura

Guide complet pour réinstaller l'infrastructure Flowkura depuis zéro.

## 🎯 Prérequis

- **Serveur**: Ubuntu 20.04+ avec GPU NVIDIA
- **GPU**: 20GB VRAM minimum (RTX 4000 ou mieux)
- **RAM**: 32GB minimum
- **Stockage**: 500GB SSD minimum
- **Docker**: 24.0+
- **Docker Compose**: 2.0+
- **NVIDIA Container Toolkit**: Installé

## 📋 Étape 1: Installation de base

### 1.1 Cloner RAGFlow

```bash
ssh root@136.243.41.162
cd ~
git clone https://github.com/infiniflow/ragflow.git
cd ragflow
```

### 1.2 Configuration initiale

```bash
cd docker
cp .env.example .env

# Éditer .env
nano .env
```

Valeurs importantes:
```bash
MYSQL_PASSWORD=infini_rag_flow
MINIO_USER=rag_flow
MINIO_PASSWORD=infini_rag_flow
```

## 📋 Étape 2: Optimisations Infrastructure

### 2.1 Optimiser le parsing (8 workers)

Fichier: `ragflow/conf/.env`

```bash
TASK_EXECUTOR_COUNT=8
TASK_EXECUTOR_MAX_CPU=16
TASK_EXECUTOR_MAX_MEM=12G
EMBEDDING_BATCH_SIZE=64
```

### 2.2 Optimiser Redis (4GB cache)

Fichier: `ragflow/docker/docker-compose-base.yml`

Section `redis`:
```yaml
redis:
  command:
    - redis-server
    - --maxmemory
    - 4gb                    # MODIFIER ICI
    - --maxmemory-policy
    - allkeys-lru
```

### 2.3 Optimiser MySQL (8GB buffer)

Fichier: `ragflow/docker/docker-compose-base.yml`

Section `mysql`:
```yaml
mysql:
  command:
    - --max_connections=2000
    - --innodb_buffer_pool_size=8G
    - --innodb_log_file_size=512M
    - --innodb_flush_log_at_trx_commit=2
    - --table_open_cache=4000
    - --tmp_table_size=256M
    - --max_heap_table_size=256M
    - --innodb_io_capacity=2000
    - --innodb_read_io_threads=8
    - --innodb_write_io_threads=8
  deploy:
    resources:
      limits:
        cpus: "4"
        memory: 12G
```

### 2.4 Optimiser Elasticsearch (8GB heap)

Fichier: `ragflow/docker/docker-compose-base.yml`

Section `es01`:
```yaml
es01:
  environment:
    - "ES_JAVA_OPTS=-Xms8g -Xmx8g"
    - indices.memory.index_buffer_size=30%
    - indices.queries.cache.size=15%
    - thread_pool.search.queue_size=2000
    - thread_pool.write.queue_size=1000
    - bootstrap.memory_lock=true
  mem_limit: 16G
  ulimits:
    nofile:
      soft: 65536
      hard: 65536
  deploy:
    resources:
      limits:
        cpus: "6"
        memory: 16G
```

### 2.5 Augmenter upload max (10GB)

Fichier: `ragflow/docker/ragflow-server.yaml`

```yaml
ragflow:
  environment:
    - MAX_CONTENT_LENGTH=10737418240  # 10GB
```

## 📋 Étape 3: Installation LLM

### 3.1 Créer docker-compose-llm.yml

Fichier: `ragflow/docker/docker-compose-llm.yml`

```yaml
version: "3"

networks:
  docker_ragflow:
    external: true

services:
  sglang-qwen3:
    image: lmsysorg/sglang:latest
    container_name: flowkura-sglang-qwen3
    restart: unless-stopped
    networks:
      - docker_ragflow
    ports:
      - "8000:30000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    ipc: host
    command: |
      python3 -m sglang.launch_server \
        --model-path Qwen/Qwen3-8B \
        --port 30000 \
        --host 0.0.0.0

  ollama:
    image: ollama/ollama
    container_name: flowkura-ollama
    restart: unless-stopped
    networks:
      - docker_ragflow
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

volumes:
  ollama_data:
    name: ollama_data
```

### 3.2 Télécharger modèle embeddings

```bash
docker exec flowkura-ollama ollama pull nomic-embed-text
```

## 📋 Étape 4: SSL/HTTPS

### 4.1 Installer Certbot

```bash
apt update
apt install -y certbot python3-certbot-nginx
```

### 4.2 Obtenir certificat

```bash
certbot --nginx -d ragflow.flowkura.com
```

### 4.3 Auto-renew

Créer `/root/renew-ssl.sh`:

```bash
#!/bin/bash
certbot renew --nginx --quiet
docker exec ragflow-server nginx -s reload
```

```bash
chmod +x /root/renew-ssl.sh
crontab -e
```

Ajouter:
```
0 */12 * * * /root/renew-ssl.sh
```

## 📋 Étape 5: Démarrage

### 5.1 Démarrer RAGFlow

```bash
cd ragflow/docker
docker compose up -d
```

### 5.2 Démarrer LLM

```bash
docker compose -f docker-compose-llm.yml up -d
```

### 5.3 Vérifier

```bash
docker ps
nvidia-smi
curl -s http://localhost:8000/v1/models | jq .
```

## 📋 Étape 6: Configuration RAGFlow

### 6.1 Accéder à l'interface

```
https://ragflow.flowkura.com
```

### 6.2 Ajouter le modèle LLM

Settings → Model Providers → Add Model Provider

```
Type: OpenAI-Compatible
Provider Name: SGLang Qwen3
Base URL: http://flowkura-sglang-qwen3:30000/v1
Model: Qwen/Qwen3-8B
API Key: (laisser vide)
Max Context Length: 40960
Max Output Tokens: 4096
```

### 6.3 Vérifier embeddings

Settings → Model Providers

Devrait voir:
```
Ollama
Model: nomic-embed-text
Status: Connected ✅
```

## ✅ Vérification finale

```bash
# Health check complet
./scripts/health-check.sh

# Test génération
curl -X POST "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen3-8B", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'
```

## 🎉 Installation terminée !

Temps total estimé: **30-45 minutes**

Prochaines étapes:
- Créer des datasets
- Uploader des documents
- Parser avec 8 workers (ultra-rapide !)
- Créer des chat assistants
