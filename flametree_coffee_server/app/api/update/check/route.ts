import { NextRequest, NextResponse } from 'next/server';

// 当前应用版本信息
const APP_VERSION = {
  version: '1.1.0',
  buildNumber: '2',
  releaseDate: '2025-07-12',
  releaseNotes: '版本更新功能发布\n- 新增应用内版本检查功能\n- 支持自动下载和安装更新\n- 优化用户界面和体验\n- 支持强制更新机制\n- 添加下载进度显示',
  downloadUrl: 'http://192.168.0.123:3001/downloads/flametree_coffee_v1.1.0.apk',
  appStoreUrl: 'https://apps.apple.com/app/flametree-coffee',
  minSupportedVersion: '1.0.0',
  fileSize: 25 * 1024 * 1024, // 25MB
  forceUpdate: false
};

export async function GET(request: NextRequest) {
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
        appStoreUrl: APP_VERSION.appStoreUrl,
        forceUpdate: APP_VERSION.forceUpdate || isForceUpdateRequired(currentVersion),
        fileSize: APP_VERSION.fileSize
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