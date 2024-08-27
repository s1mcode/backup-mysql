## 配置

```sh
# 修改 mysql.cnf，设置 mysql 的用户名、密码、主机名
vim mysql.cnf

# 修改 backup_config.ini，配置需要备份的数据库、备份文件存放目录、保留策略
vim backup_config.ini

# 将 mysql.cnf 文件的权限设置为只有所有者可以读写
chmod 600 mysql.cnf

# 赋予 run.sh 可执行权限
chmod +x run.sh
```

