import { NextRequest, NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { logger, OperationLogger } from '@/lib/logger'

const dataPath = path.join(process.cwd(), 'data', 'menu.json')
const MODULE_NAME = 'MenuAPI'

export async function GET(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '获取菜单列表')
  const perf = logger.measurePerformance('读取菜单数据', 500)
  
  try {
    operation.logStep('读取菜单文件', { path: dataPath })
    const data = fs.readFileSync(dataPath, 'utf8')
    
    operation.logStep('解析菜单数据')
    const menuData = JSON.parse(data)
    
    const duration = perf.end({ module: MODULE_NAME })
    
    logger.info('菜单数据加载成功', {
      module: MODULE_NAME,
      itemCount: menuData.coffeeMenu?.length || 0,
      duration
    })
    
    operation.complete({ itemCount: menuData.coffeeMenu?.length })
    return NextResponse.json(menuData.coffeeMenu)
  } catch (error) {
    operation.fail(error as Error)
    logger.error('菜单数据读取失败', {
      module: MODULE_NAME,
      error: error.message,
      stack: error.stack
    })
    return NextResponse.json({ error: 'Failed to load menu' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '添加菜单项')
  
  try {
    operation.logStep('解析请求数据')
    const newItem = await request.json()
    
    logger.info('接收新菜单项', {
      module: MODULE_NAME,
      itemName: newItem.name,
      category: newItem.category,
      price: newItem.price
    })
    
    operation.logStep('读取现有菜单')
    const data = fs.readFileSync(dataPath, 'utf8')
    const menuData = JSON.parse(data)
    
    const newMenuItemWithId = {
      id: Date.now().toString(),
      ...newItem
    }
    
    operation.logStep('添加新菜单项', { id: newMenuItemWithId.id })
    menuData.coffeeMenu.push(newMenuItemWithId)
    
    operation.logStep('保存更新后的菜单')
    fs.writeFileSync(dataPath, JSON.stringify(menuData, null, 2))
    
    logger.info('菜单项添加成功', {
      module: MODULE_NAME,
      itemId: newMenuItemWithId.id,
      itemName: newItem.name,
      totalItems: menuData.coffeeMenu.length
    })
    
    operation.complete({ itemId: newMenuItemWithId.id })
    return NextResponse.json({ success: true, id: newMenuItemWithId.id })
  } catch (error) {
    operation.fail(error as Error)
    logger.error('添加菜单项失败', {
      module: MODULE_NAME,
      error: error.message,
      stack: error.stack
    })
    return NextResponse.json({ error: 'Failed to add menu item' }, { status: 500 })
  }
}