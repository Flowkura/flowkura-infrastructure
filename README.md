# 🚀 Flowkura RAGFlow - Infrastructure Production

**Repository complet** pour déployer et maintenir l'infrastructure Flowkura.

---

## 🎯 QU'EST-CE QUE CE REPOSITORY ?

Ce repository contient **TOUT** ce qui est nécessaire pour :
- ✅ Réinstaller Flowkura depuis zéro
- ✅ Maintenir l'infrastructure actuelle
- ✅ Restaurer en cas de panne
- ✅ Comprendre la configuration complète

**Si je ne suis pas là demain**, quelqu'un peut tout refaire avec ce repo.

---

## 📊 INFRASTRUCTURE ACTUELLE

### Serveur
- **IP** : 136.243.41.162
- **OS** : Ubuntu Linux
- **GPU** : NVIDIA RTX 4000 Ada (20GB VRAM)
- **RAM** : 32GB
- **URL** : https://ragflow.flowkura.com

### Services déployés
```
┌─────────────────────────────────────────────────────┐
│ STACK FLOWKURA                                      │
├─────────────────────────────────────────────────────┤
│ • RAGFlow (API + UI)         Port: 443 (HTTPS)     │
│ • SGLang (Qwen3-8B)          Port: 8000            │
│ • Ollama (embeddings)        Port: 11434           │
│ • MySQL (optimisé 8GB)       Port: 5455            │
│ • Redis (cache 4GB)          Port: 6379            │
│ • Elasticsearch (8GB heap)   Port: 1200            │
│ • MinIO (stockage)           Ports: 9000-9001      │
└─────────────────────────────────────────────────────┘
```

### Optimisations appliquées
- **Parsing** : 8 workers parallèles (800% plus rapide)
- **Cache Redis** : 4GB (vs 128MB)
- **MySQL** : 8GB buffer pool + IO optimisé
- **Elasticsearch** : 8GB heap
- **Upload** : 10GB max
- **SSL/HTTPS** : Let's Encrypt avec auto-renew

---

## 📁 STRUCTURE DU REPOSITORY

```
flowkura-infrastructure/
├── README.md                           ← Ce fichier
│
├── ragflow-docker/                     ← CONFIGS DOCKER PRODUCTION
│   ├── docker-compose-base.yml         ← MySQL, Redis, ES, MinIO
│   ├── docker-compose.yml              ← RAGFlow principal
│   └── .env.production                 ← Variables d'environnement
│
├── docker/                             ← CONFIG LLM
│   └── docker-compose-llm.yml          ← SGLang + Ollama
│
├── nginx/                              ← CONFIG NGINX + SSL
│   ├── nginx.conf
│   ├── ragflow.conf
│   ├── ragflow.https.conf              ← Config SSL actuelle
│   └── proxy.conf
│
├── scripts/                            ← SCRIPTS MAINTENANCE
│   ├── backup.sh                       ← Backup complet
│   ├── health-check.sh                 ← Monitoring
│   ├── deploy.sh                       ← Déploiement auto
│   └── restore.sh                      ← Restauration
│
├── docs/                               ← DOCUMENTATION
│   ├── INSTALLATION.md                 ← Installation pas-à-pas
│   ├── DEPLOYMENT.md                   ← Guide déploiement complet
│   ├── MAINTENANCE.md                  ← Tâches maintenance
│   ├── TROUBLESHOOTING.md              ← Résolution problèmes
│   └── ARCHITECTURE.md                 ← Architecture système
│
└── .github/workflows/                  ← CI/CD
    └── health-check.yml                ← Check auto 6h
```

---

## 🚀 DÉMARRAGE RAPIDE

### Pour vérifier que tout fonctionne
```bash
cd ~/Workspace/Flowkura/flowkura-infrastructure
./scripts/health-check.sh
```

### Pour faire un backup
```bash
./scripts/backup.sh
```

### Pour redémarrer les services
```bash
ssh root@136.243.41.162
cd /root/ragflow/docker
docker compose restart
docker compose -f docker-compose-llm.yml restart
```

---

## 📖 GUIDES COMPLETS

### 🔧 Si vous devez TOUT RÉINSTALLER
→ Voir [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)

**Temps estimé** : 45-60 minutes  
**Difficulté** : Moyenne

