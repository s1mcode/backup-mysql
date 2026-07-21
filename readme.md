## 依赖

脚本依赖 `mysqldump`（mysql-client），未安装会报 `mysqldump: command not found` 且备份出 0 字节空文件：

```sh
# Debian/Ubuntu（若报 404，先执行 apt update 刷新索引）
apt update && apt install -y mysql-client   # 或 mariadb-client

# RHEL/CentOS/Fedora
dnf install -y mysql                         # 或 mariadb

# 验证
which mysqldump
```

## 配置

```sh
# 修改 mysql.cnf，设置 mysql 的主机名、端口、用户名、密码；如需加密连接可开启 ssl-mode / ssl-ca
vim mysql.cnf

# 修改 backup_config.ini，配置需要备份的数据库、备份文件存放目录、保留策略
vim backup_config.ini

# 将 mysql.cnf 文件的权限设置为只有所有者可以读写
chmod 600 mysql.cnf

# 赋予 run.sh 可执行权限
chmod +x run.sh
```

