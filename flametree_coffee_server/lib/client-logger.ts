/**
 * 客户端日志工具
 * 用于前端页面的操作日志记录
 */

export enum ClientLogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error'
}

interface ClientLogContext {
  module?: string
  userId?: string
  action?: string
  data?: any
  duration?: number
  [key: string]: any
}

class ClientLogger {
  private static instance: ClientLogger
  private logBuffer: Array<{
    timestamp: string
    level: ClientLogLevel
    message: string
    context?: ClientLogContext
  }> = []
  private maxBufferSize = 100
  private sendInterval: NodeJS.Timeout | null = null
  
  private constructor() {
    // 定期发送日志到服务器
    if (typeof window !== 'undefined') {
      this.sendInterval = setInterval(() => {
        this.flush()
      }, 30000) // 每30秒发送一次
      
      // 页面卸载时发送剩余日志
      window.addEventListener('beforeunload', () => {
        this.flush(true)
      })
    }
  }
  
  static getInstance(): ClientLogger {
    if (!ClientLogger.instance) {
      ClientLogger.instance = new ClientLogger()
    }
    return ClientLogger.instance
  }
  
  private formatMessage(level: ClientLogLevel, message: string, context?: ClientLogContext): string {
    const timestamp = new Date().toISOString()
    const module = context?.module || 'Client'
    
    let formatted = `[${timestamp}] [${level.toUpperCase()}] [${module}] ${message}`
    
    if (context) {
      const { module: _, ...restContext } = context
      if (Object.keys(restContext).length > 0) {
        formatted += ` ${JSON.stringify(restContext)}`
      }
    }
    
    return formatted
  }
  
  private log(level: ClientLogLevel, message: string, context?: ClientLogContext) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      context
    }
    
    // 添加到缓冲区
    this.logBuffer.push(logEntry)
    
    // 如果缓冲区满了，立即发送
    if (this.logBuffer.length >= this.maxBufferSize) {
      this.flush()
    }
    
    // 控制台输出
    const formatted = this.formatMessage(level, message, context)
    
    switch (level) {
      case ClientLogLevel.ERROR:
        console.error(formatted)
        break
      case ClientLogLevel.WARN:
        console.warn(formatted)
        break
      case ClientLogLevel.INFO:
        console.info(formatted)
        break
      default:
        console.log(formatted)
    }
  }
  
  debug(message: string, context?: ClientLogContext) {
    this.log(ClientLogLevel.DEBUG, message, context)
  }
  
  info(message: string, context?: ClientLogContext) {
    this.log(ClientLogLevel.INFO, message, context)
  }
  
  warn(message: string, context?: ClientLogContext) {
    this.log(ClientLogLevel.WARN, message, context)
  }
  
  error(message: string, context?: ClientLogContext) {
    this.log(ClientLogLevel.ERROR, message, context)
  }
  
  /**
   * 记录用户操作
   */
  logUserAction(action: string, data?: any) {
    this.info('用户操作', {
      module: 'UserAction',
      action,
      data,
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : undefined,
      timestamp: Date.now()
    })
  }
  
  /**
   * 记录API调用
   */
  logAPICall(endpoint: string, method: string, duration: number, status: number, error?: string) {
    const level = status >= 400 ? ClientLogLevel.ERROR : ClientLogLevel.INFO
    const message = status >= 400 ? 'API调用失败' : 'API调用成功'
    
    this.log(level, message, {
      module: 'APICall',
      endpoint,
      method,
      duration,
      status,
      error
    })
  }
  
  /**
   * 记录页面性能
   */
  logPerformance(metric: string, value: number, threshold?: number) {
    const context: ClientLogContext = {
      module: 'Performance',
      metric,
      value
    }
    
    if (threshold && value > threshold) {
      context.threshold = threshold
      this.warn('性能指标超过阈值', context)
    } else {
      this.info('性能指标', context)
    }
  }
  
  /**
   * 发送日志到服务器
   */
  async flush(immediate = false) {
    if (this.logBuffer.length === 0) return
    
    const logs = [...this.logBuffer]
    this.logBuffer = []
    
    try {
      const response = await fetch('/api/logs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ logs }),
        // 如果是页面卸载，使用 keepalive
        keepalive: immediate
      })
      
      if (!response.ok) {
        console.error('Failed to send logs to server:', response.status)
        // 如果发送失败，将日志重新加入缓冲区
        this.logBuffer.unshift(...logs)
      }
    } catch (error) {
      console.error('Error sending logs to server:', error)
      // 如果发送失败，将日志重新加入缓冲区
      this.logBuffer.unshift(...logs)
    }
  }
  
  /**
   * 清理资源
   */
  destroy() {
    if (this.sendInterval) {
      clearInterval(this.sendInterval)
      this.sendInterval = null
    }
    
    this.flush(true)
  }
}

