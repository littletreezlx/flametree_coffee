#!/bin/bash

echo "🔥 Flametree Coffee 启动脚本"
echo "================================"

# 定义端口
SERVER_PORT=50031

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：关闭指定端口的进程
kill_port_processes() {
    local port=$1
    echo -e "${YELLOW}🔍 检查端口 $port 上的进程...${NC}"
    
    # 使用 lsof 查找使用该端口的进程
    local pids=$(lsof -ti :$port 2>/dev/null)
    
    if [ -z "$pids" ]; then
        echo -e "${GREEN}✅ 端口 $port 没有正在运行的进程${NC}"
    else
        echo -e "${RED}🔄 发现端口 $port 上的进程: $pids${NC}"
        echo -e "${YELLOW}📋 进程详情:${NC}"
        lsof -i :$port 2>/dev/null
        
        echo -e "${YELLOW}🛑 正在关闭端口 $port 上的进程...${NC}"
        # 先尝试优雅关闭
        for pid in $pids; do
            if kill -TERM $pid 2>/dev/null; then
                echo -e "${GREEN}✅ 已发送 TERM 信号给进程 $pid${NC}"
            fi
        done
        
        # 等待2秒
        sleep 2
        
        # 检查进程是否还在运行，如果是则强制关闭
        local remaining_pids=$(lsof -ti :$port 2>/dev/null)
        if [ ! -z "$remaining_pids" ]; then
            echo -e "${RED}⚠️  进程仍在运行，强制关闭...${NC}"
            for pid in $remaining_pids; do
                if kill -KILL $pid 2>/dev/null; then
                    echo -e "${GREEN}✅ 已强制关闭进程 $pid${NC}"
                fi
            done
        fi
        
        # 最终确认
        sleep 1
        local final_check=$(lsof -ti :$port 2>/dev/null)
        if [ -z "$final_check" ]; then
            echo -e "${GREEN}✅ 端口 $port 已成功清理${NC}"
        else
            echo -e "${RED}❌ 警告: 端口 $port 仍有进程运行${NC}"
        fi
    fi
}

# 函数：关闭 Node.js 相关进程
kill_node_processes() {
    echo -e "${YELLOW}🔍 检查 Node.js 进程...${NC}"
    
    # 查找可能的 Node.js 进程
    local node_pids=$(pgrep -f "node.*next" 2>/dev/null)
    
    if [ -z "$node_pids" ]; then
        echo -e "${GREEN}✅ 没有发现相关的 Node.js 进程${NC}"
    else
        echo -e "${RED}🔄 发现 Node.js 进程: $node_pids${NC}"
        echo -e "${YELLOW}🛑 正在关闭 Node.js 进程...${NC}"
        
        # 优雅关闭
        pkill -TERM -f "node.*next" 2>/dev/null
        sleep 2
        
        # 强制关闭剩余进程
        pkill -KILL -f "node.*next" 2>/dev/null
        
        echo -e "${GREEN}✅ Node.js 进程已清理${NC}"
    fi
}

# 主清理流程
echo -e "${BLUE}🧹 开始清理进程...${NC}"

# 1. 关闭端口上的进程
kill_port_processes $SERVER_PORT

# 2. 关闭可能的 Node.js 进程
kill_node_processes

echo ""
echo -e "${BLUE}🚀 启动服务器...${NC}"

# 检查是否在正确的目录
if [ ! -d "flametree_coffee_server" ]; then
    echo -e "${RED}❌ 错误: 未找到 flametree_coffee_server 目录${NC}"
    echo -e "${YELLOW}请确保在项目根目录下运行此脚本${NC}"
    exit 1
fi

# 进入服务器目录
cd flametree_coffee_server

# 检查 package.json 是否存在
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 错误: 未找到 package.json 文件${NC}"
    exit 1
fi

# 检查 node_modules 是否存在
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 正在安装依赖...${NC}"
    npm install
fi

# 启动开发服务器
echo -e "${GREEN}🎉 启动 Flametree Coffee 服务器在端口 $SERVER_PORT...${NC}"
echo -e "${BLUE}🌐 访问地址: http://localhost:$SERVER_PORT${NC}"
echo -e "${YELLOW}💡 按 Ctrl+C 停止服务器${NC}"
echo ""

# 启动服务器
npm run dev

echo ""
echo -e "${YELLOW}👋 服务器已停止${NC}"