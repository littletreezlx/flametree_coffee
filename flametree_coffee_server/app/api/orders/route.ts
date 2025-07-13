import { NextRequest, NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'

const dataPath = path.join(process.cwd(), 'data', 'orders.json')

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

export async function GET() {
  try {
    const data = fs.readFileSync(dataPath, 'utf8')
    const ordersData = JSON.parse(data)
    
    return NextResponse.json(ordersData.orders)
  } catch (error) {
    console.error('Error reading orders:', error)
    return NextResponse.json({ error: 'Failed to load orders' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const orderData = await request.json()
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
    
    ordersData.orders.push(newOrder)
    
    fs.writeFileSync(dataPath, JSON.stringify(ordersData, null, 2))
    
    return NextResponse.json({ success: true, orderId: newOrder.id })
  } catch (error) {
    console.error('Error creating order:', error)
    return NextResponse.json({ error: 'Failed to create order' }, { status: 500 })
  }
}