# 域名监控系统 - 会话状态打包

## 项目基本信息
- **GitHub 仓库**: https://github.com/zyy166/yuming
- **Worker URL**: https://yuming.zyy5815.workers.dev
- **自定义域名**: https://ym.cyy.pp.ua
- **CF Account ID**: f205fc83f50de77f948e9a4b316f1338
- **Worker 名称**: yuming
- **KV Namespace**: DOMAIN_MONITOR (ID: a0aa08405b4849859042f93c7e7e181e)
- **Cron 触发器**: `0 0 * * *`（每天 0 点）
- **代码文件**: `/root/workspace/yuming/src/worker.js`（7722 行，336KB）
- **部署方式**: GitHub push → CF 自动部署（约 3-4 分钟）

## 环境变量（已设为 Secret，不会被 deploy 覆盖）
| 变量名 | 值 | 说明 |
|--------|-----|------|
| TOKEN | meiyoumima | 登录密码 |
| TG_TOKEN | 7116091495:AAHCohEInCOhCwp_kBrB6qAd2LiI1T8Sr6o | Telegram Bot Token |
| TG_ID | 582983975 | Telegram Chat ID |
| SITE_NAME | Zz的域名监控 | 网站标题 |

**重要**: 环境变量必须用 `wrangler secret put` 设置，不能用 wrangler.toml `[vars]`（会覆盖），也不能用 CF API `plain_text`（wrangler deploy 会清除）。Secret 是唯一持久的方式。

## KV 数据状态
- 51 个域名在 KV key `domains`（JSON 数组）
- 分类数据在 KV key `categories`
- Telegram 配置在 KV key `telegram_config`
- 其他 key: `last_notify_date`, `session:*`, `pending_notification` 等

## 已完成的 14 项改进（之前会话）
1. 安全：签名 cookie 认证、CSRF 保护、限流、XSS 防护
2. WHOIS 查询：who.cx + RDAP，支持多级域名
3. 通知去重
4. 错误处理
5. 数据导出导入（CSV）
6. 仪表盘统计
7. 搜索筛选
8. 静默时段
9. 定期汇总报告
10. 深色/浅色主题切换
11. 域名分类管理
12. 续期链接
13. 自定义备注和标签颜色
14. 拖拽排序

## 本次会话修复的 Bug
1. **`[vars]` 覆盖环境变量** — wrangler deploy 带 `[vars]` 段会覆盖 CF 控制台设的变量。修复：移除 `[vars]`，改用 `wrangler secret put`
2. **页面空白（themeToggleBtn 缺失）** — JS 引用了 `themeToggleBtn` 但 HTML 没这个按钮 → null 引用崩溃 → setupEventListeners 中断 → loadDomains 没执行。修复：补上 HTML 按钮
3. **域名卡片不显示（escapeHtml 未定义）** — 客户端 JS 调用 `escapeHtml()` 但该函数只在服务端定义。每个域名卡片创建都报 ReferenceError。修复：在客户端加 escapeHtml 函数
4. **主题切换无效（缺 CSS）** — 有 JS toggle 但没有 `body.light-theme` CSS。修复：添加完整浅色主题 CSS
5. **主题切换仍无效（::before 蒙版）** — `body::before` 有 `rgba(0,0,0,0.55)` 暗色蒙版，浅色主题没覆盖它。修复：加 `body.light-theme::before { display: none !important; }`
6. **搜索栏左侧空白** — statsContainer/searchFilterBar/domainListContainer 与 page-header 不对齐。修复：加 `padding: 0 20px`
7. **页面加载慢** — dashboard HTML 响应无缓存头。修复：加 `Cache-Control: private, max-age=60`

## 本次会话新增功能
### 已完成
- **分级提醒**（feat-6）：修改 checkExpiringDomains，支持 30/14/7/3/1 天分级通知，每个域名每个级别只通知一次，KV key `notify_tier:{domainId}:{tier}` 记录已通知级别

### 待实现（计划中）
- [high] **批量操作**（feat-2）：域名卡片加复选框，批量删除/移动分类/续期，后端加 batch API
- [medium] **历史记录**（feat-11）：续期/检测时记录历史，前端加历史查看模态框，后端加 /api/domains/:id/history
- [medium] **通知模板自定义**（feat-8）：设置页加模板编辑，KV 存 telegram_config.notifyTemplate
- [medium] **分页/虚拟滚动**（feat-1）：客户端分页，每页 50 个
- [medium] **KV 数据拆分**（feat-kv）：每个域名单独 key `domain:id`，加索引 `domain_index`，向后兼容自动迁移
- [medium] **检测频率可配**（feat-cron）：设置页加频率选择，KV 存 `check_schedule`，scheduled 事件读配置

## 未提交的代码变更
- 3 个 bug 修复（主题::before覆盖、搜索栏对齐、Cache-Control）已写入 worker.js 但未 git push
- 分级提醒（feat-6）已写入 worker.js 但未 git push
- **需要 git push 触发部署**

## Git 提交历史
```
d080f57 fix: 添加浅色主题CSS + 修复搜索栏对齐
fc4404e fix: 添加客户端escapeHtml函数，修复域名卡片渲染崩溃
9e88a86 debug: 添加域名卡片渲染错误捕获，定位显示不全问题
50d79b3 fix: 添加缺失的主题切换按钮HTML，修复页面空白bug
01f03fe fix: 移除 [vars] 段，避免 deploy 覆盖控制台环境变量
81164e1 test: 验证 GitHub 自动部署
f5deaab chore: 绑定现有 KV namespace
640b4b7 feat: 域名监控系统 - Cloudflare Workers
```

## 关键技术教训
1. `wrangler deploy` 的 `[vars]` 会**覆盖**所有控制台环境变量，不是合并
2. `wrangler deploy` 也会清除 `plain_text` 类型的 bindings
3. 只有 `wrangler secret put` 设置的 secret_text 类型才会在 deploy 后保留
4. 客户端 JS 和服务端 JS 在同一个 worker.js 文件里，但作用域不同 — 服务端函数不会自动在客户端可用
5. GitHub 绑定 CF Workers 后，push 到 master 自动触发部署，约 3-4 分钟
6. 沙箱环境无法访问 workers.dev 域名（网络限制）
7. 沙箱环境无法安装 Chrome（缺 libnspr4 等系统库，无 apt-get）

## 下次继续的步骤
1. `git push` 当前未提交的变更（3 bug 修复 + 分级提醒）
2. 等待自动部署完成
3. 验证：主题切换、搜索栏对齐、页面加载速度
4. 继续实现 feat-2（批量操作）→ feat-11（历史记录）→ feat-8（通知模板）→ feat-1（分页）→ feat-kv（KV拆分）→ feat-cron（检测频率）
