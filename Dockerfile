# 一页成稿 Paperize · 全量部署（前端构建 + 零依赖服务器）
# 服务器职责：托管 dist/ 静态文件 + 同源代理模型接口（/api/extract）

FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
COPY --from=build /app/dist ./dist
COPY server ./server
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1:3000/healthz || exit 1
CMD ["node", "server/index.mjs"]
