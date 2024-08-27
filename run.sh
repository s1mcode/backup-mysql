#!/bin/bash

# 检测操作系统并设置相应的 date 命令
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v gdate > /dev/null 2>&1; then
        DATE_CMD="gdate"
    else
        echo "错误：在 macOS 上需要安装 gdate。请运行 'brew install coreutils' 来安装。" >&2
        exit 1
    fi
else
    # 假设其他系统是 Linux
    DATE_CMD="date"
fi

# 读取配置文件
CONFIG_FILE="backup_config.ini"

# 读取数据库列表
DATABASES=($(awk -F '=' '/^databases/ {gsub(/ /, "", $2); split($2, arr, ","); for (i in arr) print arr[i]}' "$CONFIG_FILE"))

# 读取备份目录
BACKUP_DIR=$(awk -F '=' '/^backup_dir/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")

# 读取保留策略
ANNUAL_KEEP=$(awk -F '=' '/^annual_keep/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
MONTHLY_KEEP=$(awk -F '=' '/^monthly_keep/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
WEEKLY_KEEP=$(awk -F '=' '/^weekly_keep/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
DAILY_KEEP=$(awk -F '=' '/^daily_keep/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
HOURLY_KEEP=$(awk -F '=' '/^hourly_keep/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")
LATEST_KEEP=$(awk -F '=' '/^latest_keep/ {gsub(/ /, "", $2); print $2}' "$CONFIG_FILE")

# 日志文件路径
LOG_FILE="${BACKUP_DIR}/backup_log.log"

# 确保备份目录存在
mkdir -p "${BACKUP_DIR}"

# 清理旧的备份文件
cleanup_old_backups() {
    local db=$1
    local pattern="${BACKUP_DIR}/*_${db}.sql"
    
    # 获取所有备份文件并按时间排序
    all_backups=$(find $pattern -type f | sort -r)
    
    # 初始化保留列表
    declare keep_list
    
    # 保留最新的备份
    i=0
    for backup in $all_backups; do
        if [ $i -lt $LATEST_KEEP ]; then
            keep_list="$keep_list $backup"
            echo "保留: $backup (latest-$((i+1)))" >> "$LOG_FILE"
        fi
        i=$((i+1))
    done
    
    # 初始化计数器
    hour_count=0
    day_count=0
    week_count=0
    month_count=0
    year_count=0
    
    current_hour=""
    current_day=""
    current_week=""
    current_month=""
    current_year=""
    
    for backup in $all_backups; do
        # 提取日期信息
        filename=$(basename "$backup")
        date_part=${filename:0:12}
        year=${date_part:0:4}
        month=${date_part:0:6}
        week=$($DATE_CMD -d "${year}-${month:4:2}-${date_part:6:2}" +%Y%W)
        day=${date_part:0:8}
        hour=${date_part:0:10}
        
        keep_reason=""
        
        # 检查并更新每小时备份
        if [ "$hour" != "$current_hour" ] && [ $hour_count -lt $HOURLY_KEEP ]; then
            keep_reason="${keep_reason:+$keep_reason,}hourly-$((hour_count+1))"
            current_hour=$hour
            hour_count=$((hour_count+1))
        fi
        
        # 检查并更新每日备份
        if [ "$day" != "$current_day" ] && [ $day_count -lt $DAILY_KEEP ]; then
            keep_reason="${keep_reason:+$keep_reason,}daily-$((day_count+1))"
            current_day=$day
            day_count=$((day_count+1))
        fi
        
        # 检查并更新每周备份
        if [ "$week" != "$current_week" ] && [ $week_count -lt $WEEKLY_KEEP ]; then
            keep_reason="${keep_reason:+$keep_reason,}weekly-$((week_count+1))"
            current_week=$week
            week_count=$((week_count+1))
        fi
        
        # 检查并更新每月备份
        if [ "$month" != "$current_month" ] && [ $month_count -lt $MONTHLY_KEEP ]; then
            keep_reason="${keep_reason:+$keep_reason,}monthly-$((month_count+1))"
            current_month=$month
            month_count=$((month_count+1))
        fi
        
        # 检查并更新每年备份
        if [ "$year" != "$current_year" ] && [ $year_count -lt $ANNUAL_KEEP ]; then
            keep_reason="${keep_reason:+$keep_reason,}annual-$((year_count+1))"
            current_year=$year
            year_count=$((year_count+1))
        fi
        
        if [ -n "$keep_reason" ]; then
            keep_list="$keep_list $backup"
            echo "保留: $backup ($keep_reason)" >> "$LOG_FILE"
        fi
    done
    
    # 删除不在保留列表中的文件
    for backup in $all_backups; do
        if ! echo "$keep_list" | grep -q "$backup"; then
            rm -f "$backup"
            echo "已删除: $backup" >> "$LOG_FILE"
        fi
    done
}

# 循环备份每个数据库
for DB in "${DATABASES[@]}"
do
    # 获取当前时间
    CURRENT_TIME=$($DATE_CMD +"%Y-%m-%d %H:%M:%S")

    # 日志：备份开始
    echo "${CURRENT_TIME} - 开始备份数据库 ${DB}。" >> "${LOG_FILE}"

    # 定义备份文件的完整路径，文件名以当前时间开头
    BACKUP_FILE="${BACKUP_DIR}/$($DATE_CMD +%Y%m%d%H%M)_${DB}.sql"

    # 执行备份命令并将输出结果重定向到日志文件
    mysqldump --defaults-file=mysql.cnf "${DB}" > "${BACKUP_FILE}" 2>>"${LOG_FILE}"

    # 获取备份操作后的当前时间
    CURRENT_TIME=$($DATE_CMD +"%Y-%m-%d %H:%M:%S")

    # 检查备份是否成功，并将结果与时间写入日志文件
    if [ $? -eq 0 ]; then
        echo "${CURRENT_TIME} - 数据库 ${DB} 备份成功。" >> "${LOG_FILE}"
    else
        echo "${CURRENT_TIME} - 备份数据库 ${DB} 时出错" >> "${LOG_FILE}"
    fi

    # 清理旧的备份文件
    cleanup_old_backups "${DB}"
done