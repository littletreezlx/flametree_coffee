import { NextRequest, NextResponse } from 'next/server'
import { logger, OperationLogger } from '@/lib/logger'
import { getLogStats, exportLogs } from '@/lib/logger-config'

const MODULE_NAME = 'LogsAPI'

/**
 * 接收客户端日志
 */
export async function POST(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '接收客户端日志')
  
  try {
    const { logs } = await request.json()
    
    if (!Array.isArray(logs)) {
      logger.warn('无效的日志数据格式', {
        module: MODULE_NAME,
        dataType: typeof logs
      })
      return NextResponse.json({ error: 'Invalid log format' }, { status: 400 })
    }
    
    operation.logStep('处理客户端日志', { count: logs.length })
    
    // 处理每条日志
    for (const log of logs) {
      const { level, message, context, timestamp } = log
      
      // 根据级别记录日志
      switch (level) {
        case 'error':
          logger.error(`[Client] ${message}`, {
            ...context,
            module: 'ClientLog',
            clientTimestamp: timestamp
          })
          break
        case 'warn':
          logger.warn(`[Client] ${message}`, {
            ...context,
            module: 'ClientLog',
            clientTimestamp: timestamp
          })
          break
        case 'info':
          logger.info(`[Client] ${message}`, {
            ...context,
            module: 'ClientLog',
            clientTimestamp: timestamp
          })
          break
        default:
          logger.debug(`[Client] ${message}`, {
            ...context,
            module: 'ClientLog',
            clientTimestamp: timestamp
          })
      }
    }
    
    operation.complete({ processedCount: logs.length })
    return NextResponse.json({ success: true, processed: logs.length })
  } catch (error) {
    operation.fail(error as Error)
    logger.error('处理客户端日志失败', {
      module: MODULE_NAME,
      error: error.message,
      stack: error.stack
    })
    return NextResponse.json({ error: 'Failed to process logs' }, { status: 500 })
  }
}

/**
 * 获取日志统计信息
 */
export async function GET(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '获取日志统计')
  const { searchParams } = request.nextUrl
  const action = searchParams.get('action')
  
  try {
    if (action === 'stats') {
      operation.logStep('获取日志统计信息')
      const stats = await getLogStats()
      
      logger.info('日志统计信息获取成功', {
        module: MODULE_NAME,
        stats
      })
      
      operation.complete(stats)
      return NextResponse.json(stats)
    } else if (action === 'export') {
      operation.logStep('导出日志')
      
      const startDate = searchParams.get('start')
      const endDate = searchParams.get('end')
      const level = searchParams.get('level')
      
      if (!startDate || !endDate) {
        logger.warn('缺少必要的导出参数', {
          module: MODULE_NAME,
          startDate,
          endDate
        })
        return NextResponse.json({ error: 'Start and end dates are required' }, { status: 400 })
      }
      
      const logs = await exportLogs(
        new Date(startDate),
        new Date(endDate),
        level || undefined
      )
      
      logger.info('日志导出成功', {
        module: MODULE_NAME,
        exportCount: logs.length,
        dateRange: { startDate, endDate },
        level
      })
      
      operation.complete({ exportCount: logs.length })
      return NextResponse.json(logs)
    } else {
      logger.warn('未知的日志操作', {
        module: MODULE_NAME,
        action
      })
      return NextResponse.json({ error: 'Unknown action' }, { status: 400 })
    }
  } catch (error) {
    operation.fail(error as Error)
    logger.error('日志操作失败', {
      module: MODULE_NAME,
      action,
      error: error.message,
      stack: error.stack
    })
    return NextResponse.json({ error: 'Failed to perform log operation' }, { status: 500 })
  }
}