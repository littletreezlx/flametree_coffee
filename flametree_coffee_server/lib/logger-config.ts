/**
 * 日志配置管理
 * 提供统一的日志配置和初始化功能
 */

import { logger } from './logger'
import fs from 'fs'
import path from 'path'
import { schedule } from 'node-cron'

interface LoggerConfig {
  level: string
  logDir: string
  retentionDays: number
  enableConsoleLog: boolean
  perfThresholds: {
    api: number
    db: number
  }
  rateLimits: {
    windowMs: number
    maxRequests: number
  }
}

/**
 * 获取日志配置
 */
export function getLoggerConfig(): LoggerConfig {
  return {
    level: process.env.LOG_LEVEL || 'info',
    logDir: process.env.LOG_DIR || 'logs',
    retentionDays: parseInt(process.env.LOG_RETENTION_DAYS || '30'),
    enableConsoleLog: process.env.ENABLE_CONSOLE_LOG !== 'false',
    perfThresholds: {
      api: parseInt(process.env.PERF_THRESHOLD_API || '1000'),
      db: parseInt(process.env.PERF_THRESHOLD_DB || '500')
    },
    rateLimits: {
      windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000'),
      maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100')
    }
  }
}

/**
 * 初始化日志系统
 */
export function initializeLogger() {
  const config = getLoggerConfig()
  
  // 确保日志目录存在
  const logDir = path.join(process.cwd(), config.logDir)
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true })
  }
  
  // 记录初始化信息
  logger.info('日志系统初始化', {
    module: 'LoggerConfig',
    config: {
      level: config.level,
      logDir: config.logDir,
      retentionDays: config.retentionDays,
      enableConsoleLog: config.enableConsoleLog,
      environment: process.env.NODE_ENV
    }
  })
  
  // 设置定时清理任务（每天凌晨2点执行）
  if (process.env.NODE_ENV === 'production') {
    scheduleLogCleanup(config.retentionDays)
  }
  
  // 设置进程退出处理
  setupProcessHandlers()
  
  return logger
}

/**
 * 设置日志清理定时任务
 */
function scheduleLogCleanup(retentionDays: number) {
  // 每天凌晨2点执行清理
  schedule('0 2 * * *', async () => {
    logger.info('开始执行日志清理任务', {
      module: 'LoggerConfig',
      retentionDays
    })
    
    try {
      await logger.cleanupOldLogs(retentionDays)
      
      // 同时清理数据备份文件
      const dataDir = path.join(process.cwd(), 'data')
      await cleanupBackupFiles(dataDir, retentionDays)
      
      logger.info('日志清理任务完成', {
        module: 'LoggerConfig'
      })
    } catch (error) {
      logger.error('日志清理任务失败', {
        module: 'LoggerConfig',
        error: error.message
      })
    }
  })
  
  logger.info('日志清理任务已调度', {
    module: 'LoggerConfig',
    schedule: '每天凌晨2点',
    retentionDays
  })
}

/**
 * 清理备份文件
 */
async function cleanupBackupFiles(directory: string, daysToKeep: number) {
  try {
    const files = await fs.promises.readdir(directory)
    const cutoffDate = new Date()
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep)
    
    let cleanedCount = 0
    
    for (const file of files) {
      if (file.endsWith('.backup')) {
        const filePath = path.join(directory, file)
        const stats = await fs.promises.stat(filePath)
        
        if (stats.mtime < cutoffDate) {
          await fs.promises.unlink(filePath)
          cleanedCount++
        }
      }
    }
    
    if (cleanedCount > 0) {
      logger.info('备份文件清理完成', {
        module: 'LoggerConfig',
        directory,
        cleanedCount
      })
    }
  } catch (error) {
    logger.error('备份文件清理失败', {
      module: 'LoggerConfig',
      directory,
      error: error.message
    })
  }
}

/**
 * 设置进程事件处理
 */
