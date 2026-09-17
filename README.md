# 一页成稿 Paperize

**文章 → 一页 A4 图解排版**。模型负责理解文章、提炼结构化内容；人负责两次确认——先勾选上版内容，再从三种版式中选定一种——最后导出 PNG 或打印为 PDF。

React + TypeScript + Vite 实现，大模型走 OpenAI 兼容接口、用户自带 API Key（仅保存在浏览器 localStorage）。内置一个零依赖 Node 服务端（`server/index.mjs`）：在 Kimi 平台预览或自托管时由它做同源代理，绕开浏览器 CSP 对跨域请求的拦截；纯静态部署（GitHub Pages）时前端自动回退为直连（Kimi / DeepSeek 接口已验证支持 CORS）。

## 工作流：模型提炼 + 两次人工确认

```
输入文章            模型提炼              人工确认 ①            人工确认 ②
─────────   →   ─────────────   →   ───────────────   →   ───────────────
粘贴/上传/URL     理解全文并输出      结构树逐项勾选         三种版式实时预览
                  结构化内容树        决定什么上版           选定后导出/打印
```

1. **输入文章**：粘贴纯文本 / Markdown，上传 `.txt` `.md` `.docx` `.pdf`，或抓取网页 URL 正文。
2. **模型提炼**：调用大模型（JSON 模式）把文章压缩成「一页容量」的结构树——标题、章节、要点、对比表、步骤、金句、关键数据，总量控制在 450 字以内。
3. **人工确认 ①（选内容）**：结构树逐项展示，带类型标签与字数统计；取消勾选的节点不进入排版，并实时预估总字数、检测 A4 超页。
4. **人工确认 ②（选版式）**：三种 A4 单页版式实时渲染、点击切换，确认后导出 PNG（约 1750×2470px，可直接印刷）或打印 / 另存 PDF。

## 三种版式

| 版式 | 风格 | 适用 |
| --- | --- | --- |
| **蓝图解析** | 蓝白技术信息图：衬线大标题、对比表高亮列、数据条、署名横幅 | 技术解析、产品对比 |
| **步骤图解** | 编号步骤 + 以前/现在对照框 + 红色收益标注 + 大数字结果条 | 流程演进、原理解释 |
| **手账涂鸦** | 手绘风：纸纹、歪歪扭扭边框、胶带贴纸、荧光笔划重点 | 轻松话题、科普推文 |

![蓝图解析](docs/screenshots/style-blueprint.png)

![步骤图解](docs/screenshots/style-techsteps.png)

![手账涂鸦](docs/screenshots/style-handbook.png)

## 快速开始

```bash
npm install
npm run dev        # 本地开发
npm run build      # 构建产物到 dist/
npm run server     # 零依赖服务器：托管 dist/ + 同源代理模型接口（默认 :3000）
```

1. 打开右上角「模型设置」，填入你自己的 API Key（默认 Kimi / Moonshot，兼容任意 OpenAI 接口：`DeepSeek`、`OpenAI`、`通义` 等，改 Base URL 与模型名即可）。
2. 粘贴文章 →「开始提炼结构」。
3. 没有 Key 也可以点「免 Key 体验排版」，用内置示例结构走完整个流程。

## 部署方式

模型请求的链路设计：**优先走同源 `/api/extract` 代理，不存在时自动回退浏览器直连**。

| 场景 | 部署方式 | 模型请求链路 |
| --- | --- | --- |
| Kimi 平台预览 / 发布 | 直接保存版本（平台托管） | 服务端代理 |
| 自有服务器 / VPS | `Dockerfile` 一键构建运行 | 服务端代理 |
| GitHub Pages 等纯静态托管 | Actions 构建 `dist/` | 浏览器直连（需模型接口支持 CORS，Kimi / DeepSeek 已验证） |

### 自有服务器（Docker）

```bash
docker build -t paperize .
docker run -d -p 3000:3000 paperize
```

### GitHub Pages

推送到 `main` 自动构建发布（见 `.github/workflows/deploy.yml`）。Pages 上模型请求为浏览器直连，请确认所用模型接口允许跨域；在平台预览或自托管环境下则无任何限制。

## 配置

| 配置项 | 默认值 | 说明 |
| --- | --- | --- |
| Base URL | `https://api.moonshot.cn/v1` | OpenAI 兼容接口地址 |
| API Key | — | 仅存浏览器 localStorage，不上传任何服务器 |
| 模型 | `kimi-k2-0905-preview` | 需要支持 JSON 模式 |

URL 抓取说明：浏览器直连目标站点可能受 CORS 限制，代码内置了两个公共代理兜底；抓取失败时建议直接粘贴正文。

## 模型调用说明

### 调用链路

前端按以下优先级发起提炼请求，全程使用 OpenAI 兼容的 `POST {baseUrl}/chat/completions`：

