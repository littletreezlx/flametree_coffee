/**
 * Next.js 中间件
 * 提供请求日志、性能监控、错误处理等功能
 */

import { NextRequest, NextResponse } from 'next/server'
import { logger } from './lib/logger'

// 定义需要监控的API路径
const API_PATHS = ['/api/menu', '/api/orders', '/api/members', '/api/update']

// 定义性能阈值（毫秒）
const PERFORMANCE_THRESHOLDS = {
  '/api/menu': 500,
  '/api/orders': 800,
  '/api/members': 500,
  '/api/update': 1000,
  default: 1000
}

export function middleware(request: NextRequest) {
  const startTime = Date.now()
  const { pathname, searchParams } = request.nextUrl
  const method = request.method
  
  // 生成请求追踪ID
  const traceId = generateTraceId()
  
  // 添加追踪ID到响应头
  const requestHeaders = new Headers(request.headers)
  requestHeaders.set('x-trace-id', traceId)
  
  // 判断是否是API请求
  const isAPIRequest = pathname.startsWith('/api/')
  
  // 记录请求开始
  if (isAPIRequest) {
    logger.info('HTTP请求接收', {
      module: 'Middleware',
      traceId,
      method,
      path: pathname,
      query: Object.fromEntries(searchParams),
      userAgent: request.headers.get('user-agent'),
      referer: request.headers.get('referer'),
      ip: request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip')
    })
  }
  
  // 创建响应包装器以记录响应信息
  const response = NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  })
  
  // 添加追踪ID到响应头
  response.headers.set('x-trace-id', traceId)
  
  // 计算请求处理时间
  const duration = Date.now() - startTime
  
  // 获取性能阈值
  const threshold = PERFORMANCE_THRESHOLDS[pathname] || PERFORMANCE_THRESHOLDS.default
  
  // 记录性能监控
  if (isAPIRequest) {
    if (duration > threshold) {
      logger.warn('请求处理缓慢', {
        module: 'Middleware',
        traceId,
        method,
        path: pathname,
        duration,
        threshold
      })
    } else {
      logger.debug('请求处理完成', {
        module: 'Middleware',
        traceId,
        method,
        path: pathname,
        duration
      })
    }
    
    // 添加性能监控头
    response.headers.set('x-response-time', `${duration}ms`)
  }
  
  // 添加安全头
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-XSS-Protection', '1; mode=block')
  
  // CORS 处理（如果需要）
  if (request.headers.get('origin')) {
    response.headers.set('Access-Control-Allow-Origin', '*')
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    response.headers.set('Access-Control-Max-Age', '86400')
  }
  
  return response
}

// 配置中间件匹配路径
export const config = {
  matcher: [
    // 匹配所有API路由
    '/api/:path*',
    // 匹配管理后台
    '/admin/:path*',
    // 排除静态资源
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
}

/**
 * 生成追踪ID
 */
function generateTraceId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

/**
 * 错误处理中间件（用于API路由）
 */
export function withErrorHandler(handler: Function) {
  return async (request: NextRequest, context: any) => {
    const traceId = request.headers.get('x-trace-id') || generateTraceId()
    
    try {
      return await handler(request, context)
    } catch (error) {
      logger.error('API处理异常', {
        module: 'ErrorHandler',
        traceId,
        path: request.nextUrl.pathname,
        method: request.method,
        error: error.message,
        stack: error.stack
      })
      
      return NextResponse.json(
        {
          error: 'Internal Server Error',
          message: process.env.NODE_ENV === 'development' ? error.message : 'An error occurred',
          traceId
        },
        {
          status: 500,
          headers: {
            'x-trace-id': traceId
          }
        }
      )
    }
  }
}

/**
 * 性能监控装饰器
 */
export function measurePerformance(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value
  
  descriptor.value = async function(...args: any[]) {
    const startTime = Date.now()
    const methodName = `${target.constructor.name}.${propertyKey}`
    
    logger.debug('方法执行开始', {
      module: 'Performance',
      method: methodName
    })
    
    try {
      const result = await originalMethod.apply(this, args)
      const duration = Date.now() - startTime
      
      logger.info('方法执行完成', {
        module: 'Performance',
        method: methodName,
        duration
      })
      
      return result
    } catch (error) {
      const duration = Date.now() - startTime
      
      logger.error('方法执行失败', {
        module: 'Performance',
        method: methodName,
        duration,
        error: error.message
      })
      
      throw error
    }
  }
  
  return descriptor
}

/**
 * 请求限流中间件
 */
class RateLimiter {
  private requests: Map<string, number[]> = new Map()
  private readonly windowMs: number = 60000 // 1分钟
  private readonly maxRequests: number = 100 // 每分钟最多100个请求
  
  isAllowed(identifier: string): boolean {
    const now = Date.now()
    const requests = this.requests.get(identifier) || []
    
    // 清理过期的请求记录
    const validRequests = requests.filter(time => now - time < this.windowMs)
    
    if (validRequests.length >= this.maxRequests) {
      logger.warn('请求限流触发', {
        module: 'RateLimiter',
        identifier,
        requestCount: validRequests.length,
        limit: this.maxRequests
      })
      return false
    }
    
    validRequests.push(now)
    this.requests.set(identifier, validRequests)
    
    // 定期清理过期记录
    if (Math.random() < 0.01) {
      this.cleanup()
    }
    
    return true
  }
  
  private cleanup() {
    const now = Date.now()
    
    for (const [identifier, requests] of this.requests.entries()) {
      const validRequests = requests.filter(time => now - time < this.windowMs)
      
      if (validRequests.length === 0) {
        this.requests.delete(identifier)
      } else {
        this.requests.set(identifier, validRequests)
      }
    }
    
    logger.debug('限流器清理完成', {
      module: 'RateLimiter',
      remainingIdentifiers: this.requests.size
    })
  }
}

export const rateLimiter = new RateLimiter()