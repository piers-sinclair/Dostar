# code-quality

Audit code for quality issues across a defined set of principles and report findings before making any changes.

## Usage

```
/code-quality [path]
```

- No argument → audits files changed on the current branch (`git diff main...HEAD --name-only`)
- Path given → audits all source files under that path recursively

## Workflow

1. **Determine scope**: resolve the file list (diff or path)
2. **Read every file** in scope
3. **Audit** each file against every category below
4. **Report** all findings grouped by category, with severity, file reference, what was found, and a suggested fix
5. **Ask the user** which findings (if any) they want applied — do not touch any file until they confirm

## Severity levels

| Level | Meaning |
|-------|---------|
| `Error` | Clear, unambiguous violation — fix unconditionally (e.g. `.Result` blocking call, `catch (Exception)`, magic string repeated 2+ times) |
| `Warning` | Probable violation that needs context to confirm (e.g. SRP smell, large method) |
| `Info` | Improvement opportunity — newer syntax available, naming suggestion, minor clarity improvement |

## Reporting format

For each finding, output:

```
[<Severity>] <Category> — <file>:<line or range>
  Found: <what was found>
  Fix:   <suggested change>
```

Group findings by category. At the end, print a summary table:

| Category | Error | Warning | Info |
|----------|-------|---------|------|
| ...      | N     | N       | N    |

Then ask: **"Which findings would you like me to fix? List numbers, 'all', or 'none'."**

---

## Audit categories

### Shared (all file types)

#### 1. SOLID

Check each principle:

