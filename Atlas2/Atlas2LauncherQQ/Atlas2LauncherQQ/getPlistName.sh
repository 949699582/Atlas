#!/bin/bash
  
# 脚本名称: list_atlas2_config_files.sh
# 功能描述: 获取~/Library/Atlas2/Config文件夹下所有文件的名称
# 注意事项: 确保该脚本具有执行权限，并且~/Library/Atlas2/Config目录存在
  
# 定义目标目录变量，使用绝对路径确保脚本的通用性
# 注意：这里使用~代表当前用户的家目录，但在脚本中直接使用~可能不会被正确解析
# 因此，我们使用$HOME环境变量来代表当前用户的家目录
TARGET_DIR="$HOME/Library/Atlas2/Config"
  
# 检查目标目录是否存在
if [ -d "$TARGET_DIR" ]; then
    echo "正在列出$TARGET_DIR目录下的所有文件..."
    # 使用ls命令列出目录下的所有文件（不包括目录本身），并通过-1选项使每个文件名占一行
    ls -1 "$TARGET_DIR"
else
    echo "错误：目录$TARGET_DIR不存在，请检查路径是否正确。"
fi
