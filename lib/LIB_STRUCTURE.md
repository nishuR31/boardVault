# BoardVault Flutter App - Lib Structure

## Folder Organization

### `/lib`

Root directory for the Flutter application.

#### `/lib/models/`

Contains data models for type safety and serialization.

- `board_model.dart` - Board data class with JSON serialization
- `index.dart` - Export file for easy importing

#### `/lib/services/`

Contains business logic and API communication.

- `board_service.dart` - API service for board operations (fetch, search, filter)
- `index.dart` - Export file for easy importing

#### `/lib/pages/`

Contains page/screen widgets.

- `home.dart` - Home screen
- `boards.dart` - Searchable boards list page with filters
- `board.dart` - Single board detail page with all information
- `about.dart` - About page
- `privacy.dart` - Privacy policy page
- `terms.dart` - Terms of service page
- `faqs.dart` - FAQ page
- `health.dart` - Health check page
- `error.dart` - Error/404 page
- `footer.dart` - Footer component

#### `/lib/components/`

Contains reusable UI components.

- `common_widgets.dart` - Shared widgets (LoadingIndicator, ErrorDisplay, EmptyState)

#### `/lib/routes/`

Contains routing configuration.

- `index.dart` - Go Router configuration with all routes

#### `/lib/app/`

Contains app-level configuration.

- `index.dart` - App widget and theme configuration

#### `/lib/shared/`

Contains shared utilities and helpers.

- `scrollBehaviour.dart` - Custom scroll behavior

#### `/lib/apis/`

Reserved for API client configuration (currently empty).

---

## Architecture Pattern

**Service → Model → Page**

1. **Models** (`board_model.dart`): Define data structures with JSON serialization
2. **Services** (`board_service.dart`): Handle API calls and business logic
3. **Pages** (`boards.dart`, `board.dart`): UI layer that uses services and models

### Usage Example:

```dart
// In a page/widget
final boardService = BoardService();
final boards = await boardService.fetchBoards();

// Models provide type safety
final board = Board.fromJson(jsonData);
final filtered = boardService.filterByType(boards, 'SBC');
```

---

## Features

### Boards Page (`/boards`)

- ✅ Search functionality
- ✅ Type filtering (SBC/MC)
- ✅ Category filtering
- ✅ Limited info display with one image
- ✅ Responsive card layout

### Board Detail Page (`/board/:id`)

- ✅ Full board information from backend
- ✅ All categories and specifications
- ✅ Best for and alternatives lists
- ✅ Multiple images (front, pin diagram)
- ✅ Metadata (created, updated dates)
- ✅ Back navigation

### Board Service

- ✅ Fetch all boards
- ✅ Fetch single board by ID
- ✅ Fetch board by name/slug
- ✅ Search with local filtering
- ✅ Type filtering
- ✅ Category filtering

---

## Environment Variables

The app uses `BACKEND_URL` environment variable for API endpoint configuration.

```bash
flutter run --dart-define=BACKEND_URL=http://your-api.com
```

Default: Empty string (falls back to relative paths)

---

## Dependencies Used

- `flutter` - UI framework
- `go_router` - Navigation and routing
- `http` - HTTP requests

---

## Optimization Notes

1. **Single Image in List** - Only `photoFrontId` displayed in boards list to reduce bandwidth
2. **All Info on Detail** - Full `photoFrontId` and `pinDiagramId` available on detail page
3. **Local Filtering** - Search/filter done client-side after fetching all boards once
4. **Type-Safe Models** - Board class ensures compile-time safety
5. **Reusable Components** - Common widgets reduce code duplication
6. **Service Pattern** - Centralized API logic for easy testing and maintenance

---

## File Organization Benefits

- **Clear Separation of Concerns** - Models, services, and pages are separate
- **Easy Maintenance** - Find code by layer type
- **Scalability** - Easy to add new models, services, and pages
- **Code Reuse** - Components and services shared across pages
- **Testing** - Services can be easily mocked and tested
