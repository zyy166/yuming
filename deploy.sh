#!/bin/bash
# 一键部署脚本
# 用法: ./deploy.sh
# 前提: 已安装 Node.js 和 npm

set -e

echo "🚀 域名监控系统 - 一键部署到 Cloudflare Workers"
echo "============================================="

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 未检测到 Node.js，请先安装: https://nodejs.org/"
    exit 1
fi

# 安装 wrangler
echo "📦 安装 Wrangler CLI..."
npm install

# 检查是否已登录 Cloudflare
echo ""
echo "🔐 检查 Cloudflare 认证状态..."
if ! npx wrangler whoami &> /dev/null; then
    echo "请先登录 Cloudflare 账号:"
    npx wrangler login
fi

echo ""
echo "✅ 认证成功！"

# 创建 KV 命名空间（如果 wrangler.toml 中 id 为空）
if grep -q 'id = ""' wrangler.toml; then
    echo ""
    echo "📦 创建 KV 命名空间..."
    KV_OUTPUT=$(npx wrangler kv namespace create DOMAIN_MONITOR 2>&1)
    echo "$KV_OUTPUT"
    KV_ID=$(echo "$KV_OUTPUT" | grep -oP 'id = "\K[^"]+')
    if [ -n "$KV_ID" ]; then
        sed -i "s/id = \"\"/id = \"$KV_ID\"/" wrangler.toml
        echo "✅ KV 命名空间已创建并写入 wrangler.toml"
    fi
fi

# 部署
echo ""
echo "🚀 部署到 Cloudflare Workers..."
npx wrangler deploy

echo ""
echo "✅ 部署完成！"
echo "============================================="
echo ""
echo "📋 部署后请完成以下配置："
echo "  1. 设置登录密码: 控制台 → Workers → yuming → 设置 → 变量 → TOKEN"
echo "  2. 配置 Telegram: 控制台 → Workers → yuming → 设置 → 变量 → TG_TOKEN / TG_ID"
echo "  3. 或在网页设置面板中直接配置 Telegram"
echo ""
echo "🔗 访问你的 Worker 域名开始使用: https://yuming.<your-subdomain>.workers.dev"
