FROM alpine:3.18 AS builder

# 安装必备工具（增加 git、go、libc6-compat）
RUN apk add --no-cache wget ca-certificates git go libc6-compat

# 安装 Hugo Extended v0.161.1（最新稳定版）
RUN wget -O /tmp/hugo.tar.gz https://github.com/gohugoio/hugo/releases/download/v0.161.1/hugo_extended_0.161.1_linux-amd64.tar.gz && \
    tar -xzf /tmp/hugo.tar.gz -C /tmp && \
    ls -la /tmp/hugo && \
    mv /tmp/hugo /usr/local/bin/hugo && \
    chmod +x /usr/local/bin/hugo && \
    hugo version && \
    rm -f /tmp/hugo.tar.gz

WORKDIR /site

# 先复制主题相关文件（利用缓存）
COPY .gitmodules .gitmodules
COPY themes/ themes/

# 初始化 git submodule（Stack 主题）
RUN if [ -f .gitmodules ]; then \
        git submodule update --init --recursive || true; \
    fi

# 复制站点内容
COPY . .

# 构建站点
RUN hugo --minify

FROM nginx:alpine

COPY --from=builder /site/public /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
