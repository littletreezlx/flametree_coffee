import { NextRequest, NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { logger, OperationLogger } from '@/lib/logger'

const dataPath = path.join(process.cwd(), 'data', 'orders.json')
const MODULE_NAME = 'MembersAPI'

export async function GET(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '获取家庭成员列表')
  
  try {
    operation.logStep('读取数据文件', { path: dataPath })
    const data = fs.readFileSync(dataPath, 'utf8')
    
    operation.logStep('解析成员数据')
    const ordersData = JSON.parse(data)
    
    const members = ordersData.familyMembers || []
    
    logger.info('家庭成员数据加载成功', {
      module: MODULE_NAME,
      memberCount: members.length,
      members: members.map((m: any) => ({ id: m.id, name: m.name }))
    })
    
    operation.complete({ memberCount: members.length })
    return NextResponse.json(members)
  } catch (error) {
    operation.fail(error as Error)
    logger.error('家庭成员数据读取失败', {
      module: MODULE_NAME,
      error: error.message,
      stack: error.stack
    })
    return NextResponse.json({ error: 'Failed to load family members' }, { status: 500 })
  }
}