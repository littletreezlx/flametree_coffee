# Flametree Coffee - Project Structure Mapping Table

## Project Overview
**Family Internal Ordering MVP System** - 家庭内部点餐MVP应用
- **Flutter Client**: iOS/Android mobile app with Provider state management
- **Next.js Server**: TypeScript backend with React admin interface
- **Core Features**: Family member selection, coffee menu, love heart currency, local caching

---

## File Structure & Component Mapping

### 🚀 **Server Side** (`flametree_coffee_server/`)

#### **Core Configuration**
| File Path | Purpose | Key Components |
|-----------|---------|----------------|
| `next.config.ts:1` | Next.js configuration | App router setup |
| `tsconfig.json:1` | TypeScript configuration | Strict mode, paths |
| `postcss.config.mjs:1` | PostCSS & Tailwind setup | CSS processing |
| `package.json:1` | Dependencies & scripts | Next.js 15.3.5, React 19 |

#### **API Endpoints** 
| Endpoint | File Path | Methods | Purpose |
|----------|-----------|---------|---------|
| `/api/menu` | `app/api/menu/route.ts:1-45` | GET, POST | Menu CRUD operations |
| `/api/menu/categories` | `app/api/menu/route.ts:47-56` | GET | Category list |
| `/api/orders` | `app/api/orders/route.ts:1-89` | GET, POST | Order management |
| `/api/members` | `app/api/orders/route.ts:91-100` | GET | Family members |

#### **Data Storage**
| File Path | Content Type | Structure |
|-----------|--------------|-----------|
| `data/menu.json:2-207` | Coffee Menu | 16 items, 3 categories (美式系列, 拿铁系列, 茶系列) |
| `data/orders.json:2-76` | Orders & Members | Orders history + 4 family members |

#### **Admin Interface**
| Component | File Path | Features |
|-----------|-----------|----------|
| Admin Dashboard | `app/admin/page.tsx:1-180` | Family member management, order overview |
| Layout | `app/layout.tsx:1-25` | Root layout with Geist font |
| Landing Page | `app/page.tsx:1-15` | Welcome page |

---

### 📱 **Client Side** (`flametree_coffee_app/`)

#### **App Structure**
| Component | File Path | Responsibility |
|-----------|-----------|----------------|
| Main Entry | `lib/main.dart:1-25` | Provider setup, orange theme |
| Main Screen | `lib/screens/main_screen.dart:1-150` | Bottom navigation controller |
| Menu Tab | `lib/screens/menu_tab.dart:1-273` | Menu display with categories |
| Home Tab | `lib/screens/home_tab.dart:1-200` | Family member selection |
| Cart Tab | `lib/screens/cart_tab.dart:1-250` | Shopping cart management |

#### **State Management**
| Provider | File Path | State Data |
|----------|-----------|------------|
| CartProvider | `lib/providers/cart_provider.dart:1-150` | Selected member, cart items, totals |

#### **Services Layer**
| Service | File Path | Purpose |
|---------|-----------|---------|
| API Service | `lib/services/api_service.dart:1-150` | HTTP client, server communication |
| Cache Service | `lib/services/menu_cache_service.dart:1-116` | Local storage, 1-hour expiration |

#### **Data Models**
| Model | File Path | Properties |
|-------|-----------|------------|
| CoffeeItem | `lib/models/coffee_item.dart:1-50` | id, name, category, prices, availability |
| FamilyMember | `lib/models/family_member.dart:1-30` | id, name, avatar |
| CartItem | `lib/models/cart_item.dart:1-40` | coffee, temperature, quantity |
| Order | `lib/models/order.dart:1-60` | member info, items, total, status |

#### **UI Components**
| Widget | File Path | Function |
|--------|-----------|----------|
| CoffeeCard | `lib/widgets/coffee_card.dart:1-200` | Menu item display |
| FullscreenImageViewer | `lib/widgets/fullscreen_image_viewer.dart:1-80` | Hero image transitions |

---

## 🔄 **Data Flow Architecture**

### **Menu Data Flow**
```
Server: menu.json → API endpoint → Client: HTTP request → Cache Service → UI Display
Cache: 1-hour expiration, offline fallback, force refresh capability
```

### **Order Flow**
```
Client: Cart → API Service → Server: orders.json → Admin Interface
Family Member Selection → Local Storage → Order Association
```

### **Navigation Structure**
```
MainScreen (Bottom Tabs)
├── HomeTab: Family member selection
├── MenuTab: Coffee categories + items
└── CartTab: Order summary + checkout
```

---

## 🛠 **Development Commands**

### **Server Commands**
```bash
cd flametree_coffee_server
npm install          # Install dependencies
npm run dev          # Development server (Turbo)
npm run build        # Production build
npm run lint         # Code linting
```

### **Flutter Commands**
```bash
cd flametree_coffee_app
flutter pub get      # Install dependencies
flutter run          # Debug mode with hot reload
flutter run -d chrome # Web platform
flutter test         # Run tests
flutter analyze      # Code analysis
```

---

## 🎯 **Key Technical Concepts**

### **State Management Pattern**
- **Provider Pattern**: Centralized state for cart and member selection
- **Local Storage**: SharedPreferences for persistence
- **Caching Strategy**: 1-hour validity with offline fallback

### **API Integration**
- **Base URL**: `http://192.168.0.123:3001/api`
- **Error Handling**: Network errors fall back to cached data
- **Force Refresh**: Manual cache invalidation capability

### **UI Design System**
- **Theme Color**: Orange (`#FF8C42`)
- **Currency**: Love hearts (❤️) instead of money
- **Navigation**: Bottom tabs with state switching
- **Image Handling**: Hero animations for smooth transitions

---

## 📋 **Current Implementation Status**

### ✅ **Completed Features**
- [x] Complete menu system with 16 coffee items
- [x] Family member selection with local storage
- [x] Shopping cart with love heart currency
- [x] Local caching with 1-hour expiration
- [x] Bottom tab navigation structure
- [x] Admin interface for order management
- [x] Hero image viewer for menu photo

### 🔧 **Architecture Decisions**
- **Navigation**: Switched from separate screens to tab-based content switching
- **Caching**: Comprehensive offline support with automatic fallback
- **Currency**: Love heart system instead of traditional money concept
- **Storage**: JSON files for MVP phase instead of database

---

## 🚨 **Common Issues & Solutions**

### **Navigation Issues**
- **Problem**: Bottom tabs not visible in menu screen
- **Solution**: Restructured to use state management within MainScreen instead of Navigator.push

### **Caching Behavior**
- **Cache Hit**: Console shows "Using cached menu data"
- **Network Fetch**: Console shows "Fetching menu from server"
- **Fallback**: "Network error, using cached menu"

### **Development Environment**
- **Server Port**: 3001
- **Local IP**: 192.168.0.123
- **Hot Reload**: Both server (Turbo) and Flutter support

---

*Last Updated: 2025-07-06*
*This mapping table is dynamically maintained to optimize project interactions*