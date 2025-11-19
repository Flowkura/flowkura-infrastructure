# 📦 GUIDE DE DÉPLOIEMENT COMPLET - Flowkura

**Ce guide permet à N'IMPORTE QUI de redéployer Flowkura depuis zéro.**

Temps estimé : **45-60 minutes**

---

## 🎯 OBJECTIF

À la fin de ce guide, vous aurez :
- ✅ RAGFlow fonctionnel avec HTTPS
- ✅ SGLang + Qwen3-8B (LLM)
- ✅ Ollama + nomic-embed-text (embeddings)
- ✅ Bases de données optimisées
- ✅ 8 workers de parsing
- ✅ SSL auto-renew

---

## 📋 PRÉREQUIS

### Serveur
- Ubuntu 20.04+ avec GPU NVIDIA
- 20GB VRAM minimum (RTX 4000 ou mieux)
- 32GB RAM
- 500GB SSD
- Accès root SSH

### Logiciels
- Docker 24.0+
- Docker Compose 2.0+
- NVIDIA Container Toolkit
- Certbot (pour SSL)

### Domaine
- Un domaine pointant vers votre serveur (ex: ragflow.flowkura.com)
- Ports 80 et 443 ouverts

---

## 🚀 PARTIE 1 : INSTALLATION DE BASE

### Étape 1.1 : Connexion au serveur

```bash
ssh root@136.243.41.162
```

### Étape 1.2 : Cloner RAGFlow

```bash
cd ~
git clone https://github.com/infiniflow/ragflow.git
cd ragflow
```

### Étape 1.3 : Copier les configurations depuis ce repository

**Sur votre machine locale** :

```bash
cd ~/Workspace/Flowkura/flowkura-infrastructure

# Copier docker-compose optimisé
scp ragflow-docker/docker-compose-base.yml root@136.243.41.162:/root/ragflow/docker/

# Copier .env production
scp ragflow-docker/.env.production root@136.243.41.162:/root/ragflow/docker/.env

# Copier configs nginx
scp nginx/ragflow.https.conf root@136.243.41.162:/root/ragflow/docker/nginx/
```

**Pourquoi ?** Ces fichiers contiennent déjà toutes les optimisations (8 workers, Redis 4GB, MySQL 8GB, etc.)

---

## 🔧 PARTIE 2 : CONFIGURATION OPTIMISÉE

### Étape 2.1 : Vérifier le fichier .env

```bash
ssh root@136.243.41.162
cd /root/ragflow/docker
cat .env
```

Doit contenir :
```bash
# PARSING OPTIMISÉ
TASK_EXECUTOR_COUNT=8
TASK_EXECUTOR_MAX_CPU=16
TASK_EXECUTOR_MAX_MEM=12G
EMBEDDING_BATCH_SIZE=64

# MYSQL
MYSQL_PASSWORD=infini_rag_flow
MYSQL_PORT=5455

# MINIO
MINIO_USER=rag_flow
MINIO_PASSWORD=infini_rag_flow

# UPLOAD
MAX_CONTENT_LENGTH=10737418240
```

### Étape 2.2 : Vérifier docker-compose-base.yml

Les optimisations importantes :

**Redis (4GB cache)** :
```yaml
redis:
  command:
    - redis-server
    - --maxmemory
    - 4gb
    - --maxmemory-policy
    - allkeys-lru
```

**MySQL (8GB buffer)** :
```yaml
mysql:
  command:
    - --innodb_buffer_pool_size=8G
    - --max_connections=2000
    # ... autres optimisations
```

**Elasticsearch (8GB heap)** :
```yaml
es01:
  environment:
    - "ES_JAVA_OPTS=-Xms8g -Xmx8g"
  mem_limit: 16G
```

---

## 🐳 PARTIE 3 : DÉMARRAGE DES SERVICES

### Étape 3.1 : Démarrer RAGFlow

```bash
cd /root/ragflow/docker
docker compose up -d
```

**Attendre 2-3 minutes** que tous les services démarrent.

### Étape 3.2 : Vérifier les containers

```bash
docker ps
```

Vous devez voir :
- ragflow-server
- ragflow-mysql
- ragflow-redis
- ragflow-es-01
- ragflow-minio

### Étape 3.3 : Vérifier les logs

```bash
docker logs ragflow-server
```

Doit afficher "Server started" ou similaire.

---

## 🔒 PARTIE 4 : CONFIGURATION SSL/HTTPS

### Étape 4.1 : Installer Certbot

```bash
apt update
apt install -y certbot python3-certbot-nginx
```

### Étape 4.2 : Obtenir le certificat

```bash
certbot --nginx -d ragflow.flowkura.com
```

Répondre aux questions :
- Email : votre email
- Accepter les termes : Yes (Y)
- Redirect HTTP to HTTPS : Yes (Y)

### Étape 4.3 : Créer le script auto-renew

```bash
cat > /root/renew-ssl.sh << 'EOF'
#!/bin/bash
certbot renew --nginx --quiet
docker exec ragflow-server nginx -s reload
EOF

chmod +x /root/renew-ssl.sh
```

### Étape 4.4 : Ajouter au cron

```bash
crontab -e
```

Ajouter cette ligne :
```
0 */12 * * * /root/renew-ssl.sh
```

### Étape 4.5 : Tester l'accès HTTPS

```bash
curl -I https://ragflow.flowkura.com
```

Doit retourner `200 OK` ou `302 Found`.

---

## 🤖 PARTIE 5 : INSTALLATION LLM (SGLang + Qwen3)

