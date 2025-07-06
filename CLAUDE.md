# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a Flametree Coffee project with two main components:

- **flametree_coffee_app/**: Flutter mobile application (iOS/Android/Web/Desktop)
- **flametree_coffee_server/**: Next.js web server with TypeScript and Tailwind CSS

## Flutter App (flametree_coffee_app/)

### Development Commands
```bash
# Navigate to Flutter app directory
cd flametree_coffee_app

# Install dependencies
flutter pub get

# Run the app (debug mode with hot reload)
flutter run

# Run on specific device
flutter run -d chrome  # Web
flutter run -d ios     # iOS simulator
flutter run -d android # Android emulator

# Build for production
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web

# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

### Architecture
- Standard Flutter project structure with Material Design
- Uses `flutter_lints` for code quality
- Cupertino icons included for iOS-style UI elements
- Supports all platforms (iOS, Android, Web, Windows, macOS, Linux)

## Next.js Server (flametree_coffee_server/)

### Development Commands
```bash
# Navigate to server directory
cd flametree_coffee_server

# Install dependencies
npm install

# Start development server with Turbo
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linting
npm run lint
```

### Architecture
- Next.js 15.3.5 with App Router
- React 19 with TypeScript
- Tailwind CSS 4 for styling
- Geist font family integration
- PostCSS configuration

### Key Files
- `app/page.tsx`: Main landing page component
- `app/layout.tsx`: Root layout component
- `next.config.ts`: Next.js configuration
- `tsconfig.json`: TypeScript configuration
- `postcss.config.mjs`: PostCSS configuration

## Development Workflow

When working across both projects:
1. Changes to the Flutter app require `flutter pub get` after dependency updates
2. Changes to the server require `npm install` after package.json updates  
3. Both projects support hot reload during development
4. Use `flutter analyze` and `npm run lint` to check code quality before committing