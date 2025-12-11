#!/bin/bash

# 验证打包文件完整性的脚本

set -e

RELEASE_FILE="/home/nvidia/projects/scaffold/dist/releases/scaffold-v1.1.0.tar.gz"
TEMP_DIR="/tmp/scaffold-verify"

echo "验证打包文件: $RELEASE_FILE"

# 创建临时目录
mkdir -p "$TEMP_DIR"

# 解压到临时目录
echo "解压文件..."
tar -xzf "$RELEASE_FILE" -C "$TEMP_DIR"

# 检查必要的文件和目录
echo "检查必要的文件和目录..."

REQUIRED_PATHS=(
    "VERSION"
    "README.md"
    "scripts/install.sh"
    "scripts/service.sh"
    "frontend/src/App.tsx"
    "backend-node/src/server.ts"
    "backend-python/app/main.py"
)

for path in "${REQUIRED_PATHS[@]}"; do
    if [ ! -e "$TEMP_DIR/$path" ]; then
        echo "错误: 缺少必要的文件或目录: $path"
        exit 1
    else
        echo "找到: $path"
    fi
done

# 检查VERSION文件内容
echo "检查VERSION文件内容..."
VERSION_CONTENT=$(cat "$TEMP_DIR/VERSION")
if [ "$VERSION_CONTENT" != "v1.1.0" ]; then
    echo "警告: VERSION文件内容不是预期的'v1.1.0': $VERSION_CONTENT"
else
    echo "VERSION文件内容正确: $VERSION_CONTENT"
fi

# 检查install.sh脚本的最后一行（可能没有换行符）
echo "检查install.sh脚本的最后一行..."
LAST_LINE=$(tail -n 1 "$TEMP_DIR/scripts/install.sh")
EXPECTED_LINE='p_ok "ready. use ./scripts/service.sh start"'

# 如果最后一行不匹配，检查是否是因为缺少换行符
if [ "$LAST_LINE" != "$EXPECTED_LINE" ]; then
    # 尝试去掉可能的换行符再比较
    LAST_LINE_TRIMMED=$(echo "$LAST_LINE" | tr -d '\n')
    if [ "$LAST_LINE_TRIMMED" != "$EXPECTED_LINE" ]; then
        echo "错误: install.sh脚本的最后一行不正确: $LAST_LINE"
        echo "期望: $EXPECTED_LINE"
        exit 1
    else
        echo "install.sh脚本的最后一行正确（忽略换行符）: $LAST_LINE_TRIMMED"
    fi
else
    echo "install.sh脚本的最后一行正确: $LAST_LINE"
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

echo "打包文件验证成功!"