### Étape 5.1 : Copier docker-compose-llm.yml

**Sur votre machine locale** :

```bash
scp ~/Workspace/Flowkura/flowkura-infrastructure/docker/docker-compose-llm.yml \
  root@136.243.41.162:/root/ragflow/docker/
```

### Étape 5.2 : Démarrer les services LLM

```bash
ssh root@136.243.41.162
cd /root/ragflow/docker
docker compose -f docker-compose-llm.yml up -d
```

### Étape 5.3 : Attendre le téléchargement du modèle

**Première fois : ~15-20 minutes** (Qwen3-8B = 17GB)

Suivre la progression :
```bash
docker logs -f flowkura-sglang-qwen3
```

Vous verrez : "Downloading model..." puis "Model loaded"

### Étape 5.4 : Télécharger le modèle d'embeddings

```bash
docker exec flowkura-ollama ollama pull nomic-embed-text
```

~2 minutes (274MB)

### Étape 5.5 : Vérifier que tout fonctionne

```bash
# Test SGLang
curl -s http://localhost:8000/v1/models | jq .

# Test Ollama
curl -s http://localhost:11434/api/tags | jq .

# Vérifier VRAM
nvidia-smi
```

Doit afficher :
- SGLang : ~17.3GB VRAM
- Ollama : ~300MB VRAM

---

## ⚙️ PARTIE 6 : CONFIGURATION RAGFLOW

### Étape 6.1 : Accéder à l'interface

Aller sur : `https://ragflow.flowkura.com`

### Étape 6.2 : Créer un compte admin

Premier utilisateur = admin automatiquement.

### Étape 6.3 : Configurer le modèle LLM

1. Aller dans **Settings** → **Model Providers**
2. Cliquer **+ Add Model Provider**
3. Sélectionner **OpenAI-Compatible**
4. Remplir :

```
Provider Name: SGLang Qwen3
Base URL: http://flowkura-sglang-qwen3:30000/v1
API Key: (laisser vide)
Model Name: Qwen/Qwen3-8B
Max Context Length: 40960
Max Output Tokens: 4096
Temperature: 0.6
Top P: 0.95
```

5. Cliquer **Test Connection** → Doit dire "Success"
6. Cliquer **Save**

### Étape 6.4 : Vérifier le modèle d'embeddings

1. Aller dans **Settings** → **Model Providers**
2. Vous devez voir automatiquement :

```
Provider: Ollama
Model: nomic-embed-text
Status: Connected ✅
```

Si non visible, ajouter manuellement :
- Type : Ollama
- Base URL : `http://flowkura-ollama:11434`
- Model : `nomic-embed-text`

### Étape 6.5 : Définir les modèles par défaut

1. **Settings** → **System Settings**
2. Sélectionner :
   - **Default Chat Model** : Qwen/Qwen3-8B (SGLang Qwen3)
   - **Default Embedding Model** : nomic-embed-text (Ollama)
3. **Save**

---

## ✅ PARTIE 7 : VÉRIFICATION FINALE

### Test 1 : Health check complet

```bash
cd ~/Workspace/Flowkura/flowkura-infrastructure
./scripts/health-check.sh
```

Tout doit être ✅ vert.

### Test 2 : Créer un dataset

1. Dans RAGFlow : **Knowledge Base** → **+ Create**
2. Nom : "Test"
3. Embedding Model : nomic-embed-text
4. Créer

### Test 3 : Upload un fichier

1. Ouvrir le dataset "Test"
2. Cliquer **Upload**
3. Uploader un fichier texte
4. Cliquer **Parse**

Doit parser en ~1-2 secondes avec 8 workers.

### Test 4 : Créer un chat assistant

1. **Chat Assistants** → **+ Create**
2. Nom : "Test Assistant"
3. Sélectionner dataset "Test"
4. LLM : Qwen/Qwen3-8B
5. Créer

### Test 5 : Tester la génération

1. Ouvrir le chat assistant
2. Poser une question : "Bonjour, qui es-tu ?"
3. Doit répondre en français avec contexte du dataset

---

## 🎉 DÉPLOIEMENT TERMINÉ !

Vous avez maintenant :
- ✅ RAGFlow avec HTTPS
- ✅ LLM moderne (Qwen3-8B)
- ✅ Embeddings performants
- ✅ 8 workers de parsing (ultra-rapide)
- ✅ Bases de données optimisées
- ✅ SSL auto-renew

---

## 📊 UTILISATION RESSOURCES

```
GPU: NVIDIA RTX 4000 Ada (20GB)
├── SGLang (Qwen3-8B): 17.3 GB
├── Ollama (embeddings): 0.3 GB
└── Libre: 2.4 GB

RAM: 32GB
├── Elasticsearch: 8 GB
├── MySQL: 8 GB
├── RAGFlow: 4 GB
└── Système: 12 GB

Disque:
├── Modèles LLM: ~20 GB
├── Base de données: Variable
└── Documents uploadés: Variable
```

---

## 🔄 PROCHAINES ÉTAPES

1. **Backup** : `./scripts/backup.sh`
2. **Monitoring** : Configurer alertes
3. **Documentation** : Ajouter vos procédures spécifiques
4. **Tests** : Tester avec vrais datasets

---

## 🆘 EN CAS DE PROBLÈME

Voir [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)

---

**Guide créé le** : 19 novembre 2025  
**Version** : 2.0  
**Testé sur** : Ubuntu 22.04 LTS + RTX 4000 Ada
