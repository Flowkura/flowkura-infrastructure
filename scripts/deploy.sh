#!/bin/bash
###############################################################################
# FLOWKURA DEPLOYMENT SCRIPT
# Déploie automatiquement Flowkura sur un nouveau serveur
###############################################################################

set -e

SERVER="${1:-root@136.243.41.162}"
DOMAIN="${2:-ragflow.flowkura.com}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🚀 FLOWKURA AUTO-DEPLOYMENT                             ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "  Server: $SERVER"
echo "  Domain: $DOMAIN"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -p "Continuer ? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "📦 Étape 1/7 : Clone RAGFlow..."
ssh $SERVER 'cd ~ && git clone https://github.com/infiniflow/ragflow.git 2>/dev/null || echo "Déjà cloné"'

echo ""
echo "📦 Étape 2/7 : Copie des configurations optimisées..."
scp ragflow-docker/docker-compose-base.yml $SERVER:/root/ragflow/docker/
scp ragflow-docker/.env.production $SERVER:/root/ragflow/docker/.env
scp docker/docker-compose-llm.yml $SERVER:/root/ragflow/docker/

echo ""
echo "📦 Étape 3/7 : Copie configs Nginx..."
scp nginx/*.conf $SERVER:/root/ragflow/docker/nginx/

echo ""
echo "🐳 Étape 4/7 : Démarrage RAGFlow..."
ssh $SERVER 'cd /root/ragflow/docker && docker compose up -d'

echo ""
echo "⏳ Attente démarrage services (30s)..."
sleep 30

echo ""
echo "🔒 Étape 5/7 : Configuration SSL..."
ssh $SERVER "apt update && apt install -y certbot python3-certbot-nginx"
ssh $SERVER "certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email contact@$DOMAIN || echo 'SSL déjà configuré'"

echo ""
echo "📝 Étape 6/7 : Configuration auto-renew SSL..."
ssh $SERVER 'cat > /root/renew-ssl.sh << "EOF"
#!/bin/bash
certbot renew --nginx --quiet
docker exec ragflow-server nginx -s reload
EOF
chmod +x /root/renew-ssl.sh
(crontab -l 2>/dev/null; echo "0 */12 * * * /root/renew-ssl.sh") | crontab -'

echo ""
echo "🤖 Étape 7/7 : Démarrage services LLM..."
ssh $SERVER 'cd /root/ragflow/docker && docker compose -f docker-compose-llm.yml up -d'

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ DÉPLOIEMENT TERMINÉ                                   ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "  URL: https://$DOMAIN"
echo ""
echo "  ⏳ Services LLM en cours de démarrage..."
echo "     (Première fois: 15-20 min pour télécharger Qwen3-8B)"
echo ""
echo "  📋 Prochaines étapes:"
echo "     1. Aller sur https://$DOMAIN"
echo "     2. Créer un compte admin"
echo "     3. Configurer le modèle LLM (voir docs/DEPLOYMENT.md)"
echo "╚════════════════════════════════════════════════════════════╝"
