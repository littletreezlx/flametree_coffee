import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

// 当前应用版本信息
const APP_VERSION = {
  version: '1.0.0',
  buildNumber: '1',
  releaseDate: '2025-07-06',
  releaseNotes: '初始版本发布\n- 完整的咖啡菜单\n- 家庭成员管理\n- 购物车功能\n- 爱心货币系统',
  downloadUrl: 'http://192.168.0.123:3001/downloads/flametree_coffee_v1.0.0.apk',
  minSupportedVersion: '1.0.0'
};

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const endpoint = searchParams.get('endpoint');
    
    if (endpoint === 'check') {
      return handleCheckUpdate(request);
    } else if (endpoint === 'history') {
      return handleUpdateHistory(request);
    }
    
    return NextResponse.json({ error: 'Invalid endpoint' }, { status: 400 });
  } catch (error) {
    console.error('Update API error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

async function handleCheckUpdate(request: NextRequest) {
  try {
    const currentVersion = request.headers.get('Current-Version') || '0.0.0';
    
    // 比较版本号
    const hasUpdate = isNewVersionAvailable(currentVersion, APP_VERSION.version);
    
    if (hasUpdate) {
      return NextResponse.json({
        hasUpdate: true,
        version: APP_VERSION.version,
        buildNumber: APP_VERSION.buildNumber,
        releaseDate: APP_VERSION.releaseDate,
        releaseNotes: APP_VERSION.releaseNotes,
        downloadUrl: APP_VERSION.downloadUrl,
        forceUpdate: isForceUpdateRequired(currentVersion),
        fileSize: await getFileSize(APP_VERSION.downloadUrl)
      });
    } else {
      return NextResponse.json({
        hasUpdate: false,
        currentVersion: APP_VERSION.version,
        message: '已是最新版本'
      });
    }
  } catch (error) {
    console.error('Check update error:', error);
    return NextResponse.json({ error: 'Failed to check update' }, { status: 500 });
  }
}

async function handleUpdateHistory(request: NextRequest) {
  try {
    // 模拟版本历史数据
    const updateHistory = [
      {
        version: '1.0.0',
        buildNumber: '1',
        releaseDate: '2025-07-06',
        releaseNotes: '初始版本发布\n- 完整的咖啡菜单\n- 家庭成员管理\n- 购物车功能\n- 爱心货币系统',
        downloadUrl: 'http://192.168.0.123:3001/downloads/flametree_coffee_v1.0.0.apk'
      }
    ];
    
    return NextResponse.json(updateHistory);
  } catch (error) {
    console.error('Update history error:', error);
    return NextResponse.json({ error: 'Failed to get update history' }, { status: 500 });
  }
}

// 比较版本号
function isNewVersionAvailable(currentVersion: string, newVersion: string): boolean {
  const current = parseVersion(currentVersion);
  const newer = parseVersion(newVersion);
  
  for (let i = 0; i < 3; i++) {
    if (newer[i] > current[i]) {
      return true;
    } else if (newer[i] < current[i]) {
      return false;
    }
  }
  return false;
}

// 解析版本号
function parseVersion(version: string): number[] {
  const parts = version.split('.');
  return [
    parseInt(parts[0] || '0', 10),
    parseInt(parts[1] || '0', 10),
    parseInt(parts[2] || '0', 10)
  ];
}

// 检查是否需要强制更新
function isForceUpdateRequired(currentVersion: string): boolean {
  return isNewVersionAvailable(currentVersion, APP_VERSION.minSupportedVersion);
}

// 获取文件大小
async function getFileSize(downloadUrl: string): Promise<number | null> {
  try {
    // 如果是本地文件，直接获取文件大小
    if (downloadUrl.includes('localhost') || downloadUrl.includes('192.168.')) {
      const fileName = path.basename(downloadUrl);
      const filePath = path.join(process.cwd(), 'public', 'downloads', fileName);
      
      if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
        return stats.size;
      }
    }
    
    return null;
  } catch (error) {
    console.error('Error getting file size:', error);
    return null;
  }
}