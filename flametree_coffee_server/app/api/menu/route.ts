import { NextRequest, NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'

const dataPath = path.join(process.cwd(), 'data', 'menu.json')

export async function GET() {
  try {
    const data = fs.readFileSync(dataPath, 'utf8')
    const menuData = JSON.parse(data)
    
    return NextResponse.json(menuData.coffeeMenu)
  } catch (error) {
    console.error('Error reading menu data:', error)
    return NextResponse.json({ error: 'Failed to load menu' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const newItem = await request.json()
    const data = fs.readFileSync(dataPath, 'utf8')
    const menuData = JSON.parse(data)
    
    menuData.coffeeMenu.push({
      id: Date.now().toString(),
      ...newItem
    })
    
    fs.writeFileSync(dataPath, JSON.stringify(menuData, null, 2))
    
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error adding menu item:', error)
    return NextResponse.json({ error: 'Failed to add menu item' }, { status: 500 })
  }
}