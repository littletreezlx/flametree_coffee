/**
 * 数据访问层日志包装器
 * 为所有文件系统操作提供统一的日志记录
 */

import fs from 'fs'
import path from 'path'
import { logger } from './logger'

const MODULE_NAME = 'DataAccess'

export class DataLogger {
  /**
   * 读取JSON文件并记录日志
   */
  static readJSON(filePath: string, operation: string): any {
    const startTime = Date.now()
    const fileName = path.basename(filePath)
    
    logger.debug('开始读取数据文件', {
      module: MODULE_NAME,
      operation,
      file: fileName,
      path: filePath
    })
    
    try {
      const data = fs.readFileSync(filePath, 'utf8')
      const parsed = JSON.parse(data)
      
      const duration = Date.now() - startTime
      const fileSize = Buffer.byteLength(data, 'utf8')
      
      logger.info('数据文件读取成功', {
        module: MODULE_NAME,
        operation,
        file: fileName,
        fileSize,
        duration,
        recordCount: Array.isArray(parsed) ? parsed.length : Object.keys(parsed).length
      })
      
      if (duration > 100) {
        logger.warn('数据文件读取缓慢', {
          module: MODULE_NAME,
          operation,
          file: fileName,
          duration,
          threshold: 100
        })
      }
      
      return parsed
    } catch (error) {
      const duration = Date.now() - startTime
      
      logger.error('数据文件读取失败', {
        module: MODULE_NAME,
        operation,
        file: fileName,
        duration,
        error: error.message,
        stack: error.stack
      })
      
      throw error
    }
  }
  
  /**
   * 写入JSON文件并记录日志
   */
  static writeJSON(filePath: string, data: any, operation: string): void {
    const startTime = Date.now()
    const fileName = path.basename(filePath)
    
    logger.debug('开始写入数据文件', {
      module: MODULE_NAME,
      operation,
      file: fileName,
      path: filePath
    })
    
    try {
      const jsonString = JSON.stringify(data, null, 2)
      const fileSize = Buffer.byteLength(jsonString, 'utf8')
      
      // 备份原文件
      if (fs.existsSync(filePath)) {
        const backupPath = `${filePath}.backup`
        fs.copyFileSync(filePath, backupPath)
        
        logger.debug('创建数据文件备份', {
          module: MODULE_NAME,
          operation,
          original: fileName,
          backup: path.basename(backupPath)
        })
      }
      
      fs.writeFileSync(filePath, jsonString)
      
      const duration = Date.now() - startTime
      
      logger.info('数据文件写入成功', {
        module: MODULE_NAME,
        operation,
        file: fileName,
        fileSize,
        duration,
        recordCount: Array.isArray(data) ? data.length : Object.keys(data).length
      })
      
      if (duration > 200) {
        logger.warn('数据文件写入缓慢', {
          module: MODULE_NAME,
          operation,
          file: fileName,
          duration,
          threshold: 200
        })
      }
    } catch (error) {
      const duration = Date.now() - startTime
      
      logger.error('数据文件写入失败', {
        module: MODULE_NAME,
        operation,
        file: fileName,
        duration,
        error: error.message,
        stack: error.stack
      })
      
      // 尝试恢复备份
      const backupPath = `${filePath}.backup`
      if (fs.existsSync(backupPath)) {
        try {
          fs.copyFileSync(backupPath, filePath)
          logger.info('从备份恢复数据文件', {
            module: MODULE_NAME,
            operation,
            file: fileName
          })
        } catch (restoreError) {
          logger.fatal('数据文件恢复失败', {
            module: MODULE_NAME,
            operation,
            file: fileName,
            error: restoreError.message
          })
        }
      }
      
      throw error
    }
  }
  
  /**
   * 检查文件是否存在并记录日志
   */
  static exists(filePath: string): boolean {
    const fileName = path.basename(filePath)
    const exists = fs.existsSync(filePath)
    
    logger.debug('检查文件存在性', {
      module: MODULE_NAME,
      file: fileName,
      exists
    })
    
    return exists
  }
  
  /**
   * 获取文件统计信息并记录日志
   */
  static async getStats(filePath: string): Promise<fs.Stats | null> {
    const fileName = path.basename(filePath)
    
    try {
      const stats = await fs.promises.stat(filePath)
      
      logger.debug('获取文件统计信息', {
        module: MODULE_NAME,
        file: fileName,
        size: stats.size,
        modified: stats.mtime,
        created: stats.birthtime
      })
      
      return stats
    } catch (error) {
      logger.error('获取文件统计信息失败', {
        module: MODULE_NAME,
        file: fileName,
        error: error.message
      })
      
      return null
    }
  }
  
  /**
   * 创建目录并记录日志
   */
  static ensureDirectory(dirPath: string): void {
    const dirName = path.basename(dirPath)
    
    if (!fs.existsSync(dirPath)) {
      try {
        fs.mkdirSync(dirPath, { recursive: true })
        
        logger.info('创建目录成功', {
          module: MODULE_NAME,
          directory: dirName,
          path: dirPath
        })
      } catch (error) {
        logger.error('创建目录失败', {
          module: MODULE_NAME,
          directory: dirName,
          path: dirPath,
          error: error.message
        })
        
        throw error
      }
    } else {
      logger.debug('目录已存在', {
        module: MODULE_NAME,
        directory: dirName,
        path: dirPath
      })
    }
  }
  
  /**
   * 清理过期备份文件
   */
  static async cleanupBackups(directory: string, daysToKeep: number = 7): Promise<void> {
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
            
            logger.debug('删除过期备份文件', {
              module: MODULE_NAME,
              file,
              age: daysToKeep
            })
          }
        }
      }
      
      if (cleanedCount > 0) {
        logger.info('清理备份文件完成', {
          module: MODULE_NAME,
          directory,
          cleanedCount,
          daysToKeep
        })
      }
    } catch (error) {
      logger.error('清理备份文件失败', {
        module: MODULE_NAME,
        directory,
        error: error.message
      })
    }
  }
}

/**
 * 数据操作事务日志
 */
export class DataTransaction {
  private transactionId: string
  private operations: Array<{
    type: string
    target: string
    timestamp: number
    success: boolean
    error?: string
  }> = []
  private startTime: number
  
  constructor(operation: string) {
    this.transactionId = `txn-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    this.startTime = Date.now()
    
    logger.info('数据事务开始', {
      module: MODULE_NAME,
      transactionId: this.transactionId,
      operation
    })
  }
  
  logOperation(type: string, target: string, success: boolean, error?: string) {
    const operation = {
      type,
      target,
      timestamp: Date.now(),
      success,
      error
    }
    
    this.operations.push(operation)
    
    logger.debug('事务操作记录', {
      module: MODULE_NAME,
      transactionId: this.transactionId,
      ...operation
    })
  }
  
  commit() {
    const duration = Date.now() - this.startTime
    const successCount = this.operations.filter(op => op.success).length
    const failureCount = this.operations.filter(op => !op.success).length
    
    logger.info('数据事务提交', {
      module: MODULE_NAME,
      transactionId: this.transactionId,
      duration,
      totalOperations: this.operations.length,
      successCount,
      failureCount
    })
  }
  
  rollback(reason: string) {
    const duration = Date.now() - this.startTime
    
    logger.warn('数据事务回滚', {
      module: MODULE_NAME,
      transactionId: this.transactionId,
      duration,
      reason,
      operations: this.operations
    })
  }
}

export default DataLogger