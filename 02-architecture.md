# Architecture Document: Go SQLite Todo Application

## 1. Technology Stack
- **Go + Gin**: Gin provides a fast, minimal router with first-class middleware and ergonomic JSON binding/validation. It fits a small, single-binary REST API without the overhead of a larger framework. The ecosystem has mature middleware (logging, recovery, CORS) and pairs cleanly with `go:embed` for static file serving.
- **modernc.org/sqlite**: Pure Go SQLite driver (no CGO) keeps builds simple and portable. Fits the single-user, file-backed persistence requirement while retaining full SQLite feature support (pragma tuning, WAL). Pure Go driver improves cross-platform build reproducibility.
- **React + Vite**: Vite offers fast dev server + optimized production bundling. React enables componentized UI and stateful search/filter interactions. Vite output is static assets that can be embedded in the Go binary.
- **Ant Design**: Provides polished data-entry and table/list components, form validation, modals, pagination, tag elements, and layout primitives. Reduces custom styling effort while delivering a professional desktop-first UI. Pairs well with React Context for controlled components and validation feedback.

## 2. System Architecture
- **Shape**: Single binary serving REST API and embedded SPA. SPA communicates over JSON via `/api/*` routes. Static assets served from `go:embed` at `/`.
- **Component diagram (textual)**:
  - `React SPA (Vite + AntD)` → fetch/JSON → `Gin HTTP API`
  - `Gin HTTP API` → service layer → repository layer → `SQLite (todos.db)`
  - `Gin HTTP API` → static file handler → embedded `dist/` assets
- **Data flow**: UI actions → API calls → handlers validate → services enforce business rules/transactions → repositories execute parameterized SQL → results mapped to DTOs → JSON responses → UI renders and updates Context state.
- **Cross-cutting**: middleware for request ID, structured logging, recovery, validation errors; transaction helper encapsulates multi-table operations (todos + tags + junction table); consistent error envelope across API.

## 3. Backend Architecture
- **Project layout (proposed)**:
  - `cmd/server/main.go` (bootstrap, config, embed FS wiring)
  - `internal/config` (port, db path, dev flags, CORS origins)
  - `internal/http/router.go` (Gin engine + middleware + route registration)
  - `internal/http/middleware` (request ID, logging, recovery, CORS, body limit)
  - `internal/todo/handler.go` (Gin handlers), `service.go`, `repository.go`
  - `internal/tag/...` (handlers/services/repos for tags)
  - `internal/importexport/...` (CSV/JSON parsers, streaming responses)
  - `internal/db/sqlite.go` (connection setup, pragmas, migration)
  - `web/dist` (embedded frontend build artifacts)
- **Router & middleware chain (order)**:
  1) `gin.Recovery()` with custom panic logging → 2) request ID injection (adds `X-Request-ID`) → 3) structured logger (method, path, status, latency, request ID) → 4) optional CORS (dev only) → 5) body size limiter (protect import) → 6) JSON error translator middleware (captures `error` set on context and emits standard envelope). Static file handler registered after API group to serve SPA.
- **Handlers / Services / Repositories**:
  - *Handlers*: decode/validate requests via Gin binding, map to service DTOs, handle pagination/query params, translate service errors to HTTP codes.
  - *Services*: enforce business rules (title length, tag limit 20, status/priority enums, completed_at stamping, due-date parsing), orchestrate repositories, open/commit/rollback transactions, build export payloads.
  - *Repositories*: parameterized SQL only; exposed via interfaces for testability. Separate repos for todos, tags, and todo_tags linking. Provide tx-aware versions (`WithTx(*sql.Tx)`) so services can compose multiple operations atomically.
- **Transaction management**:
  - `db.WithTx(ctx, func(tx *sql.Tx) error { ... })` helper wraps `BEGIN IMMEDIATE` to avoid write contention; rollback on error.
  - CRUD with tags uses single transaction: insert/update todo → ensure tags exist → sync junction rows → return hydrated todo.
  - Import runs batched inserts inside one transaction; per-row validation accumulates errors while keeping good rows.
- **Validation**: Gin binding with `binding:"required"` and custom validators for enums, tag count (≤20), length checks mirroring DB constraints; service-level normalization (trim, lowercase priority/status).
- **Pagination/filters**: query builder in repository assembles WHERE clauses for search scope, case sensitivity, tag ANY/ALL (via EXISTS vs GROUP BY HAVING COUNT), priority/status/due range, and ORDER/LIMIT/OFFSET.
- **Import/Export**: CSV uses streaming reader/writer to avoid large memory use; JSON uses stream encoder. Export respects active filters; import returns per-row errors.

