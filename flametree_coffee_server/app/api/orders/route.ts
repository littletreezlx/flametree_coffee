import { NextRequest, NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { logger, OperationLogger } from '@/lib/logger'

const dataPath = path.join(process.cwd(), 'data', 'orders.json')
const MODULE_NAME = 'OrdersAPI'

interface OrderItem {
  id: string
  name: string
  temperature: 'ice' | 'hot'
  quantity: number
  price: number
}

interface Order {
  id: string
  memberId: string
  memberName: string
  items: OrderItem[]
  totalPrice: number
  status: 'pending' | 'preparing' | 'ready' | 'completed'
  createdAt: string
}

export async function GET(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '获取订单列表')
  const perf = logger.measurePerformance('读取订单数据', 500)
  
  try {
    operation.logStep('读取订单文件', { path: dataPath })
    const data = fs.readFileSync(dataPath, 'utf8')
    
    operation.logStep('解析订单数据')
    const ordersData = JSON.parse(data)
    
    const duration = perf.end({ module: MODULE_NAME })
    
    const stats = {
      total: ordersData.orders?.length || 0,
      pending: ordersData.orders?.filter((o: Order) => o.status === 'pending').length || 0,
      preparing: ordersData.orders?.filter((o: Order) => o.status === 'preparing').length || 0,
      ready: ordersData.orders?.filter((o: Order) => o.status === 'ready').length || 0,
      completed: ordersData.orders?.filter((o: Order) => o.status === 'completed').length || 0
    }
    
    logger.info('订单数据加载成功', {
      module: MODULE_NAME,
      ...stats,
      duration
    })
    
    operation.complete(stats)
    return NextResponse.json(ordersData.orders)
  } catch (error) {
    operation.fail(error as Error)
    logger.error('订单数据读取失败', {
      module: MODULE_NAME,
      error: error.message,
      stack: error.stack
    })
    return NextResponse.json({ error: 'Failed to load orders' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  const operation = new OperationLogger(MODULE_NAME, '创建订单')
  
  try {
    operation.logStep('解析订单数据')
    const orderData = await request.json()
    
    logger.info('接收新订单', {
      module: MODULE_NAME,
      memberId: orderData.memberId,
      memberName: orderData.memberName,
      itemCount: orderData.items?.length || 0,
      totalPrice: orderData.totalPrice
    })
    
    operation.logStep('读取现有订单')
    const data = fs.readFileSync(dataPath, 'utf8')
    const ordersData = JSON.parse(data)
    
    const newOrder: Order = {
      id: Date.now().toString(),
      memberId: orderData.memberId,
      memberName: orderData.memberName,
      items: orderData.items,
      totalPrice: orderData.totalPrice,
      status: 'pending',
      createdAt: new Date().toISOString()
    }
    
    operation.logStep('创建新订单', {
      orderId: newOrder.id,
      items: newOrder.items.map((item: OrderItem) => ({
        name: item.name,
        quantity: item.quantity,
        temperature: item.temperature
      }))
    })
    
    ordersData.orders.push(newOrder)
    
    operation.logStep('保存订单数据')
    fs.writeFileSync(dataPath, JSON.stringify(ordersData, null, 2))
    
    logger.info('订单创建成功', {
      module: MODULE_NAME,
      orderId: newOrder.id,
      memberId: newOrder.memberId,
      memberName: newOrder.memberName,
      totalPrice: newOrder.totalPrice,
      itemCount: newOrder.items.length
    })
    
    operation.complete({ orderId: newOrder.id })
    return NextResponse.json({ success: true, orderId: newOrder.id })
  } catch (error) {
    operation.fail(error as Error)
    logger.error('创建订单失败', {
      module: MODULE_NAME,
      error: error.message,
      stack: error.stack,
      orderData
    })
    return NextResponse.json({ error: 'Failed to create order' }, { status: 500 })
  }
}