# 🚀 Flowkura Infrastructure

Documentation complète et scripts de maintenance pour l'infrastructure Flowkura RAGFlow optimisée.

## 📊 Vue d'ensemble

- **Serveur** : root@136.243.41.162
- **GPU** : NVIDIA RTX 4000 SFF Ada Generation (20GB VRAM)
- **Services** : RAGFlow + SGLang (Qwen3-8B) + Ollama (embeddings)
- **URL** : https://ragflow.flowkura.com
- **Date optimisation** : 19 novembre 2025

## 🎯 Optimisations appliquées

### Infrastructure (800% plus rapide)
- ✅ **8 workers** de parsing parallèle (était: 1)
- ✅ **Redis 4GB** de cache (était: 128MB)
- ✅ **MySQL** optimisé (8GB buffer + IO threads)
- ✅ **Elasticsearch** optimisé (8GB heap)
- ✅ **Upload 10GB** (était: 6GB)
- ✅ **HTTPS/SSL** avec Let's Encrypt auto-renew

### LLM (SGLang remplace vLLM)
- ✅ **SGLang** + Qwen3-8B pour génération (port 8000)
- ✅ **Ollama** + nomic-embed-text pour embeddings (port 11434)
- ✅ **40K tokens** de context window
- ✅ **API OpenAI compatible**

## 📁 Structure

```
flowkura-infrastructure/
├── docs/                    # Documentation complète
│   ├── INSTALLATION.md     # Guide réinstallation
│   ├── MAINTENANCE.md      # Procédures maintenance
│   ├── CONFIGURATION.md    # Détails configurations
│   └── TROUBLESHOOTING.md  # Dépannage
├── scripts/                # Scripts utilitaires
│   ├── backup.sh          # Backup complet
│   ├── restore.sh         # Restauration
│   ├── health-check.sh    # Monitoring
│   └── deploy.sh          # Déploiement
├── docker/                # Docker configs
│   ├── docker-compose-llm.yml
│   ├── docker-compose-base.yml.optimized
│   └── ragflow-server.yaml.optimized
├── configs/               # Fichiers de config
│   ├── .env.optimized
│   ├── service_conf.yaml.example
│   └── nginx-ssl.conf
├── backups/               # Backups (gitignored)
└── .github/workflows/     # CI/CD
    └── health-check.yml
```

## 🚀 Démarrage rapide

### Backup complet
```bash
./scripts/backup.sh
```

### Health check
```bash
./scripts/health-check.sh
```

### Redémarrer services
```bash
ssh root@136.243.41.162
cd ragflow/docker
docker compose restart
docker compose -f docker-compose-llm.yml restart
```

## 📊 Ressources

### VRAM
- **Utilisé**: 17.7GB (88%)
- **Libre**: 2.3GB (12%)
- **SGLang (Qwen3-8B)**: 17.3GB
- **Ollama (embeddings)**: ~300MB

### Containers actifs
- ragflow-server (HTTPS:443, HTTP:80)
- ragflow-mysql (optimisé 8GB buffer)
- ragflow-redis (4GB cache)
- ragflow-es-01 (8GB heap)
- ragflow-minio
- flowkura-sglang-qwen3 (port 8000)
- flowkura-ollama (port 11434)

## 📞 Support

- **Documentation**: Voir `docs/`
- **Problèmes**: Voir `docs/TROUBLESHOOTING.md`
- **Monitoring**: `./scripts/health-check.sh`

---

**Version**: 1.0  
**Dernière mise à jour**: 19 novembre 2025  
**Auteur**: Flowkura Team
