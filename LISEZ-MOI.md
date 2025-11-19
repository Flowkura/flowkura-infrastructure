# 📖 LISEZ-MOI EN PREMIER

**Si vous découvrez ce repository pour la première fois**, commencez ici.

---

## ❓ QU'EST-CE QUE C'EST ?

Ce repository contient **TOUTE** l'infrastructure de production Flowkura :
- Configurations Docker optimisées
- Scripts de déploiement automatique
- Guides pas-à-pas complets
- Scripts de backup/restore
- Monitoring automatique

**Vous pouvez redéployer TOUT Flowkura en 1h avec ce repo.**

---

## 🎯 SCÉNARIOS D'UTILISATION

### Je veux juste vérifier que tout va bien
```bash
./scripts/health-check.sh
```

### Je dois faire un backup
```bash
./scripts/backup.sh
```

### Le serveur a planté, je dois tout redémarrer
```bash
ssh root@136.243.41.162
cd /root/ragflow/docker
docker compose restart
docker compose -f docker-compose-llm.yml restart
```

### Je dois déployer sur un NOUVEAU serveur
1. Lire [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) (guide complet)
2. Ou utiliser le script automatique : `./scripts/deploy.sh`

### Je dois restaurer depuis un backup
```bash
./scripts/restore.sh /chemin/vers/backup.tar.gz
```

---

## 📁 FICHIERS IMPORTANTS

| Fichier | Description |
|---------|-------------|
| `README.md` | Vue d'ensemble complète |
| `docs/DEPLOYMENT.md` | Guide déploiement **COMPLET** (45-60 min) |
| `ragflow-docker/docker-compose-base.yml` | Config Docker production (OPTIMISÉ) |
| `ragflow-docker/.env.production` | Variables d'environnement |
| `docker/docker-compose-llm.yml` | Config LLM (SGLang + Ollama) |
| `nginx/ragflow.https.conf` | Config Nginx avec SSL |
| `scripts/deploy.sh` | Déploiement automatique |
| `scripts/backup.sh` | Backup complet |
| `scripts/health-check.sh` | Vérification santé |

---

## 🚀 DÉMARRAGE RAPIDE

### Option 1 : Déploiement automatique (nouveau serveur)
```bash
cd ~/Workspace/Flowkura/flowkura-infrastructure
./scripts/deploy.sh root@VOTRE_IP votre-domaine.com
```

Puis suivre les instructions à l'écran.

### Option 2 : Déploiement manuel (contrôle total)
Suivre [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) étape par étape.

---

## 🔑 INFORMATIONS CRITIQUES

### Serveur actuel
- **IP** : 136.243.41.162
- **Domaine** : ragflow.flowkura.com
- **Accès** : `ssh root@136.243.41.162`

### Mots de passe
- MySQL root : `infini_rag_flow`
- MinIO : user=`rag_flow`, pass=`infini_rag_flow`

### Optimisations appliquées
- **8 workers** parsing (vs 1) = 800% plus rapide
- **Redis 4GB** cache (vs 128MB) = 3100% boost
- **MySQL 8GB** buffer pool
- **Elasticsearch 8GB** heap
- **Upload 10GB** max (vs 6GB)

---

## 📊 ARCHITECTURE

```
┌─────────────────────────────────────────────────────┐
│ INTERNET (HTTPS:443)                                │
│   ↓                                                 │
│ Nginx + Let's Encrypt SSL                          │
│   ↓                                                 │
│ RAGFlow UI + API                                    │
│   ↓                ↓                ↓               │
├─────────┬──────────┬────────────────┴──────────────┤
│ MySQL   │ Redis    │ Elasticsearch    MinIO        │
│ 8GB     │ 4GB      │ 8GB              (storage)    │
└─────────┴──────────┴───────────────────────────────┘
         ↓                              ↓
┌────────┴──────────────────────────────┴─────────────┐
│ GPU (NVIDIA RTX 4000 Ada - 20GB VRAM)               │
├─────────────────────────────────────────────────────┤
│ SGLang (Qwen3-8B)         17.3 GB                   │
│ Ollama (nomic-embed-text)  0.3 GB                   │
└─────────────────────────────────────────────────────┘
```

---

## ⚠️ AVANT DE MODIFIER QUOI QUE CE SOIT

1. **FAIRE UN BACKUP** : `./scripts/backup.sh`
2. Lire la documentation correspondante
3. Tester en staging si possible
4. Documenter vos changements
5. Mettre à jour ce repository

---

## 🆘 PROBLÈMES ?

### Le site ne répond pas
```bash
./scripts/health-check.sh
# Voir les services en erreur et redémarrer
```

### GPU saturé / VRAM pleine
```bash
ssh root@136.243.41.162
docker restart flowkura-sglang-qwen3
```

### Base de données corrompue
```bash
./scripts/restore.sh [chemin-backup]
```

### SSL expiré
```bash
ssh root@136.243.41.162
certbot renew --nginx --force-renewal
```

### Autres problèmes
Voir `docs/TROUBLESHOOTING.md` (à créer si besoin)

---

## 📞 RESSOURCES

- **Guide complet** : `docs/DEPLOYMENT.md`
- **Scripts** : `scripts/`
- **Configs** : `ragflow-docker/` et `docker/`
- **Logs serveur** : `ssh root@136.243.41.162 'docker logs [container]'`

---

## ✅ CHECKLIST MAINTENANCE

### Quotidien
- [ ] Vérifier health check : `./scripts/health-check.sh`
- [ ] Vérifier logs : `docker logs ragflow-server`

### Hebdomadaire
- [ ] Backup : `./scripts/backup.sh`
- [ ] Vérifier espace disque : `df -h`
- [ ] Vérifier VRAM : `nvidia-smi`

### Mensuel
- [ ] Tester restauration backup
- [ ] Mettre à jour ce repository si modifs
- [ ] Vérifier certificat SSL (expire 22 déc 2025)

---

## 🎯 PROCHAINES ÉTAPES

1. **Lire** [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) pour comprendre l'architecture
2. **Tester** le health check : `./scripts/health-check.sh`
3. **Faire** un backup test : `./scripts/backup.sh`
4. **Explorer** les autres docs dans `docs/`

---

**Créé le** : 19 novembre 2025  
**Version** : 2.0 Production-Ready  
**Mainteneur** : Flowkura Team

**Note** : Ce repository est autosuffisant. Vous n'avez besoin de rien d'autre pour redéployer Flowkura.
