/**
 * 统一日志工具模块
 * 提供分级日志、格式化输出、性能监控等功能
 */

import { NextRequest } from 'next/server'
import fs from 'fs'
import path from 'path'

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4
}

interface LogContext {
  module?: string
  operation?: string
  userId?: string
  traceId?: string
  params?: any
  duration?: number
  error?: any
  [key: string]: any
}

class Logger {
  private static instance: Logger
  private logLevel: LogLevel
  private logDir: string
  private currentStream: fs.WriteStream | null = null
  private currentDate: string = ''

  private constructor() {
    this.logLevel = this.getLogLevelFromEnv()
    this.logDir = path.join(process.cwd(), 'logs')
    this.ensureLogDirectory()
  }

  static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger()
    }
    return Logger.instance
  }

  private getLogLevelFromEnv(): LogLevel {
    const env = process.env.NODE_ENV
    const level = process.env.LOG_LEVEL?.toUpperCase()
    
    if (level && LogLevel[level as keyof typeof LogLevel] !== undefined) {
      return LogLevel[level as keyof typeof LogLevel]
    }
    
    return env === 'production' ? LogLevel.INFO : LogLevel.DEBUG
  }

  private ensureLogDirectory() {
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true })
    }
  }

  private getLogStream(): fs.WriteStream {
    const today = new Date().toISOString().split('T')[0]
    
    if (today !== this.currentDate) {
      if (this.currentStream) {
        this.currentStream.end()
      }
      
      this.currentDate = today
      const logFile = path.join(this.logDir, `${today}.log`)
      this.currentStream = fs.createWriteStream(logFile, { flags: 'a' })
    }
    
    return this.currentStream!
  }

  private formatMessage(level: string, message: string, context?: LogContext): string {
    const timestamp = new Date().toISOString()
    const module = context?.module || 'System'
    const traceId = context?.traceId || '-'
    
    let formattedMessage = `[${timestamp}] [${level}] [${module}] [${traceId}] ${message}`
    
    if (context) {
      const { module: _, traceId: __, ...restContext } = context
      if (Object.keys(restContext).length > 0) {
        formattedMessage += ` ${JSON.stringify(restContext)}`
      }
    }
    
    return formattedMessage
  }

  private sanitizeData(data: any): any {
    if (!data) return data
    
    const sensitiveKeys = ['password', 'token', 'secret', 'apiKey', 'authorization']
    
    if (typeof data === 'object') {
      const sanitized = Array.isArray(data) ? [...data] : { ...data }
      
      for (const key in sanitized) {
        const lowerKey = key.toLowerCase()
        
        if (sensitiveKeys.some(sensitive => lowerKey.includes(sensitive))) {
          sanitized[key] = '***REDACTED***'
        } else if (typeof sanitized[key] === 'object') {
          sanitized[key] = this.sanitizeData(sanitized[key])
        }
      }
      
      return sanitized
    }
    
    return data
  }

  private log(level: LogLevel, levelStr: string, message: string, context?: LogContext) {
    if (level < this.logLevel) return
    
    const sanitizedContext = this.sanitizeData(context)
    const formattedMessage = this.formatMessage(levelStr, message, sanitizedContext)
    
    // 控制台输出
    if (process.env.NODE_ENV !== 'production' || level >= LogLevel.WARN) {
      const consoleMethod = level >= LogLevel.ERROR ? console.error : console.log
      consoleMethod(formattedMessage)
    }
    
    // 文件输出
    if (process.env.NODE_ENV === 'production') {
      try {
        const stream = this.getLogStream()
        stream.write(formattedMessage + '\n')
      } catch (error) {
        console.error('Failed to write log to file:', error)
      }
    }
  }

  debug(message: string, context?: LogContext) {
    this.log(LogLevel.DEBUG, 'DEBUG', message, context)
  }

  info(message: string, context?: LogContext) {
    this.log(LogLevel.INFO, 'INFO', message, context)
  }

  warn(message: string, context?: LogContext) {
    this.log(LogLevel.WARN, 'WARN', message, context)
  }

  error(message: string, context?: LogContext) {
    this.log(LogLevel.ERROR, 'ERROR', message, context)
  }

  fatal(message: string, context?: LogContext) {
    this.log(LogLevel.FATAL, 'FATAL', message, context)
  }

  /**
   * 记录API请求
   */
  logRequest(req: NextRequest, module: string) {
    const traceId = this.generateTraceId()
    const { pathname, searchParams } = req.nextUrl
    
    this.info('API请求接收', {
      module,
      operation: 'request',
      traceId,
      method: req.method,
      path: pathname,
      query: Object.fromEntries(searchParams),
      headers: this.sanitizeHeaders(req.headers)
    })
    
    return traceId
  }

  /**
   * 记录API响应
   */
  logResponse(traceId: string, module: string, status: number, duration: number, data?: any) {
    const level = status >= 400 ? LogLevel.ERROR : LogLevel.INFO
    const message = status >= 400 ? 'API响应错误' : 'API响应成功'
    
    this.log(level, LogLevel[level], message, {
      module,
      operation: 'response',
      traceId,
      status,
      duration,
      responseSize: JSON.stringify(data || {}).length
    })
  }

  /**
   * 性能监控装饰器
   */
  measurePerformance(operation: string, threshold: number = 1000) {
    const startTime = Date.now()
    
    return {
      end: (context?: LogContext) => {
        const duration = Date.now() - startTime
        
        if (duration > threshold) {
          this.warn('操作执行缓慢', {
            ...context,
            operation,
            duration,
            threshold
          })
        } else {
          this.debug('操作执行完成', {
            ...context,
            operation,
            duration
          })
        }
        
        return duration
      }
    }
  }

  /**
   * 生成追踪ID
   */
  private generateTraceId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }

  /**
   * 清理敏感请求头
   */
  private sanitizeHeaders(headers: Headers): Record<string, string> {
    const sanitized: Record<string, string> = {}
    const sensitiveHeaders = ['authorization', 'cookie', 'x-api-key']
    
    headers.forEach((value, key) => {
      if (sensitiveHeaders.includes(key.toLowerCase())) {
        sanitized[key] = '***REDACTED***'
      } else {
        sanitized[key] = value
      }
    })
    
    return sanitized
  }

  /**
   * 清理过期日志文件
   */
  async cleanupOldLogs(daysToKeep: number = 30) {
    try {
      const files = await fs.promises.readdir(this.logDir)
      const cutoffDate = new Date()
      cutoffDate.setDate(cutoffDate.getDate() - daysToKeep)
      
      for (const file of files) {
        if (file.endsWith('.log')) {
          const filePath = path.join(this.logDir, file)
          const stats = await fs.promises.stat(filePath)
          
          if (stats.mtime < cutoffDate) {
            await fs.promises.unlink(filePath)
            this.info('清理过期日志文件', { file, age: daysToKeep })
          }
        }
      }
    } catch (error) {
      this.error('清理日志文件失败', { error: error.message })
    }
  }
}

