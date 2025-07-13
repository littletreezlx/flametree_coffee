'use client'

import { useState, useEffect } from 'react'

interface FamilyMember {
  id: string
  name: string
  avatar: string
}

interface Order {
  id: string
  memberId: string
  memberName: string
  items: any[]
  totalPrice: number
  status: string
  createdAt: string
}

export default function AdminPage() {
  const [members, setMembers] = useState<FamilyMember[]>([])
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [editingMember, setEditingMember] = useState<FamilyMember | null>(null)
  const [newMember, setNewMember] = useState({ name: '', avatar: '' })

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      const [membersRes, ordersRes] = await Promise.all([
        fetch('/api/members'),
        fetch('/api/orders')
      ])
      
      if (membersRes.ok && ordersRes.ok) {
        const membersData = await membersRes.json()
        const ordersData = await ordersRes.json()
        setMembers(membersData)
        setOrders(ordersData)
      }
    } catch (error) {
      console.error('Error loading data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSaveMember = async () => {
    // This would be implemented with a PUT/POST API
    console.log('Save member:', editingMember || newMember)
    setEditingMember(null)
    setNewMember({ name: '', avatar: '' })
    // Reload data
    loadData()
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-orange-50 to-orange-100 flex items-center justify-center">
        <div className="text-orange-600 text-xl">加载中...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-orange-100">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-orange-800 mb-2">
            🔥🌳 火树咖啡厅管理后台
          </h1>
          <p className="text-orange-600">家庭成员与订单管理</p>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* 家庭成员管理 */}
          <div className="bg-white rounded-2xl shadow-lg p-6">
            <h2 className="text-2xl font-bold text-orange-800 mb-6 flex items-center">
              <span className="mr-2">👨‍👩‍👧‍👦</span>
              家庭成员管理
            </h2>
            
            {/* 成员列表 */}
            <div className="space-y-4 mb-6">
              {members.map((member) => (
                <div key={member.id} className="flex items-center justify-between p-4 bg-orange-50 rounded-lg">
                  <div className="flex items-center space-x-4">
                    <span className="text-3xl">{member.avatar}</span>
                    <div>
                      <div className="font-semibold text-orange-800">{member.name}</div>
                      <div className="text-sm text-orange-600">ID: {member.id}</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="bg-red-100 text-red-800 px-3 py-1 rounded-full text-sm font-semibold">
                      ❤️ 10000
                    </span>
                    <button
                      onClick={() => setEditingMember(member)}
                      className="bg-orange-500 text-white px-3 py-1 rounded hover:bg-orange-600 text-sm"
                    >
                      编辑
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* 添加新成员表单 */}
            <div className="border-t pt-6">
              <h3 className="text-lg font-semibold text-orange-800 mb-4">添加新成员</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-orange-700 mb-2">姓名</label>
                  <input
                    type="text"
                    value={newMember.name}
                    onChange={(e) => setNewMember({...newMember, name: e.target.value})}
                    className="w-full px-3 py-2 border border-orange-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                    placeholder="输入姓名"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-orange-700 mb-2">头像 (Emoji)</label>
                  <input
                    type="text"
                    value={newMember.avatar}
                    onChange={(e) => setNewMember({...newMember, avatar: e.target.value})}
                    className="w-full px-3 py-2 border border-orange-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                    placeholder="😊"
                  />
                </div>
              </div>
              <button
                onClick={handleSaveMember}
                disabled={!newMember.name || !newMember.avatar}
                className="mt-4 w-full bg-orange-500 text-white py-2 rounded-lg hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                添加成员
              </button>
            </div>
          </div>

          {/* 订单管理 */}
          <div className="bg-white rounded-2xl shadow-lg p-6">
            <h2 className="text-2xl font-bold text-orange-800 mb-6 flex items-center">
              <span className="mr-2">📋</span>
              订单管理
            </h2>
            
            <div className="space-y-4 max-h-96 overflow-y-auto">
              {orders.map((order) => (
                <div key={order.id} className="p-4 bg-orange-50 rounded-lg">
                  <div className="flex justify-between items-start mb-2">
                    <div className="flex items-center space-x-2">
                      <span className="font-semibold text-orange-800">{order.memberName}</span>
                      <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                        order.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                        order.status === 'preparing' ? 'bg-blue-100 text-blue-800' :
                        order.status === 'ready' ? 'bg-green-100 text-green-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {order.status === 'pending' ? '待处理' :
                         order.status === 'preparing' ? '制作中' :
                         order.status === 'ready' ? '已完成' : '已取餐'}
                      </span>
                    </div>
                    <div className="text-sm text-orange-600">
                      {new Date(order.createdAt).toLocaleString()}
                    </div>
                  </div>
                  
                  <div className="text-sm text-gray-600 mb-2">
                    {order.items.map((item, index) => (
                      <div key={index}>
                        {item.name} ({item.temperature === 'ice' ? '冰' : '热'}) x{item.quantity}
                      </div>
                    ))}
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <div className="font-semibold text-orange-800">
                      ❤️ {order.totalPrice}
                    </div>
                    <div className="space-x-2">
                      <button className="bg-blue-500 text-white px-3 py-1 rounded text-xs hover:bg-blue-600">
                        制作中
                      </button>
                      <button className="bg-green-500 text-white px-3 py-1 rounded text-xs hover:bg-green-600">
                        完成
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 统计信息 */}
        <div className="mt-8 grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-lg p-6 text-center shadow-lg">
            <div className="text-3xl font-bold text-orange-600">{members.length}</div>
            <div className="text-orange-800">家庭成员</div>
          </div>
          <div className="bg-white rounded-lg p-6 text-center shadow-lg">
            <div className="text-3xl font-bold text-blue-600">{orders.length}</div>
            <div className="text-blue-800">总订单数</div>
          </div>
          <div className="bg-white rounded-lg p-6 text-center shadow-lg">
            <div className="text-3xl font-bold text-green-600">
              {orders.filter(o => o.status === 'pending').length}
            </div>
            <div className="text-green-800">待处理</div>
          </div>
          <div className="bg-white rounded-lg p-6 text-center shadow-lg">
            <div className="text-3xl font-bold text-purple-600">
              ❤️ {orders.reduce((sum, order) => sum + order.totalPrice, 0)}
            </div>
            <div className="text-purple-800">总爱心值</div>
          </div>
        </div>
      </div>

      {/* 编辑成员模态框 */}
      {editingMember && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-96 max-w-90vw">
            <h3 className="text-xl font-bold text-orange-800 mb-4">编辑成员</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-orange-700 mb-2">姓名</label>
                <input
                  type="text"
                  value={editingMember.name}
                  onChange={(e) => setEditingMember({...editingMember, name: e.target.value})}
                  className="w-full px-3 py-2 border border-orange-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-orange-700 mb-2">头像</label>
                <input
                  type="text"
                  value={editingMember.avatar}
                  onChange={(e) => setEditingMember({...editingMember, avatar: e.target.value})}
                  className="w-full px-3 py-2 border border-orange-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                />
              </div>
            </div>
            <div className="flex space-x-4 mt-6">
              <button
                onClick={handleSaveMember}
                className="flex-1 bg-orange-500 text-white py-2 rounded-lg hover:bg-orange-600"
              >
                保存
              </button>
              <button
                onClick={() => setEditingMember(null)}
                className="flex-1 bg-gray-500 text-white py-2 rounded-lg hover:bg-gray-600"
              >
                取消
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}