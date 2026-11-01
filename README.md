# 🌐 域名监控系统

基于 **Cloudflare Workers + KV** 的域名到期监控与通知服务，零服务器成本、全球 CDN 加速。

## ✨ 功能特性

- **域名管理** — 添加/删除/编辑域名，支持自定义备注、到期日期、续费价格
- **到期监控** — 每日自动检查域名到期状态，通过 Telegram Bot 推送通知
- **WHOIS 查询** — 集成 who.cx + RDAP 协议，支持多级域名查询
- **分类管理** — 自定义域名分类，拖拽排序
- **Dashboard 统计** — 总域名数、即将到期、已过期、年度续费成本一目了然
- **搜索与筛选** — 按域名名搜索，按状态/分类筛选
- **Telegram 通知** — 到期提醒、汇总报告，支持静默时段配置
- **数据导入导出** — JSON 格式备份/恢复
- **深色/浅色主题** — 一键切换，自动保存偏好
- **安全防护** — Session 认证、CSRF 防护、登录限流、XSS 转义

## 🚀 一键部署

### 方式一：使用部署脚本（推荐）

```bash
git clone https://github.com/zyy166/yuming.git
cd yuming
chmod +x deploy.sh
./deploy.sh
```

脚本会自动安装依赖、创建 KV 命名空间、部署到 Cloudflare。

### 方式二：使用 Wrangler CLI

```bash
git clone https://github.com/zyy166/yuming.git
cd yuming
npm install
npx wrangler login          # 登录 Cloudflare
npx wrangler kv namespace create DOMAIN_MONITOR  # 创建 KV
# 将返回的 namespace id 填入 wrangler.toml
npx wrangler deploy         # 部署
```

### 方式三：Cloudflare 控制台手动部署

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 进入 **Workers & Pages** → **Create** → **Create Worker**
3. 将 `src/worker.js` 的内容粘贴到编辑器中
4. 点击 **Deploy**
5. 进入 **Settings** → **Variables**：
   - 添加 **KV Namespace Binding**：变量名 `DOMAIN_MONITOR`
   - 添加环境变量（可选）：`TOKEN`、`TG_TOKEN`、`TG_ID` 等
6. 进入 **Triggers** → **Cron Triggers**：添加 `0 0 * * *`（每日执行）

## 🔄 绑定现有部署（更新已有 Worker）

如果你已经在 Cloudflare 上部署了本系统，想用本仓库代码更新：

### 步骤

1. **获取现有 KV Namespace ID**

```bash
npx wrangler kv namespace list
```

找到 `DOMAIN_MONITOR` 对应的 namespace id。

2. **填入 wrangler.toml**

```toml
[[kv_namespaces]]
binding = "DOMAIN_MONITOR"
id = "你的现有KV_NAMESPACE_ID"   # ← 填这里
```

3. **确保 Worker 名称一致**

```toml
name = "yuming"   # ← 改成你现有的 Worker 名称
```

4. **部署更新**

```bash
npx wrangler deploy
```

Wrangler 会将新代码部署到同名的现有 Worker，**KV 数据不会丢失**。

> ⚠️ 如果你的现有 Worker 名称不是 `yuming`，请修改 `wrangler.toml` 中的 `name` 字段使其匹配。

## ⚙️ 环境变量配置

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `TOKEN` | 登录密码 | `domain` | 否 |
| `TG_TOKEN` | Telegram Bot Token | — | 否（可在面板设置） |
| `TG_ID` | Telegram Chat ID | — | 否（可在面板设置） |
| `SITE_NAME` | 网站标题 | `域名监控系统` | 否 |
| `LOGO_URL` | 自定义 Logo 图片 URL | 内置默认 | 否 |
| `BACKGROUND_URL` | 自定义背景图 URL | 内置默认 | 否 |
| `MOBILE_BACKGROUND_URL` | 移动端背景图 URL | 内置默认 | 否 |

### KV 命名空间

| 绑定名 | 说明 | 必填 |
|--------|------|------|
| `DOMAIN_MONITOR` | 存储域名、分类、Telegram 配置、会话等数据 | ✅ 是 |

## 📅 定时任务

系统通过 Cron Trigger 每日自动执行：

- **域名到期检查** — 检查所有域名到期状态，发送 Telegram 通知
- **汇总报告** — 每周/每月发送域名状态汇总（可在设置中开启）

默认 Cron 表达式：`0 0 * * *`（每天 UTC 0:00 / 北京时间 8:00）

可在 `wrangler.toml` 中修改：

```toml
[triggers]
crons = ["0 0 * * *"]  # 改成你需要的时间
```

## 🛠️ 本地开发

```bash
npm install
npx wrangler dev
```

访问 `http://localhost:8787` 即可预览。

## 📁 项目结构

```
yuming/
├── src/
│   └── worker.js       # Cloudflare Workers 主代码（HTML+CSS+JS）
├── wrangler.toml        # Cloudflare Workers 部署配置
├── package.json         # 项目依赖与脚本
├── deploy.sh            # 一键部署脚本
├── .gitignore
└── README.md
```

## 🔒 安全特性

- **Session 认证** — 随机 token 替代固定 Cookie，24 小期自动过期
- **CSRF 防护** — 所有写操作校验 X-CSRF-Token
- **登录限流** — 同一 IP 连续失败 5 次锁定 15 分钟
- **XSS 防护** — 所有用户输入经 HTML 转义后渲染

## 📝 使用说明

1. 部署完成后，访问 Worker 域名
2. 首次访问会显示部署引导页面
3. 使用密码登录（默认 `domain`，可通过 `TOKEN` 环境变量修改）
4. 添加域名，设置到期日期
5. 在设置面板配置 Telegram 通知（可选）
6. 系统每日自动检查并通知

## 📄 License

MIT

<!-- auto-deploy test: 2026-11-01T11:12:43Z -->
