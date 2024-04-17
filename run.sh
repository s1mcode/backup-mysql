#!/bin/bash

# 要备份的数据库数组，用空格分隔多个数据库
DATABASES=("database1" "database2")

# 备份文件存放目录
BACKUP_DIR="/path/to/your/backup/directory"

# 日志文件路径
LOG_FILE="${BACKUP_DIR}/backup_log_$(date +%Y%m%d).log"

# 确保备份目录存在
mkdir -p "${BACKUP_DIR}"

# 循环备份每个数据库
for DB in "${DATABASES[@]}"
do
    # 获取当前时间
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # 日志：备份开始
    echo "${CURRENT_TIME} - Starting backup for database ${DB}." >> "${LOG_FILE}"

    # 定义备份文件的完整路径，文件名以当前时间开头
    BACKUP_FILE="${BACKUP_DIR}/$(date +%Y%m%d%H%M)_${DB}.sql"
    
    # 执行备份命令并将输出结果重定向到日志文件
    mysqldump --defaults-file=my.cnf "${DB}" > "${BACKUP_FILE}" 2>>"${LOG_FILE}"
    
    # 获取备份操作后的当前时间
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # 检查备份是否成功，并将结果与时间写入日志文件
    if [ $? -eq 0 ]; then
        echo "${CURRENT_TIME} - Database ${DB} backed up successfully." >> "${LOG_FILE}"
    else
        echo "${CURRENT_TIME} - Error in backing up database ${DB}" >> "${LOG_FILE}"
    fi
done
