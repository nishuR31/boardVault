# BoardVault Flutter - Quick Reference

## 🚀 Getting Started

### Run the app:

```bash
cd boardvault
flutter run --dart-define=BACKEND_URL=http://localhost:3030
```

### Project Structure:

```
lib/
├── models/          → Data classes (Board)
├── services/        → API calls (BoardService)
├── pages/           → Screens (Boards, Board Detail)
├── components/      → Reusable widgets
├── routes/          → Navigation
├── app/             → App config & theme
└── shared/          → Utilities
```

---

## 📱 Pages Overview

### Boards List (`/boards`)

**Features:**

- Search by name/description
- Filter by type (SBC/MC)
- Filter by category
- Display: name, description, 1 image, categories

**Navigate to:**

```dart
context.push('/boards');
```

### Board Detail (`/board/:id`)

**Features:**

- Full board information
- All categories, best-for list, alternatives
- Multiple images (front + pin diagram)
- Board metadata (dates, ID)

**Navigate to:**

```dart
context.push('/board/$boardId');
```

---

## 🔧 Using BoardService

```dart
// Import
import '/services/board_service.dart';

// Create instance
final service = BoardService();

// Fetch operations
final allBoards = await service.fetchBoards();           // All boards
final board = await service.fetchBoardById('id');        // Single by ID
final byName = await service.fetchBoardByName('name');   // By name/slug
final searched = await service.searchBoards('query');    // Search

// Filtering (after fetching)
final sbcBoards = service.filterByType(boards, 'SBC');
final catBoards = service.filterByCategory(boards, 'IoT');
```

---

## 📦 Board Model

```dart
// Import
import '/models/board_model.dart';

// Create from JSON
final board = Board.fromJson(jsonData);

// Access properties
print(board.name);           // String
print(board.type);           // 'SBC' or 'MC'
print(board.category);       // List<String>
print(board.bestFor);        // List<String>
print(board.photoFrontId);   // String?
print(board.pinDiagramId);   // String?
```

---

## 🎨 Using Common Widgets

```dart
// Import
import '/components/common_widgets.dart';

// Loading indicator
LoadingIndicator(message: 'Loading boards...');
LoadingIndicator(message: 'Loading...', fullScreen: true);

// Error display
ErrorDisplay(
  title: 'Error',
  message: 'Failed to load boards',
  onRetry: () => refetch(),
);

// Empty state
EmptyState(
  title: 'No Results',
  subtitle: 'Try a different search',
  icon: Icons.search_off,
  onAction: () => reset(),
  actionLabel: 'Reset Search',
);
```

---

## 🛣️ Navigation

```dart
// Navigate to boards list
context.push('/boards');

// Navigate to board detail
context.push('/board/$boardId');

// Go back
context.pop();

// All routes:
/              → Home
/about         → About
/boards        → Boards list
/board/:id     → Board detail
/privacy       → Privacy
/terms         → Terms
/faqs          → FAQs
/health        → Health
```

---

## 🌐 Environment Variables

### Set Backend URL:

```bash
flutter run --dart-define=BACKEND_URL=http://your-api.com
```

### Default:

- Uses `BACKEND_URL` env var
- Falls back to empty string if not set
- API endpoints added dynamically: `/api/v1/boards`

---

## 🔍 Debugging Tips

### Check API calls:

```dart
// BoardService logs all requests
// Look for: "Fetching from: $boardsUrl"
// And: "Error fetching boards: $e"
```

### View network:

```bash
# Enable verbose logging
flutter run -v
```

### Common Issues:

**"Backend not reachable"**

- Check BACKEND_URL is set correctly
- Ensure backend server is running at http://localhost:3030

**"No boards found"**

- Verify backend has boards in database
- Run: `CRUD_PASSWORD=nishu3126 bun src/feedData.ts`

**Images not loading**

- Check photoFrontId/pinDiagramId in database
- Verify image URLs are accessible
- Images have fallback error UI

---

## 📊 Data Flow

```
User Action
    ↓
Page Widget
    ↓
BoardService (API call)
    ↓
Backend (/api/v1/boards)
    ↓
Board Model (JSON → Dart)
    ↓
UI Update (setState/rebuild)
```

---

## ✅ Testing Checklist

- [ ] Run app with: `flutter run --dart-define=BACKEND_URL=http://localhost:3030`
- [ ] Navigate to `/boards`
- [ ] Search for a board (e.g., "Arduino")
- [ ] Filter by type (SBC/MC)
- [ ] Click a board card
- [ ] Verify detail page loads with all info
- [ ] Check images load (or show error state)
- [ ] Test back button
- [ ] Test on dark mode

---

## 📝 Code Style

### File naming:

- Pages: `page_name.dart` (e.g., `boards.dart`)
- Models: `model_name.dart` (e.g., `board_model.dart`)
- Services: `service_name.dart` (e.g., `board_service.dart`)

### Class naming:

- Pages: `PascalCase` widget (e.g., `Boards`, `BoardDetail`)
- Models: `PascalCase` (e.g., `Board`)
- Services: `PascalCase` (e.g., `BoardService`)

### Imports:

- Use absolute imports: `import '/models/board_model.dart';`
- Use index files for cleaner imports: `import '/services/index.dart';`

---

## 🚀 Deployment

1. **Android:**

   ```bash
   flutter build apk --dart-define=BACKEND_URL=https://your-api.com
   ```

2. **iOS:**

   ```bash
   flutter build ios --dart-define=BACKEND_URL=https://your-api.com
   ```

3. **Web:**
   ```bash
   flutter build web --dart-define=BACKEND_URL=https://your-api.com
   ```

---

## 📚 Additional Resources

- See `lib/LIB_STRUCTURE.md` for detailed folder organization
- See `lib/IMPLEMENTATION_SUMMARY.md` for complete feature list
- See individual files for inline documentation

---

**Last Updated:** May 2026
**Status:** Production Ready ✅
