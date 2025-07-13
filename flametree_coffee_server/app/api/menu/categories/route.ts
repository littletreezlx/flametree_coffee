import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'

const dataPath = path.join(process.cwd(), 'data', 'menu.json')

export async function GET() {
  try {
    const data = fs.readFileSync(dataPath, 'utf8')
    const menuData = JSON.parse(data)
    
    const categories = [...new Set(menuData.coffeeMenu.map((item: any) => item.category))]
    
    return NextResponse.json(categories)
  } catch (error) {
    console.error('Error reading categories:', error)
    return NextResponse.json({ error: 'Failed to load categories' }, { status: 500 })
  }
}