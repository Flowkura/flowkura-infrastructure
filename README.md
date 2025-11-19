# 🚀 Flowkura Infrastructure

Infrastructure complète pour déployer RAGFlow avec Qwen3-8B et BGE-M3 sur GPU.

## 📋 Prérequis

- Docker et Docker Compose installés
- GPU NVIDIA avec drivers installés
- NVIDIA Container Toolkit configuré
- Token Hugging Face (pour télécharger les modèles)

## 🛠️ Installation Rapide

### 1. Cloner le repository

```bash
git clone https://github.com/Flowkura/flowkura-infrastructure.git
cd flowkura-infrastructure
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
nano .env  # Remplacer your_huggingface_token_here par votre token HF
```

### 3. Créer la structure de dossiers

```bash
mkdir -p ragflow/volumes/{ragflow,nginx}
mkdir -p ollama
```

### 4. Lancer les services

```bash
docker-compose up -d
```

### 5. Télécharger le modèle d'embedding

```bash
docker exec -it ollama ollama pull bge-m3
```

## 📦 Services Déployés

### RAGFlow (Port 9380, 80, 443)
- **Image**: `infiniflow/ragflow:v0.15.0`
- **Fonction**: Interface principale et moteur RAG
- **Accès**: http://localhost:9380

### Ollama (Port 11434)
- **Image**: `ollama/ollama:latest`
- **Modèle**: BGE-M3 (embedding multilingue français)
- **Fonction**: Génération d'embeddings pour la recherche sémantique

### SGLang (Port 8000)
- **Image**: `lmsysorg/sglang:latest`
- **Modèle**: Qwen3-8B
- **Fonction**: Serveur LLM pour la génération de texte

## ⚙️ Configuration dans RAGFlow

### 1. Ajouter Ollama (Embedding)

Dans RAGFlow > Settings > Model Providers:

```
Type: Ollama
Base URL: http://ollama:11434
Model: bge-m3
Type: embedding
```

### 2. Ajouter SGLang (LLM)

Dans RAGFlow > Settings > Model Providers:

```
Type: OpenAI-API-Compatible
Name: VLLM
Base URL: http://sglang:8000/v1
API Key: EMPTY
Model: Qwen3-8B
Type: chat
Max Tokens: 8192
```

### 3. Configurer vos Datasets

Pour chaque dataset:
1. Aller dans Knowledge Base > Votre Dataset > Settings
2. Embedding Model: `bge-m3@Ollama`
3. Chunk Method: `naive` (General)
4. Chunk Token Count: `512` (ou selon vos besoins)

## 🔧 Commandes Utiles

### Vérifier les logs
```bash
docker-compose logs -f ragflow    # Logs RAGFlow
docker-compose logs -f ollama     # Logs Ollama
docker-compose logs -f sglang     # Logs SGLang
```

### Redémarrer un service
```bash
docker-compose restart ragflow
docker-compose restart ollama
docker-compose restart sglang
```

### Arrêter tous les services
```bash
docker-compose down
```

### Supprimer tout (⚠️ ATTENTION: supprime les données)
```bash
docker-compose down -v
```

### Vérifier le modèle Ollama
```bash
docker exec -it ollama ollama list
```

### Tester l'embedding Ollama
```bash
curl http://localhost:11434/api/embeddings \
  -d '{"model": "bge-m3", "prompt": "Bonjour le monde"}'
```

### Tester SGLang
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen3-8B",
    "messages": [{"role": "user", "content": "Bonjour!"}],
    "max_tokens": 100
  }'
```

## 📊 Optimisations Appliquées

### Base de données (Redis + MySQL + Elasticsearch)
- Configuration optimisée pour GPU
- Augmentation des buffers et cache
- Pooling optimisé

### RAGFlow
- GPU activé (`CPUONLY=0`)
- Max tokens augmenté (8192)
- Registration désactivée

### SGLang
- `mem-fraction-static 0.85` : Utilisation optimale de la VRAM
- `trust-remote-code` : Support complet de Qwen3

## 🔐 Sécurité

- Le `.env` est dans `.gitignore` (ne jamais commit les tokens)
- Utilisez `.env.example` comme template
- Changez les ports si nécessaire pour votre infrastructure

## 🐛 Troubleshooting

### RAGFlow ne démarre pas
```bash
docker-compose logs ragflow
# Vérifier que le GPU est bien détecté
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### Ollama ne télécharge pas le modèle
```bash
# Vérifier l'espace disque
df -h
# Télécharger manuellement
docker exec -it ollama ollama pull bge-m3
```

### SGLang out of memory
```bash
# Réduire mem-fraction-static dans docker-compose.yml
# De 0.85 à 0.7 par exemple
```

## 📈 Performance

- **Parsing**: ~500-1000 documents/heure (selon complexité)
- **Embedding**: ~100 chunks/seconde
- **Génération**: ~20-30 tokens/seconde

## 🆘 Support

- GitHub Issues: [https://github.com/Flowkura/flowkura-infrastructure/issues](https://github.com/Flowkura/flowkura-infrastructure/issues)
- Documentation RAGFlow: [https://ragflow.io/docs](https://ragflow.io/docs)

## 📝 License

MIT