function setupProcessHandlers() {
  // 捕获未处理的Promise拒绝
  process.on('unhandledRejection', (reason, promise) => {
    logger.fatal('未处理的Promise拒绝', {
      module: 'Process',
      reason: reason instanceof Error ? reason.message : String(reason),
      stack: reason instanceof Error ? reason.stack : undefined
    })
  })
  
  // 捕获未捕获的异常
  process.on('uncaughtException', (error) => {
    logger.fatal('未捕获的异常', {
      module: 'Process',
      error: error.message,
      stack: error.stack
    })
    
    // 给日志写入一些时间，然后退出
    setTimeout(() => {
      process.exit(1)
    }, 1000)
  })
  
  // 优雅关闭
  const gracefulShutdown = (signal: string) => {
    logger.info('收到关闭信号，开始优雅关闭', {
      module: 'Process',
      signal
    })
    
    // 执行清理操作
    setTimeout(() => {
      logger.info('进程关闭', {
        module: 'Process'
      })
      process.exit(0)
    }, 500)
  }
  
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
  process.on('SIGINT', () => gracefulShutdown('SIGINT'))
  
  logger.debug('进程事件处理器已设置', {
    module: 'LoggerConfig'
  })
}

/**
 * 获取日志统计信息
 */
export async function getLogStats(): Promise<{
  totalFiles: number
  totalSize: number
  oldestLog: Date | null
  newestLog: Date | null
}> {
  const config = getLoggerConfig()
  const logDir = path.join(process.cwd(), config.logDir)
  
  try {
    const files = await fs.promises.readdir(logDir)
    const logFiles = files.filter(f => f.endsWith('.log'))
    
    if (logFiles.length === 0) {
      return {
        totalFiles: 0,
        totalSize: 0,
        oldestLog: null,
        newestLog: null
      }
    }
    
    let totalSize = 0
    let oldestTime = Date.now()
    let newestTime = 0
    
    for (const file of logFiles) {
      const filePath = path.join(logDir, file)
      const stats = await fs.promises.stat(filePath)
      
      totalSize += stats.size
      const fileTime = stats.mtime.getTime()
      
      if (fileTime < oldestTime) oldestTime = fileTime
      if (fileTime > newestTime) newestTime = fileTime
    }
    
    return {
      totalFiles: logFiles.length,
      totalSize,
      oldestLog: new Date(oldestTime),
      newestLog: new Date(newestTime)
    }
  } catch (error) {
    logger.error('获取日志统计信息失败', {
      module: 'LoggerConfig',
      error: error.message
    })
    
    return {
      totalFiles: 0,
      totalSize: 0,
      oldestLog: null,
      newestLog: null
    }
  }
}

/**
 * 导出日志为JSON格式
 */
export async function exportLogs(
  startDate: Date,
  endDate: Date,
  level?: string
): Promise<any[]> {
  const config = getLoggerConfig()
  const logDir = path.join(process.cwd(), config.logDir)
  const logs: any[] = []
  
  try {
    const files = await fs.promises.readdir(logDir)
    
    for (const file of files) {
      if (!file.endsWith('.log')) continue
      
      const fileDate = file.replace('.log', '')
      const fileDateObj = new Date(fileDate)
      
      if (fileDateObj >= startDate && fileDateObj <= endDate) {
        const filePath = path.join(logDir, file)
        const content = await fs.promises.readFile(filePath, 'utf8')
        const lines = content.split('\n').filter(line => line.trim())
        
        for (const line of lines) {
          try {
            // 解析日志行
            const logEntry = parseLogLine(line)
            
            if (!level || logEntry.level === level.toUpperCase()) {
              logs.push(logEntry)
            }
          } catch (error) {
            // 忽略解析错误的行
          }
        }
      }
    }
    
    return logs
  } catch (error) {
    logger.error('导出日志失败', {
      module: 'LoggerConfig',
      error: error.message
    })
    
    return []
  }
}

/**
 * 解析日志行
 */
function parseLogLine(line: string): any {
  // 日志格式: [timestamp] [level] [module] [traceId] message {context}
  const match = line.match(/\[(.*?)\] \[(.*?)\] \[(.*?)\] \[(.*?)\] (.*?)(\{.*\})?$/)
  
  if (!match) {
    throw new Error('Invalid log format')
  }
  
  const [, timestamp, level, module, traceId, message, contextStr] = match
  
  let context = {}
  if (contextStr) {
    try {
      context = JSON.parse(contextStr)
    } catch (error) {
      // 忽略JSON解析错误
    }
  }
  
  return {
    timestamp,
    level,
    module,
    traceId,
    message,
    context
  }
}

export default {
  getLoggerConfig,
  initializeLogger,
  getLogStats,
  exportLogs
}