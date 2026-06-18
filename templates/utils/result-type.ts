// Result<T, E> pattern — explicit error handling without exceptions.
// Borrowed from Rust. Useful when:
//   - Errors are expected as part of normal flow (validation, parsing, not-found)
//   - You want errors to be part of the type signature, not invisible
//   - Exceptions feel heavy or unclear about what can fail
//
// When NOT to use:
//   - Truly exceptional errors (out of memory, programmer error) — let those throw
//   - When the team uses exceptions consistently — don't mix paradigms

// ─── Core type ───────────────────────────────────────────────────────────────

export type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

// ─── Constructors ────────────────────────────────────────────────────────────

export const ok = <T>(value: T): Result<T, never> => ({ ok: true, value });

export const err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Wrap a sync function that might throw, return a Result.
 *
 * @example
 *   const result = tryCatch(() => JSON.parse(jsonString));
 *   if (!result.ok) console.error("Parse failed:", result.error);
 */
export function tryCatch<T>(fn: () => T): Result<T, unknown> {
  try {
    return ok(fn());
  } catch (error) {
    return err(error);
  }
}

/**
 * Wrap an async function that might throw, return a Result.
 *
 * @example
 *   const result = await tryCatchAsync(() => fetch(url).then(r => r.json()));
 *   if (!result.ok) return showError(result.error);
 *   useData(result.value);
 */
export async function tryCatchAsync<T>(
  fn: () => Promise<T>,
): Promise<Result<T, unknown>> {
  try {
    return ok(await fn());
  } catch (error) {
    return err(error);
  }
}

/**
 * Map over the success value. No-op on error.
 */
export function map<T, U, E>(
  result: Result<T, E>,
  fn: (value: T) => U,
): Result<U, E> {
  return result.ok ? ok(fn(result.value)) : result;
}

/**
 * Chain Results — like map but the mapper itself returns a Result.
 * The Rust folks call this `andThen` or `flatMap`.
 */
export function flatMap<T, U, E>(
  result: Result<T, E>,
  fn: (value: T) => Result<U, E>,
): Result<U, E> {
  return result.ok ? fn(result.value) : result;
}

/**
 * Map over the error. No-op on success. Useful for transforming error shapes.
 */
export function mapErr<T, E, F>(
  result: Result<T, E>,
  fn: (error: E) => F,
): Result<T, F> {
  return result.ok ? result : err(fn(result.error));
}

/**
 * Unwrap, providing a default for the error case.
 */
export function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
  return result.ok ? result.value : defaultValue;
}

/**
 * Throw on error. Use sparingly — defeats the purpose of using Result.
 * Useful when you're sure the operation succeeded (e.g., after a check).
 */
export function unwrap<T, E>(result: Result<T, E>): T {
  if (result.ok) return result.value;
  throw result.error instanceof Error
    ? result.error
    : new Error(String(result.error));
}

// ─── Usage example ───────────────────────────────────────────────────────────
//
// async function getUser(id: string): Promise<Result<User, "not-found" | "db-error">> {
//   const dbResult = await tryCatchAsync(() => db.users.find(id));
//   if (!dbResult.ok) return err("db-error" as const);
//   if (!dbResult.value) return err("not-found" as const);
//   return ok(dbResult.value);
// }
//
// // Caller — error path is explicit, can't be forgotten:
// const result = await getUser("123");
// if (!result.ok) {
//   switch (result.error) {
//     case "not-found": return res.status(404).json({ error: "User not found" });
//     case "db-error":  return res.status(500).json({ error: "DB error" });
//   }
// }
// return res.json(result.value);
