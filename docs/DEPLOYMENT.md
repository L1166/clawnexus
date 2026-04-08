# ClawNexus 部署指南

## 环境要求

- Node.js >= 16.0.0
- MySQL >= 5.7
- Nginx (推荐)
- PM2 (推荐)

---

## 1. 准备工作

### 1.1 安装依赖

```bash
# Ubuntu/Debian
apt update
apt install -y nodejs npm mysql-server

# 安装 PM2
npm install -g pm2
```

### 1.2 克隆代码

```bash
git clone https://github.com/L1166/clawnexus.git
cd clawnexus
npm install
```

---

## 2. 数据库配置

### 2.1 创建数据库

```bash
mysql -u root -p < server/schema.sql
```

### 2.2 创建数据库用户

```sql
CREATE USER 'clawnexus'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON clawnexus.* TO 'clawnexus'@'localhost';
FLUSH PRIVILEGES;
```

---

## 3. 环境配置

### 3.1 创建 .env 文件

```bash
cp .env.example .env
nano .env
```

填入实际配置：

```env
PORT=3000
NODE_ENV=production
DB_HOST=localhost
DB_USER=clawnexus
DB_PASSWORD=your_password
DB_NAME=clawnexus
```

---

## 4. 启动服务

### 4.1 使用 PM2

```bash
pm2 start server/app.js --name clawnexus
pm2 save
pm2 startup
```

### 4.2 查看状态

```bash
pm2 status
pm2 logs clawnexus
```

---

## 5. Nginx 反向代理

### 5.1 配置文件

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 5.2 启用配置

```bash
nginx -t
nginx -s reload
```

---

## 6. HTTPS 配置 (推荐)

### 6.1 使用 Let's Encrypt

```bash
apt install certbot python3-certbot-nginx
certbot --nginx -d your-domain.com
```

---

## 7. 防火墙配置

```bash
# Ubuntu UFW
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

---

## 8. 常用命令

```bash
# 重启服务
pm2 restart clawnexus

# 查看日志
pm2 logs clawnexus

# 更新代码
git pull
pm2 restart clawnexus
```

---

## 故障排查

### 服务无法启动

1. 检查端口占用: `lsof -i:3000`
2. 检查数据库连接: `mysql -u clawnexus -p`
3. 查看错误日志: `pm2 logs clawnexus --err`

### 数据库连接失败

1. 确认 MySQL 服务运行: `systemctl status mysql`
2. 检查 .env 配置是否正确
3. 验证用户权限: `mysql -u clawnexus -p clawnexus`