export const logger = Logger.getInstance()

/**
 * Express/Next.js 中间件日志
 */
export function logMiddleware(module: string) {
  return (req: NextRequest) => {
    const traceId = logger.generateTraceId()
    const startTime = Date.now()
    
    logger.info('中间件开始处理', {
      module,
      traceId,
      path: req.nextUrl.pathname,
      method: req.method
    })
    
    return {
      traceId,
      duration: () => Date.now() - startTime
    }
  }
}

/**
 * 错误边界日志
 */
export function logError(error: Error, context?: LogContext) {
  logger.error('未捕获的错误', {
    ...context,
    error: error.message,
    stack: error.stack
  })
}

/**
 * 业务操作日志助手
 */
export class OperationLogger {
  private traceId: string
  private module: string
  private operation: string
  private startTime: number
  private context: LogContext

  constructor(module: string, operation: string, context?: LogContext) {
    this.traceId = logger.generateTraceId()
    this.module = module
    this.operation = operation
    this.startTime = Date.now()
    this.context = context || {}
    
    logger.info(`${operation}开始`, {
      module: this.module,
      operation: this.operation,
      traceId: this.traceId,
      ...this.context
    })
  }

  addContext(context: LogContext) {
    this.context = { ...this.context, ...context }
  }

  logStep(step: string, data?: any) {
    logger.info(`${this.operation} - ${step}`, {
      module: this.module,
      operation: this.operation,
      traceId: this.traceId,
      step,
      data
    })
  }

  complete(result?: any) {
    const duration = Date.now() - this.startTime
    
    logger.info(`${this.operation}完成`, {
      module: this.module,
      operation: this.operation,
      traceId: this.traceId,
      duration,
      result: result ? '成功' : '完成',
      ...this.context
    })
    
    return duration
  }

  fail(error: Error | string) {
    const duration = Date.now() - this.startTime
    const errorMessage = error instanceof Error ? error.message : error
    
    logger.error(`${this.operation}失败`, {
      module: this.module,
      operation: this.operation,
      traceId: this.traceId,
      duration,
      error: errorMessage,
      stack: error instanceof Error ? error.stack : undefined,
      ...this.context
    })
    
    return duration
  }
}

export default logger