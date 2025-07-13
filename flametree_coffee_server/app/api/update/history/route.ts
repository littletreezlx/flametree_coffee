import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // 模拟版本历史数据
    const updateHistory = [
      {
        version: '1.0.0',
        buildNumber: '1',
        releaseDate: '2025-07-06',
        releaseNotes: '初始版本发布\n- 完整的咖啡菜单\n- 家庭成员管理\n- 购物车功能\n- 爱心货币系统',
        downloadUrl: 'http://192.168.0.123:3001/downloads/flametree_coffee_v1.0.0.apk',
        fileSize: 25 * 1024 * 1024 // 25MB
      }
    ];
    
    return NextResponse.json(updateHistory);
  } catch (error) {
    console.error('Update history error:', error);
    return NextResponse.json({ error: 'Failed to get update history' }, { status: 500 });
  }
}