## 4. Frontend Architecture
- **Component tree (high level)**:
  - `App` → `AppLayout` (AntD Layout) → `HeaderBar` (title, create, import/export buttons)
  - `FilterPanel` (search scope, case toggle, priority/status/tag filters, due range, sort) – collapsible
  - `TodoList` (List or Table) → `TodoItem` rows (priority badge, overdue styling, tags, actions)
  - `PaginationBar` (AntD Pagination, “clear filters” inline)
  - Modals: `TodoFormModal`, `ImportModal`, `ExportModal`, `DeleteConfirmModal`
  - `TagSelector` (multi-select + create-new inline)
- **State management (React Context + reducer)**:
  - `TodoProvider` holds `{todos, tags, filters, pagination, loading, error, selection}`.
  - Actions: `SET_FILTERS`, `SET_PAGE`, `SET_SORT`, `SET_TODOS`, `UPSERT_TODO`, `REMOVE_TODO`, `SET_TAGS`, `SET_LOADING`, `SET_ERROR`.
  - Derived selectors compute overdue flag, filtered counts, and badge styling.
- **Data fetching layer**:
  - `apiClient` small wrapper over `fetch` with base URL `/api`, `Content-Type: application/json`, error normalization to `{code,message,details}`.
  - Service modules: `todoApi` (list, get, create, update, delete, export), `tagApi`, `importApi`. Supports abort controllers for rapid filter changes.
- **Ant Design integration**:
  - Use `Form` with validation rules mirroring backend constraints (lengths, enum options, tag count max 20).
  - Components: `Layout`, `Form`, `Input`, `Select`, `DatePicker` (with time), `Tag`, `Badge`, `Table/List`, `Modal`, `Upload`, `Pagination`, `Alert`.
  - Theming centralized via AntD ConfigProvider; custom tokens for priority colors and overdue states.
- **Routing**: SPA single route (no React Router needed). Hashless navigation; deep links optional via querystring sync for filters (optional enhancement, not required initially).

## 5. API Design
- **Error envelope** (all 4xx/5xx):
  ```json
  {"error": {"code": "VALIDATION_ERROR", "message": "Title is required", "details": {"field": "title"}}}
  ```
- **Todos**
  - `GET /api/todos` — query params for search/filter/sort/pagination; returns `{data: [...], pagination: {...}}`.
  - `GET /api/todos/:id` — returns todo with tags array.
  - `POST /api/todos` — body: `{title, description?, priority?, due_date?, tag_ids?, new_tags?}`; status 201.
  - `PUT /api/todos/:id` — same shape as POST; status 200.
  - `DELETE /api/todos/:id` — status 200.
- **Tags**
  - `GET /api/tags` — returns `{id,name,usage_count}` list.
  - `POST /api/tags` — body `{name}`; status 201.
- **Import/Export**
  - `POST /api/import?format=json|csv` — multipart file upload; returns `{imported_count, skipped_count, errors:[{row,reason}]}`.
  - `GET /api/export?format=json|csv&...filters` — streams file download; CSV uses `Content-Type: text/csv` with `Content-Disposition` filename incorporating timestamp.
- **Gin handler pattern (example)**:
  ```go
  func (h *TodoHandler) Create(c *gin.Context) {
      var req CreateTodoRequest
      if err := c.ShouldBindJSON(&req); err != nil {
          h.respondError(c, http.StatusBadRequest, "VALIDATION_ERROR", err)
          return
      }
      todo, err := h.service.Create(c.Request.Context(), req.ToDTO())
      if err != nil {
          h.handleServiceError(c, err)
          return
      }
      c.JSON(http.StatusCreated, todo)
  }
  ```
- **Request/response example** (`POST /api/todos`):
  ```json
  {"title":"Buy groceries","priority":"high","due_date":"2025-01-02T15:00:00Z","new_tags":["errands","home"]}
  ```
  Response 201:
  ```json
  {"id":1,"title":"Buy groceries","priority":"high","status":"pending","due_date":"2025-01-02T15:00:00Z","tags":[{"id":1,"name":"errands"},{"id":2,"name":"home"}],"created_at":"2025-01-01T12:00:00Z","updated_at":"2025-01-01T12:00:00Z"}
  ```