- **SRP** (Single Responsibility): flag classes or files doing multiple unrelated things — e.g. a service that also owns HTTP-response shaping, a module class mixing business logic with DI wiring.
- **OCP** (Open/Closed): flag `if`/`switch` chains that would need editing to add a new case where a strategy or polymorphism pattern would avoid the edit.
- **LSP** (Liskov Substitution): flag subclasses that override base behaviour in ways that break the base contract (throwing where the base didn't, returning null where the base promised a value).
- **ISP** (Interface Segregation): flag interfaces with methods that some implementors leave unimplemented or stub out.
- **DIP** (Dependency Inversion): flag high-level classes that directly instantiate (`new ConcreteType()`) low-level dependencies that should be injected.

#### 2. DRY (Do Not Repeat Yourself)

Flag **proven** duplicate logic only — the same algorithm, query expression, or decision tree appearing in two or more places verbatim or near-verbatim. Do **not** flag structural similarity alone (two classes that both have a `GetById` method are not a DRY violation unless the bodies are the same).

#### 3. Composition over Inheritance

Flag inheritance chains deeper than one level (excluding framework base classes such as `DbContext`, `AbstractValidator`, `IEndpointFilter`). Suggest an interface + composition alternative when the inheritance is purely for code reuse rather than a true is-a relationship.

#### 4. Separation of Concerns

Flag:
- Business or domain logic inside endpoint handlers (should be in a service)
- Data-access logic (EF Core queries) outside the DbContext or a dedicated repository
- Cross-cutting concerns (logging, auth checks, validation) inlined in business code rather than handled by middleware or endpoint filters

#### 5. Loose Coupling

Flag:
- `new ConcreteType()` for a dependency that should be injected via constructor
- A module referencing another module's `.Implementation` project instead of `.Contracts`
- Hard-coded external URLs or connection strings embedded in business logic

#### 6. KISS (Keep It Simple)

Flag:
- Deeply nested `if`/`for` blocks that could be early-returned or flattened
- Abstractions (base classes, generics, design patterns) added speculatively with only one concrete use today
- Overly clever one-liners that reduce readability (complex LINQ chains, ternary-in-ternary, etc.)

#### 7. Magic strings and numbers

Flag any string or numeric literal that:
- Has domain or configuration meaning (status codes, route segments, header names, connection string keys, permission names, etc.)
- Appears more than once, OR
- Appears once but is non-obvious without context

Expected fix: extract to a named `private const` or `static readonly` field in the same class/file.

#### 8. Naming

Flag:
- Abbreviations (`mgr`, `svc`, `tmp`, `d`, `e` outside of catch clauses)
- Misleading names (a method called `GetUser` that also saves to the DB)
- Generic names when a specific one exists (`data`, `result`, `item`, `obj`)
- Inconsistent casing (mixing camelCase and PascalCase for the same kind of symbol)
- Boolean variables or properties not phrased as a question (`isActive`, `hasPermission`, not `active`, `permission`)

#### 9. Comments

Flag any comment that explains **what** the code does — the code itself should do that through naming and structure.

**Allow only:**
- Workaround comments: "X is intentional because of [specific external constraint or bug]"
- Non-obvious invariant explanations that cannot be expressed in types or names
- External constraint references (spec section, RFC, third-party quirk)

Do not flag TODO/FIXME/HACK if they reference a known issue or ticket.

---

### Backend (.NET-specific)

Apply these checks only to `.cs` files.

#### 10. Strict nullability

Flag:
- `!` (null-forgiving operator) used without a comment explaining why null is impossible here
- Reference-type or `string` properties that are neither `required`, initialised (`= string.Empty`, `= []`, etc.), nor explicitly nullable (`?`) — these silently produce nullable warnings or require suppression
- Nullable return type (`T?`) on a method where null is semantically impossible (prefer an exception or `Option` pattern)
- Missing `?` on a return type or parameter that can legitimately be null

Do **not** flag `required` on properties that have a default factory or are optional by design.

#### 11. Latest .NET syntax

Flag where a modern equivalent exists and improves clarity:

| Old pattern | Preferred |
|-------------|-----------|
| `public Foo(IBar bar) { _bar = bar; }` field injection | Primary constructor: `public Foo(IBar bar)` |
| `x == null` / `x != null` | `x is null` / `x is not null` |
| `new List<T>()` / `new T[0]` | Collection expression: `[]` |
| `new List<T> { a, b }` | `[a, b]` |
| Explicit type in `var`-eligible local | `var` (when type is obvious from RHS) or target-typed `new()` |
| `string.IsNullOrEmpty(x)` | `x is null or ""` or keep if negated form reads better |
| Non-record immutable DTO class | `record` or `record struct` |
| `using` directive inside a file (in Implementation projects) | Move to `GlobalUsings.cs` |
| `Guid.NewGuid()` for sequential IDs | `Guid.CreateVersion7()` where ordering matters |

Do **not** flag framework-mandated patterns (e.g. EF Core entity classes cannot always be records).

#### 12. Exception handling

Flag:
- `catch (Exception)` or `catch (Exception e)` — too broad; catch the most specific exception type
- Swallowed exceptions: `catch { }`, `catch (Exception) { }`, or `catch` that only logs without rethrowing or returning an error result
- Exceptions used for control flow (throwing to signal an expected "not found" state)
- `try/catch` blocks that simply let the exception propagate unchanged — this is redundant; delete the try/catch and let the global `UseExceptionHandler` middleware in `Program.cs` handle it

Local `try/catch` is appropriate only for **genuinely local recovery**: retrying a transient operation, translating a third-party exception into a domain type, or releasing a resource that `using` cannot manage.

#### 13. Async/await correctness

Flag:
- `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()` on a `Task` — these block threads and risk deadlocks
- `async void` methods (except event handlers — explain if this is one)
- A method named without the `Async` suffix that returns `Task` or `Task<T>`
- A method that has a `CancellationToken` available (e.g. via `HttpContext.RequestAborted`, a parameter, or `stoppingToken`) but does not pass it to async calls that accept one
- Redundant `await`: `return await SomeAsync()` at the end of a non-try method — can be `return SomeAsync()`

#### 14. EF Core / PostgreSQL best practices

Apply only to files that use `DbContext` or EF Core query syntax.

Flag:
- **Missing `AsNoTracking()`** on read-only queries (queries whose results are never mutated and saved back) — unnecessary change tracking wastes memory
- **N+1 query patterns** — iterating a collection and calling the DB per item; fix with `Include()`/`ThenInclude()` or a single projected query
- **Loading full entities when a projection suffices** — `db.Todos.ToListAsync()` then mapping in code instead of `db.Todos.Select(x => new TodoDto(...)).ToListAsync()`
- **Synchronous EF Core methods** — `ToList()`, `FirstOrDefault()`, `Count()`, etc. must be `ToListAsync()`, `FirstOrDefaultAsync()`, `CountAsync()` etc.
- **Bulk operations that load entities unnecessarily** — loading entities only to delete or update them; prefer `ExecuteDeleteAsync()` / `ExecuteUpdateAsync()` (EF Core 7+) for set-based operations
- **`DateTime` instead of `DateTimeOffset`** for timestamp columns — `DateTimeOffset` maps to `timestamptz` in PostgreSQL and preserves timezone context; `DateTime` maps to `timestamp without time zone`
- **Case-insensitive string comparisons using `ToLower()`/`ToUpper()`** — `x.Title.ToLower() == input.ToLower()` generates `LOWER()` SQL that prevents index use; prefer `EF.Functions.ILike(x.Title, input)` for PostgreSQL case-insensitive search
- **Raw SQL with string interpolation** — `FromSqlRaw($"... {value}")` is an injection risk; use `FromSqlInterpolated($"... {value}")` or parameterised `FromSqlRaw("... {0}", value)`
- **`Guid.NewGuid()` as a primary key** where sequential ordering matters — `Guid.CreateVersion7()` generates time-ordered GUIDs that perform better as clustered index keys in PostgreSQL

#### 15. Test quality

Apply only to test files (`*Tests.cs`, `*Tests/*.cs`).

Flag:
- Method name does not follow `MethodName_Condition_ExpectedOutcome` pattern
- Shared mutable state between tests (static fields, shared DbContext instances)
- Assertions using `Assert.*` (xUnit) or FluentAssertions — must use **Shouldly**
- A single `[Fact]` covering multiple unrelated scenarios (each scenario needs its own `[Fact]`)
- `InMemoryDatabase` not using `Guid.NewGuid().ToString()` as the DB name — tests must be fully isolated

---

### Frontend (TypeScript/React-specific)

Apply these checks only to `.ts` and `.tsx` files.

#### 16. TypeScript strictness

Flag:
- `any` type — suggest `unknown` and a type guard, or a proper named type
- `!` non-null assertion, except on well-known always-present DOM nodes (e.g. `document.getElementById('root')!` in `main.tsx` is acceptable; add a comment if it is not obvious)
- `as T` type assertion without an accompanying comment explaining why the cast is safe
- Exported functions or React components missing an explicit return type annotation

#### 17. Test quality (frontend)

Apply only to test files (`*.test.ts`, `*.test.tsx`, `*.spec.ts`, `*.spec.tsx`).

Flag:
- Tests not following Arrange / Act / Assert structure
- Shared mutable state between tests
- A single test covering multiple unrelated scenarios

---

## Conventions reminder

- Never apply a fix before the user confirms which findings to address.
- When applying fixes, change only the code required to resolve the finding — no opportunistic refactoring.
- If a finding requires a judgement call (e.g. whether a method truly violates SRP), present both sides briefly and let the user decide.
- After applying fixes, run `dotnet build` (for backend changes) or `pnpm build` from `frontend/` (for frontend changes) and confirm 0 errors/warnings before reporting done.