### 🔄 Si vous devez RESTAURER depuis backup
→ Voir `scripts/restore.sh`

**Temps estimé** : 15-20 minutes  
**Difficulté** : Facile

### 🛠️ Maintenance quotidienne/hebdomadaire
→ Voir [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md)

### 🐛 En cas de problème
→ Voir [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

---

## 🔑 INFORMATIONS CRITIQUES

### Accès serveur
```bash
ssh root@136.243.41.162
```

### Mots de passe (en production)
- **MySQL** : `infini_rag_flow` (root)
- **MinIO** : user=`rag_flow`, pass=`infini_rag_flow`
- **API RAGFlow** : Clé dans l'interface web

### Certificats SSL
- **Emplacement** : `/etc/letsencrypt/live/ragflow.flowkura.com/`
- **Expire** : 22 décembre 2025
- **Auto-renew** : Oui (cron 2x/jour)

### Données importantes
- **Base données** : Container `ragflow-mysql`
- **Fichiers uploadés** : Container `ragflow-minio`
- **Modèles LLM** : `/root/.cache/huggingface/`
- **Modèles embeddings** : Volume Docker `ollama_data`

---

## 🎯 SCÉNARIOS D'UTILISATION

### Scénario 1 : Le serveur a crashé
1. Redémarrer le serveur
2. Vérifier : `./scripts/health-check.sh`
3. Si erreurs → `docs/TROUBLESHOOTING.md`

### Scénario 2 : Besoin de migrer vers nouveau serveur
1. Faire backup : `./scripts/backup.sh`
2. Sur nouveau serveur : `docs/DEPLOYMENT.md`
3. Restaurer : `./scripts/restore.sh`

### Scénario 3 : Ajouter plus de capacité
1. Modifier `ragflow-docker/docker-compose-base.yml`
2. Augmenter workers, RAM, etc.
3. Redéployer : `./scripts/deploy.sh`

### Scénario 4 : Mettre à jour RAGFlow
1. Backup d'abord !
2. Voir `docs/MAINTENANCE.md#mise-à-jour`

---

## 📊 MONITORING

### Vérifier santé système
```bash
./scripts/health-check.sh
```

### Voir logs
```bash
# RAGFlow
ssh root@136.243.41.162 'docker logs -f --tail 100 ragflow-server'

# LLM (SGLang)
ssh root@136.243.41.162 'docker logs -f --tail 100 flowkura-sglang-qwen3'

# Base de données
ssh root@136.243.41.162 'docker logs -f --tail 100 ragflow-mysql'
```

### Vérifier utilisation GPU
```bash
ssh root@136.243.41.162 nvidia-smi
```

### Vérifier espace disque
```bash
ssh root@136.243.41.162 df -h
```

---

## 🆘 EN CAS D'URGENCE

### Service ne répond plus
```bash
ssh root@136.243.41.162
cd /root/ragflow/docker
docker compose restart [nom-du-service]
```

### GPU saturé
```bash
# Redémarrer SGLang
docker restart flowkura-sglang-qwen3
```

### Base de données corrompue
```bash
# Restaurer depuis backup
./scripts/restore.sh [chemin-backup]
```

### Certificat SSL expiré
```bash
ssh root@136.243.41.162
certbot renew --nginx --force-renewal
docker exec ragflow-server nginx -s reload
```

---

## 📞 CONTACTS & SUPPORT

- **Documentation** : Ce repository
- **Logs** : `/var/log/` sur le serveur
- **Backups** : `/root/backups/` sur le serveur

---

## 🔄 MISES À JOUR

### Comment mettre à jour ce repository

Après avoir modifié la config en production :

```bash
# 1. Copier les nouveaux fichiers
scp root@136.243.41.162:/root/ragflow/docker/[fichier] ragflow-docker/

# 2. Commiter
git add .
git commit -m "Update: [description]"
git push
```

---

## ⚠️ IMPORTANT

- ✅ Toujours faire un **backup** avant modification
- ✅ Tester en **staging** si possible
- ✅ Documenter les changements
- ✅ Garder ce repository à jour

---

**Version** : 2.0 Production-Ready  
**Date** : 19 novembre 2025  
**Mainteneur** : Flowkura Team
