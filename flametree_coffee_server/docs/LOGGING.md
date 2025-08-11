# 日志系统文档

## 概述

本项目实现了一套完整的分层日志系统，包括服务端日志、客户端日志、性能监控和数据操作日志。

## 日志架构

### 1. 核心模块

- **`lib/logger.ts`** - 核心日志工具，提供分级日志、格式化输出、性能监控
- **`lib/data-logger.ts`** - 数据访问层日志，记录所有文件系统操作
- **`lib/client-logger.ts`** - 客户端日志工具，用于前端页面操作记录
- **`lib/logger-config.ts`** - 日志配置管理，环境变量和定时任务
- **`middleware.ts`** - 请求中间件，提供请求追踪和性能监控

### 2. 日志级别

```typescript
enum LogLevel {
  DEBUG = 0,  // 详细调试信息
  INFO = 1,   // 关键业务流程
  WARN = 2,   // 警告信息
  ERROR = 3,  // 错误信息
  FATAL = 4   // 严重错误
}
```

### 3. 日志格式

```
[时间戳] [级别] [模块名] [追踪ID] 描述信息 {上下文数据}
```

示例：
```
[2024-01-01T10:00:00.000Z] [INFO] [OrdersAPI] [1234567890-abc] 订单创建成功 {"orderId":"ord_123","totalPrice":50}
```

## 使用指南

### 1. 基础日志记录

```typescript
import { logger } from '@/lib/logger'

// 记录不同级别的日志
logger.debug('调试信息')
logger.info('业务流程')
logger.warn('警告信息')
logger.error('错误信息')
logger.fatal('严重错误')

// 带上下文的日志
logger.info('用户登录', {
  userId: 'user123',
  ip: '192.168.1.1',
  userAgent: 'Mozilla/5.0...'
})
```

### 2. 操作日志

```typescript
import { OperationLogger } from '@/lib/logger'

// 创建操作日志器
const operation = new OperationLogger('ModuleName', '操作名称')

// 记录操作步骤
operation.logStep('步骤1', { data: 'value' })
operation.logStep('步骤2')

// 操作成功
operation.complete({ result: 'success' })

// 操作失败
operation.fail(new Error('操作失败'))
```

### 3. 性能监控

```typescript
// 使用性能监控
const perf = logger.measurePerformance('数据库查询', 1000)

// 执行操作
await performDatabaseQuery()

// 结束监控
const duration = perf.end()
```

### 4. 数据操作日志

```typescript
import { DataLogger, DataTransaction } from '@/lib/data-logger'

// 读取JSON文件
const data = DataLogger.readJSON(filePath, '读取配置')

// 写入JSON文件
DataLogger.writeJSON(filePath, data, '保存配置')

// 使用事务
const transaction = new DataTransaction('批量更新')
transaction.logOperation('update', 'file1.json', true)
transaction.logOperation('update', 'file2.json', false, 'Permission denied')
transaction.commit()
```

### 5. 客户端日志

```typescript
import { clientLogger, FormLogger } from '@/lib/client-logger'

// 记录用户操作
clientLogger.logUserAction('点击按钮', { buttonId: 'submit' })

// 记录API调用
clientLogger.logAPICall('/api/orders', 'POST', 150, 200)

// 表单日志
const formLogger = new FormLogger('UserRegistration')
formLogger.logFieldChange('email', 'user@example.com')
formLogger.logValidation('email', true)
formLogger.logSubmit(true)
```

## 配置说明

### 环境变量

创建 `.env` 文件并配置：

```env
# 日志级别
LOG_LEVEL=info

# 日志目录
LOG_DIR=logs

# 日志保留天数
LOG_RETENTION_DAYS=30

# 控制台日志
ENABLE_CONSOLE_LOG=true

# 性能阈值（毫秒）
PERF_THRESHOLD_API=1000
PERF_THRESHOLD_DB=500

# 限流配置
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
```

### 日志输出

- **开发环境**: 控制台 + 文件（可选）
- **生产环境**: 文件 + 日志收集系统

## API端点

### POST /api/logs
接收客户端日志

请求体：
```json
{
  "logs": [
    {
      "level": "info",
      "message": "用户操作",
      "context": {},
      "timestamp": "2024-01-01T10:00:00.000Z"
    }
  ]
}
```

### GET /api/logs?action=stats
获取日志统计信息

响应：
```json
{
  "totalFiles": 10,
  "totalSize": 1048576,
  "oldestLog": "2024-01-01T00:00:00.000Z",
  "newestLog": "2024-01-10T00:00:00.000Z"
}
```

### GET /api/logs?action=export&start=2024-01-01&end=2024-01-31&level=error
导出指定时间范围的日志

## 最佳实践

### 1. 合理使用日志级别

- **DEBUG**: 仅在开发环境使用，记录详细调试信息
- **INFO**: 记录关键业务流程节点
- **WARN**: 记录异常但不影响流程的情况
- **ERROR**: 记录需要关注的错误
- **FATAL**: 记录导致系统无法继续的严重错误

### 2. 包含有用的上下文

```typescript
// 好的做法
logger.error('订单创建失败', {
  orderId: order.id,
  userId: user.id,
  error: error.message,
  items: order.items.length
})

// 避免
logger.error('Error')
```

### 3. 敏感信息脱敏

系统会自动脱敏以下字段：
- password
- token
- secret
- apiKey
- authorization

### 4. 使用追踪ID

中间件会自动生成追踪ID，用于关联整个请求链路：

```typescript
const traceId = request.headers.get('x-trace-id')
logger.info('处理请求', { traceId, ...otherContext })
```

### 5. 性能监控阈值

合理设置性能阈值，避免过多的警告日志：

```typescript
// API请求：1000ms
// 数据库操作：500ms
// 文件操作：200ms
```

## 故障排查

### 1. 日志文件位置

默认位置：`{project_root}/logs/`

文件命名：`YYYY-MM-DD.log`

### 2. 查看实时日志

```bash
# 查看最新日志
tail -f logs/$(date +%Y-%m-%d).log

# 查看错误日志
grep "ERROR" logs/*.log

# 查看特定追踪ID
grep "traceId-123" logs/*.log
```

### 3. 日志清理

- 自动清理：每天凌晨2点清理超过30天的日志
- 手动清理：删除 `logs/` 目录下的旧文件

### 4. 常见问题

**Q: 日志文件过大**
A: 调整 `LOG_LEVEL` 为更高级别，减少 DEBUG 日志

**Q: 性能影响**
A: 在生产环境关闭控制台日志，使用异步写入

**Q: 日志丢失**
A: 检查文件权限，确保日志目录可写

## 监控集成

### 1. 导出到外部系统

```typescript
// 定期导出日志到监控系统
const logs = await exportLogs(startDate, endDate)
await sendToMonitoringSystem(logs)
```

### 2. 告警配置

监控以下指标：
- ERROR 级别日志频率
- 响应时间超过阈值
- 限流触发次数
- 未处理异常

## 开发调试

### 启用详细日志

```bash
LOG_LEVEL=debug npm run dev
```

### 查看特定模块日志

```typescript
// 只看特定模块
grep "MenuAPI" logs/*.log
```

### 性能分析

```typescript
// 查看慢请求
grep "请求处理缓慢" logs/*.log
```

## 更新日志

- v1.0.0 - 初始版本，基础日志功能
- v1.1.0 - 添加性能监控和追踪ID
- v1.2.0 - 添加客户端日志收集
- v1.3.0 - 添加日志导出和统计功能