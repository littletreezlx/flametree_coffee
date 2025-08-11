# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个使用Next.js 15构建的咖啡厅管理服务器，为Flametree Coffee应用提供API服务和管理后台。

## 技术栈

- **框架**: Next.js 15.3.5 (App Router)
- **语言**: TypeScript 5
- **UI框架**: React 19
- **样式**: Tailwind CSS 4 + PostCSS
- **字体**: Geist Font Family
- **运行时**: Node.js

## 开发命令

```bash
# 安装依赖
npm install

# 启动开发服务器 (端口 61002，使用Turbopack)
npm run dev

# 构建生产版本
npm run build

# 启动生产服务器 (端口 61002)
npm start

# 代码检查
npm run lint
```

## 项目结构

```
flametree_coffee_server/
├── app/                      # Next.js App Router目录
│   ├── api/                  # API路由
│   │   ├── members/          # 家庭成员管理API
│   │   ├── menu/             # 菜单管理API
│   │   │   └── categories/   # 菜单分类API
│   │   ├── orders/           # 订单管理API
│   │   └── update/           # 更新管理API
│   │       ├── check/        # 更新检查
│   │       └── history/      # 更新历史
│   ├── admin/                # 管理后台页面
│   │   └── page.tsx          # 管理员界面(家庭成员与订单管理)
│   ├── layout.tsx            # 根布局(Geist字体配置)
│   ├── page.tsx              # 首页
│   └── globals.css           # 全局样式(Tailwind CSS)
├── data/                     # JSON数据存储
│   ├── menu.json             # 菜单数据
│   └── orders.json           # 订单数据
├── public/                   # 静态资源
└── 配置文件
    ├── next.config.ts        # Next.js配置
    ├── tsconfig.json         # TypeScript配置
    └── postcss.config.mjs    # PostCSS配置(Tailwind CSS)
```

## 核心功能模块

### API端点

1. **菜单管理** (`/api/menu`)
   - GET: 获取咖啡菜单
   - POST: 添加新菜品
   - 数据存储: `data/menu.json`

2. **订单管理** (`/api/orders`)
   - GET: 获取所有订单
   - POST: 创建新订单
   - 数据结构: Order接口包含订单详情、状态追踪
   - 订单状态: pending → preparing → ready → completed

3. **成员管理** (`/api/members`)
   - 管理家庭成员信息
   - 支持头像(emoji)和爱心值系统

4. **更新管理** (`/api/update`)
   - 应用版本检查和更新历史

### 管理后台

- **路径**: `/admin`
- **功能**: 
  - 家庭成员CRUD操作
  - 订单状态管理和统计
  - 实时数据展示
  - 爱心值统计系统

## 架构特点

### 数据存储
- 使用文件系统(JSON文件)作为轻量级数据库
- 数据文件位于`data/`目录
- 通过Node.js fs模块进行读写操作

### 样式系统
- Tailwind CSS 4配置与PostCSS集成
- 使用Geist字体提升视觉体验
- 响应式设计支持多设备访问

### TypeScript配置
- 严格模式启用(`strict: true`)
- 路径别名: `@/*` 映射到根目录
- Next.js插件集成

## 开发注意事项

### 端口配置
- 开发和生产环境统一使用端口 **61002**
- 避免与其他服务端口冲突

### 热重载
- 开发模式使用Turbopack加速构建
- 支持实时代码更新

### 数据持久化
- 重要：当前使用JSON文件存储，适合开发和小规模应用
- 生产环境建议迁移到数据库

### API设计模式
- RESTful风格API
- 使用Next.js Route Handlers
- 统一的错误处理和响应格式

## 常见开发任务

### 添加新的API端点
1. 在`app/api/`下创建新的路由文件夹
2. 创建`route.ts`文件实现HTTP方法处理
3. 使用`NextRequest`和`NextResponse`处理请求响应

### 修改数据结构
1. 更新相应的TypeScript接口定义
2. 确保向后兼容性
3. 更新相关API处理逻辑

### 部署注意事项
- 运行`npm run build`构建生产版本
- 使用`npm start`启动生产服务器
- 确保`data/`目录有适当的读写权限