1. **同源代理（优先）**：`POST /api/extract`，由 `server/index.mjs` 转发到配置的上游接口。适用于 Kimi 平台预览 / 发布、Docker 自托管——浏览器不与外部模型域名直接通信，不受 CSP / CORS 限制。
2. **浏览器直连（回退）**：静态托管（GitHub Pages 等）上没有 `/api/extract`，前端检测到后自动直连上游。Kimi（api.moonshot.cn）与 DeepSeek（api.deepseek.com）已验证支持 CORS；其他服务商若返回 "Failed to fetch"，请改用带服务端的部署方式。

API Key 由浏览器在每次请求中自带（`Authorization: Bearer <key>`），服务端只做透明转发，不落盘、不记录。

### 请求参数

| 参数 | 取值 |
| --- | --- |
| model | 设置中填写的模型名（默认 `kimi-k2-0905-preview`） |
| temperature | `0.3` |
| response_format | `{ "type": "json_object" }`（要求模型支持 JSON 模式） |
| messages | system: 编辑角色 + 结构树 JSON Schema；user: 提炼要求 + 文章正文（截断至 24000 字符） |

返回经 `choices[0].message.content` 解析为结构树，渲染前会做容错处理（去代码块包裹、截取首个 `{` 至末个 `}`、补齐缺失 id）。

### 自托管 `/api/extract` 接口契约

供二次开发或接入自有后端时参考：

```
POST /api/extract
Content-Type: application/json

{
  "baseUrl": "https://api.moonshot.cn/v1",   // 上游 OpenAI 兼容接口地址，仅允许 http(s)
  "apiKey":  "sk-...",                        // 用户自带密钥
  "model":   "kimi-k2-0905-preview",
  "article": "文章正文（≤ 512KB）"
}

响应：原样透传上游 /chat/completions 的状态码与 JSON body。
```

### 排错对照

| 现象 | 原因与处理 |
| --- | --- |
| 红色报错 `Failed to fetch` / 无法连接 | 部署环境拦截跨域：改用 `npm run server` 或 Docker 部署（走同源代理） |
| `401 Invalid Authentication` | API Key 无效或过期，到服务商控制台重新签发 |
| `404` | Base URL 或模型名错误（注意 Base URL 需包含 `/v1`） |
| `429` | 触发限流或额度不足，稍后重试或充值 |
| 提炼结果缺内容 | 文章过短或模型不支持 JSON 模式，换模型后点「重新提炼」 |
| 页面提示「内容超出一页 A4」 | 返回上一步减少勾选，单页建议 ≤ 450 字 |

## 目录结构

```
src/
├── types/article.ts        # 结构树类型定义（所有版式的共同输入）
├── lib/
│   ├── prompt.ts           # 提炼 Prompt 与 JSON 解析/容错
│   ├── llm.ts              # 模型调用：优先同源代理，回退浏览器直连
│   ├── parseFile.ts        # txt / md / docx(mammoth) / pdf(pdfjs) 解析
│   ├── fetchArticle.ts     # URL 抓取（CORS 代理兜底 + 正文提取）
│   ├── tree.ts             # 树遍历、字数统计、按勾选裁剪
│   ├── sampleDoc.ts        # 内置示例结构（免 Key 体验）
│   └── demo.ts             # 内置示例文章
├── components/
│   ├── InputPanel.tsx      # 第一步：输入
│   ├── TreePanel.tsx       # 人工确认①：结构树勾选
│   ├── StyleSelect.tsx     # 人工确认②：版式选择 + 导出
│   ├── A4Sheet.tsx         # A4 纸张容器、缩放预览、超页检测
│   └── styles/             # 三种版式渲染器（纯函数：doc → JSX）
│       ├── Blueprint.tsx   # 蓝图解析
│       ├── TechSteps.tsx   # 步骤图解
│       └── Handbook.tsx    # 手账涂鸦
└── App.tsx                 # 状态机：input → extracting → tree → style

server/index.mjs            # 零依赖静态服务器 + /api/extract 同源代理（无状态，不保存密钥）
Dockerfile                  # 全量部署：构建前端 + 运行 server
```

## 新增一种版式

1. 在 `src/components/styles/` 新建渲染器：`(props: { doc: ExtractedDoc }) => JSX.Element`，根节点 `height: 100%`，参考现有三件套。
2. 在 `StyleSelect.tsx` 的 `STYLES` 数组中注册（id、名称、描述、render）。
3. 内容区（flex:1 容器）保持 `overflow: hidden`，超页检测与裁剪会自动生效。

## 设计原则

- **模型做粗活，人做决策**：提炼交给模型，但什么上版、用什么版式必须由人确认，不给"一键自动生成"的失控感。
- **一页硬约束**：Prompt 里就把容量压到 450 字，UI 里再做字数预估与超页检测，版式只负责美。
- **版式即纯函数**：三种版式共享同一份结构树数据，新增版式零成本。

## License

MIT
