# Learning Dashboard (iOS · SwiftUI)

## 1. Architecture
MVVM + Repository: `View → @Observable ViewModel → CourseRepository (protocol) → CourseAPI + CourseStore (protocols)`.
Views are dumb and render a single `State` enum (loading / loaded / empty / failed). ViewModels contain no networking or persistence. The repository is the single source of truth and the only layer that knows about caching, so data sources can be swapped (real API, SwiftData) without touching UI. All dependencies are wired in one composition root (`AppContainer`), so every layer is unit-testable with fakes. Progress is *derived* from lesson state (`Course.progress`), so it cannot drift out of sync.

## 2. Offline Support
Network-first, cache-fallback. After each successful fetch the course list is written atomically as JSON to Application Support (`FileCourseStore`). If the fetch fails and a cache exists, the cached list is shown with an "Offline" banner; with no cache the user sees an error + Retry. Lesson completions are saved to the same store, and on refresh `merge` keeps local progress when the server's lesson structure is unchanged. Trade-off: the mock API only gives a lesson count, so lessons are derived from `progress%` (40% of 16 → 6 done → shows 38%).

## 3. Security
Tokens go in the **Keychain** (`KeychainTokenStore`, `AfterFirstUnlockThisDeviceOnly`), never UserDefaults or files. In production: short-lived access token + refresh token with a refresh interceptor, certificate pinning, wipe Keychain and local cache on logout, optional biometric gate.

## 4. Scale (1M users, hundreds of courses)
1. Paginated, delta/ETag sync (`updatedSince`) instead of full list fetches; CDN in front of the API.
2. Move the cache to SwiftData/SQLite with indexes; load lessons lazily per course.
3. Outbox queue for lesson completions with retry and idempotency keys; server-side conflict resolution.
4. Observability: crash reporting, structured logs, API latency metrics, feature flags / remote config.
5. Modularise with SPM feature modules; add snapshot/integration tests in CI.

## 5. Second Platform (Android)
Kotlin + Jetpack Compose, same layering: `Composable → ViewModel (StateFlow<UiState>) → Repository → Retrofit/OkHttp + Room`. Room replaces `FileCourseStore` (Flow-based reads give offline for free); Hilt replaces `AppContainer`; tokens in Keystore-backed EncryptedSharedPreferences; Navigation-Compose for routing; connectivity via `ConnectivityManager`; tests with JUnit + Turbine + a fake repository.
