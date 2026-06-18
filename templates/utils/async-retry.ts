// Retry with exponential backoff + jitter. AbortSignal-aware.
// Use for ANY flaky external call: HTTP, queue, third-party API.
//
// Why jitter: without it, all clients retry at the same time = thundering herd.
// Why AbortSignal: caller must be able to cancel a retry loop (timeouts, unmount).
// Why max attempts > max time: most operations care about both — bound both.

interface RetryOptions {
  /** Maximum number of attempts (including the first try). Default 3. */
  maxAttempts?: number;
  /** Base delay in ms. Each retry doubles (capped by maxDelayMs). Default 200. */
  baseDelayMs?: number;
  /** Maximum delay between retries in ms. Default 5000. */
  maxDelayMs?: number;
  /** Hard timeout in ms across all attempts. Default 30000. */
  totalTimeoutMs?: number;
  /** Predicate: should this error trigger a retry? Default: all errors retry. */
  shouldRetry?: (error: unknown, attempt: number) => boolean;
  /** Optional abort signal — fail fast on caller-initiated cancellation. */
  signal?: AbortSignal;
  /** Optional callback fired before each retry (good for logging). */
  onRetry?: (error: unknown, attempt: number, delayMs: number) => void;
}

export class RetryError extends Error {
  constructor(
    message: string,
    public readonly cause: unknown,
    public readonly attempts: number,
  ) {
    super(message);
    this.name = "RetryError";
  }
}

export class AbortedError extends Error {
  constructor() {
    super("Operation aborted");
    this.name = "AbortedError";
  }
}

/**
 * Run `fn` with retries.
 *
 * @example
 *   const data = await retry(
 *     () => fetch(url).then((r) => r.json()),
 *     { maxAttempts: 5, baseDelayMs: 100, signal: controller.signal }
 *   );
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const {
    maxAttempts = 3,
    baseDelayMs = 200,
    maxDelayMs = 5_000,
    totalTimeoutMs = 30_000,
    shouldRetry = () => true,
    signal,
    onRetry,
  } = options;

  const start = Date.now();
  let lastError: unknown;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    if (signal?.aborted) throw new AbortedError();
    if (Date.now() - start > totalTimeoutMs) {
      throw new RetryError(
        `Total timeout (${totalTimeoutMs}ms) exceeded`,
        lastError,
        attempt - 1,
      );
    }

    try {
      return await fn();
    } catch (err) {
      lastError = err;

      const isLastAttempt = attempt === maxAttempts;
      if (isLastAttempt || !shouldRetry(err, attempt)) {
        throw new RetryError(
          `Failed after ${attempt} attempt(s): ${errorMessage(err)}`,
          err,
          attempt,
        );
      }

      // Exponential backoff with full jitter.
      // delay = random(0, min(maxDelay, baseDelay * 2^(attempt-1)))
      const expBackoff = Math.min(maxDelayMs, baseDelayMs * 2 ** (attempt - 1));
      const delay = Math.floor(Math.random() * expBackoff);

      onRetry?.(err, attempt, delay);

      await sleep(delay, signal);
    }
  }

  // Unreachable due to throw above, but TypeScript needs it.
  throw new RetryError(
    `Exhausted ${maxAttempts} attempts`,
    lastError,
    maxAttempts,
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) return reject(new AbortedError());

    const timer = setTimeout(() => {
      signal?.removeEventListener("abort", abortHandler);
      resolve();
    }, ms);

    const abortHandler = () => {
      clearTimeout(timer);
      reject(new AbortedError());
    };

    signal?.addEventListener("abort", abortHandler, { once: true });
  });
}

function errorMessage(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

// ─── Pre-built predicates ────────────────────────────────────────────────────

/** Retry only on network errors, not on HTTP 4xx (those are client bugs). */
export function isRetryableNetworkError(err: unknown): boolean {
  if (!(err instanceof Error)) return false;
  const msg = err.message.toLowerCase();
  return (
    msg.includes("etimedout") ||
    msg.includes("econnrefused") ||
    msg.includes("econnreset") ||
    msg.includes("network") ||
    msg.includes("fetch failed")
  );
}

/** Retry on HTTP 5xx and 429, NOT on 4xx (except 408 timeout). */
export function isRetryableHttpStatus(status: number): boolean {
  return status === 408 || status === 429 || status >= 500;
}