export const clientLogger = ClientLogger.getInstance()

/**
 * React Hook 用于组件生命周期日志
 */
export function useComponentLogger(componentName: string) {
  if (typeof window === 'undefined') return { logMount: () => {}, logUnmount: () => {}, logRender: () => {} }
  
  const logMount = () => {
    clientLogger.debug('组件挂载', {
      module: 'Component',
      component: componentName
    })
  }
  
  const logUnmount = () => {
    clientLogger.debug('组件卸载', {
      module: 'Component',
      component: componentName
    })
  }
  
  const logRender = (props?: any) => {
    clientLogger.debug('组件渲染', {
      module: 'Component',
      component: componentName,
      props
    })
  }
  
  return { logMount, logUnmount, logRender }
}

/**
 * 错误边界日志
 */
export function logErrorBoundary(error: Error, errorInfo: any, componentStack?: string) {
  clientLogger.error('React错误边界捕获错误', {
    module: 'ErrorBoundary',
    error: error.message,
    stack: error.stack,
    componentStack,
    errorInfo
  })
}

/**
 * 表单操作日志
 */
export class FormLogger {
  private formName: string
  private startTime: number
  private fieldChanges: Map<string, number> = new Map()
  
  constructor(formName: string) {
    this.formName = formName
    this.startTime = Date.now()
    
    clientLogger.info('表单开始填写', {
      module: 'Form',
      formName: this.formName
    })
  }
  
  logFieldChange(fieldName: string, value: any) {
    const changeCount = (this.fieldChanges.get(fieldName) || 0) + 1
    this.fieldChanges.set(fieldName, changeCount)
    
    clientLogger.debug('表单字段变更', {
      module: 'Form',
      formName: this.formName,
      fieldName,
      changeCount
    })
  }
  
  logValidation(fieldName: string, isValid: boolean, error?: string) {
    const level = isValid ? ClientLogLevel.DEBUG : ClientLogLevel.WARN
    
    clientLogger.log(level, '表单验证', {
      module: 'Form',
      formName: this.formName,
      fieldName,
      isValid,
      error
    })
  }
  
  logSubmit(success: boolean, data?: any, error?: string) {
    const duration = Date.now() - this.startTime
    const totalChanges = Array.from(this.fieldChanges.values()).reduce((a, b) => a + b, 0)
    
    if (success) {
      clientLogger.info('表单提交成功', {
        module: 'Form',
        formName: this.formName,
        duration,
        totalChanges,
        fieldsChanged: this.fieldChanges.size
      })
    } else {
      clientLogger.error('表单提交失败', {
        module: 'Form',
        formName: this.formName,
        duration,
        totalChanges,
        error
      })
    }
  }
  
  logCancel() {
    const duration = Date.now() - this.startTime
    
    clientLogger.info('表单取消', {
      module: 'Form',
      formName: this.formName,
      duration,
      fieldsChanged: this.fieldChanges.size
    })
  }
}

export default clientLogger