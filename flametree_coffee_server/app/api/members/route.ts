import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'

const dataPath = path.join(process.cwd(), 'data', 'orders.json')

export async function GET() {
  try {
    const data = fs.readFileSync(dataPath, 'utf8')
    const ordersData = JSON.parse(data)
    
    return NextResponse.json(ordersData.familyMembers)
  } catch (error) {
    console.error('Error reading family members:', error)
    return NextResponse.json({ error: 'Failed to load family members' }, { status: 500 })
  }
}