# Docker 部署

不使用 Cloudflare 账号时，用仓库根目录的 `Dockerfile` 在单机上运行 MiSub。容器使用同一套 Pages Functions 运行时，KV 和 D1 都落在数据卷里。

## 启动

在项目根目录执行：

```bash
docker compose up -d --build
```

旧版 Docker CLI 没有 `docker compose` 子命令时：

```bash
docker-compose up -d --build
```

启动后打开 `http://localhost:8788/login`。

未设置 `ADMIN_PASSWORD` 时，首次密码是 `admin`。登录后在「设置」里修改，新密码写入数据卷。

## 环境变量

写在项目根目录的 `.env` 中，再执行上面的启动命令。

| 变量 | 说明 |
|------|------|
| `HOST_PORT` | 宿主机端口，默认 `8788` |
| `ADMIN_PASSWORD` | 管理员密码。设置后，后台里的改密不会覆盖它 |
| `COOKIE_SECRET` | 登录 Cookie 密钥。留空则自动生成并写入数据卷 |
| `MISUB_PUBLIC_URL` | 对外访问地址，默认 `http://localhost:8788`。订阅转换回调会用它 |
| `MISUB_CALLBACK_URL` | 订阅转换回调基础地址，优先级高于 `MISUB_PUBLIC_URL`。通常留空 |
| `CORS_ORIGINS` | 允许跨域的来源，逗号分隔。同域访问不用填 |
| `CRON_SECRET` | 与后台「Cron Secret」填同一个值后，容器会按间隔调用 `/cron` |
| `CRON_INTERVAL_SECONDS` | 定时调用间隔，默认 `3600`，最小 `30` |

示例：

```bash
HOST_PORT=8788
ADMIN_PASSWORD=换成你的密码
MISUB_PUBLIC_URL=http://localhost:8788
```

改了宿主机端口时，把 `MISUB_PUBLIC_URL` 改成浏览器实际打开的地址。

## 数据

数据在 Docker 卷 `misub-data`。这是单进程部署，不要让多个容器共用同一个数据卷。

查看日志、停止：

```bash
docker compose logs -f
docker compose down
```

`docker compose down` 不会删除数据卷。要连数据一起删除时再用 `docker compose down -v`。