## 6. Data Access Layer
- **Connection management**: single `*sql.DB` using `modernc.org/sqlite`. Set `db.SetMaxOpenConns(1)` and `db.SetMaxIdleConns(1)` to avoid writer contention; `PRAGMA foreign_keys=ON` and `PRAGMA busy_timeout=5000` on open. Optional WAL via `PRAGMA journal_mode=WAL` for better read concurrency.
- **Migrations**: on startup, run SQL schema creation idempotently; version table not required for v1 but stub kept for future migration tool.
- **Repositories**:
  - `TodoRepository` methods: `List(filter)`, `Get(id)`, `Create(dto)`, `Update(id,dto)`, `Delete(id)`, `SetCompleted(id, time?)`, `UpsertTags(todoID, tagIDs)`.
  - `TagRepository`: `ListAllWithUsage()`, `CreateIfNotExists(name)`, `BulkEnsure(names)`, `Link(todoID, tagIDs)`, `UnlinkMissing(todoID, keepIDs)`.
  - `ImportRepository`: batch insert todos + tags inside tx, returning counts and per-row errors.
- **Query patterns**:
  - Filters compose via clause builder; tag ANY uses `EXISTS` on `todo_tags`; tag ALL uses HAVING `COUNT(DISTINCT tag_id) = len(tags)`.
  - Sorting validated against whitelist; uses `ORDER BY <field> <ASC|DESC>` with limit/offset.
  - Prepared statements for writes; scans into structs with nullable types for `due_date` and `completed_at`.
- **Transaction handling**: `WithTx(ctx,... )` attaches `*sql.Tx` to repository instances; services pass tx-aware repos to ensure atomic todo/tag updates and import batches.

## 7. Data Model
- **Schema** (from requirements, enforced at boot):
  ```sql
  CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL CHECK(length(title) BETWEEN 1 AND 200),
    description TEXT CHECK(length(description) <= 2000),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('high','medium','low')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','completed')),
    due_date DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
  );
  CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at);
  CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
  CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority);
  CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);

  CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE CHECK(length(name) BETWEEN 1 AND 50),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
  );
  CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);

  CREATE TABLE IF NOT EXISTS todo_tags (
    todo_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (todo_id, tag_id),
    FOREIGN KEY (todo_id) REFERENCES todos(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
  );
  CREATE INDEX IF NOT EXISTS idx_todo_tags_todo_id ON todo_tags(todo_id);
  CREATE INDEX IF NOT EXISTS idx_todo_tags_tag_id ON todo_tags(tag_id);
  ```
- **Constraints mapping**: app-level validation mirrors DB constraints (title 1-200, desc ≤2000, priority/status enums, tag name 1-50, ≤20 tags). `completed_at` set when status transitions to completed; cleared when status reverts.

## 8. Build & Deployment
- **go:embed setup**: `//go:embed all:web/dist` exposes static assets as `embed.FS`; `http.FS` used with Gin `StaticFS("/", fs)` plus SPA fallback to `index.html` for unknown routes.
- **Build steps**:
  1) `npm install && npm run build` inside `web/` → outputs `web/dist`.
  2) `go build -o todo-app ./cmd/server` (no CGO thanks to modernc SQLite).
- **Runtime configuration**: via env flags (e.g., `PORT` default 8080, `DB_PATH` default `./data/todos.db`, `DEV_CORS_ORIGINS` optional). Data directory created if missing.
- **Distribution**: single binary + SQLite file. No external services. Binary can be copied across macOS/Linux/Windows without additional deps.

## 9. Error Handling
- **Middleware**: captures handler/service errors set on context; maps known codes (`VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `INTERNAL_ERROR`) to HTTP statuses. `gin.Recovery` logs stack traces with request ID.
- **Validation patterns**: Gin binding errors normalized; service-level validation returns typed errors with field detail. Frontend displays inline form errors and toasts for general failures.
- **Not-found & method**: `NoRoute` handler serves SPA for frontend paths; `NoMethod` returns JSON error envelope for API paths.

## 10. Development Workflow
- **Local dev (frontend-first)**: run `npm run dev` in `web/` for Vite HMR; run `go run ./cmd/server` with `DEV_CORS_ORIGINS=http://localhost:5173` enabling CORS middleware. API traffic goes to Gin, UI loaded from Vite dev server.
- **Local dev (embedded)**: run `npm run build` then `go run ./cmd/server` to serve embedded assets.
- **Testing**: Go unit tests for services/repos (use temp SQLite file); JS tests optional later. Use seed script to populate sample todos for manual QA.
- **CORS configuration**: Dev-only middleware allows configured origin and methods `GET,POST,PUT,DELETE,OPTIONS`, credentials false, exposes `X-Request-ID`.

## 11. Quality Score (target ≥90)
- Functional coverage: 30/30 (all requirements mapped to handlers, filters, import/export, validation)  
- Technical depth: 24/25 (explicit middleware chain, tx strategy, query patterns, embed)  
- Implementation readiness: 22/25 (package layout, code examples, data flow; pending concrete tests)  
- Scope clarity: 20/20 (matches requirements and non-goals)  
**Overall: 96/100**
