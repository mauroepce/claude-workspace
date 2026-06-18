// Vitest setup + first integration test pattern.
//
// Dependencies: vitest
//   npm install -D vitest
//
// Add to package.json:
//   "scripts": { "test": "vitest", "test:run": "vitest run", "test:coverage": "vitest --coverage" }
//
// Then create vitest.config.ts in project root (config snippet at bottom of this file).

import { describe, it, expect, beforeAll, afterAll, beforeEach } from "vitest";

// ─── Example: testing a pure function ────────────────────────────────────────

import { retry, isRetryableHttpStatus } from "../utils/async-retry";

describe("retry()", () => {
  it("returns the result on first success", async () => {
    let calls = 0;
    const result = await retry(async () => {
      calls++;
      return "ok";
    });
    expect(result).toBe("ok");
    expect(calls).toBe(1);
  });

  it("retries until success", async () => {
    let calls = 0;
    const result = await retry(
      async () => {
        calls++;
        if (calls < 3) throw new Error("temp");
        return "ok";
      },
      { maxAttempts: 5, baseDelayMs: 1 },
    );
    expect(result).toBe("ok");
    expect(calls).toBe(3);
  });

  it("throws RetryError after maxAttempts", async () => {
    await expect(
      retry(async () => {
        throw new Error("always fails");
      }, { maxAttempts: 2, baseDelayMs: 1 }),
    ).rejects.toThrow(/Failed after 2 attempt/);
  });

  it("respects shouldRetry predicate", async () => {
    let calls = 0;
    await expect(
      retry(
        async () => {
          calls++;
          throw new Error("non-retryable");
        },
        {
          maxAttempts: 5,
          baseDelayMs: 1,
          shouldRetry: () => false, // don't retry
        },
      ),
    ).rejects.toThrow();
    expect(calls).toBe(1); // didn't retry
  });

  it("aborts on signal", async () => {
    const controller = new AbortController();
    controller.abort();

    await expect(
      retry(async () => "never returned", { signal: controller.signal }),
    ).rejects.toThrow(/abort/i);
  });
});

describe("isRetryableHttpStatus()", () => {
  it.each([
    [408, true, "request timeout"],
    [429, true, "rate limited"],
    [500, true, "server error"],
    [502, true, "bad gateway"],
    [400, false, "bad request — client bug"],
    [404, false, "not found"],
    [200, false, "success"],
  ])("returns %s for status %i (%s)", (status, expected) => {
    expect(isRetryableHttpStatus(status as number)).toBe(expected);
  });
});

// ─── Example: integration test with setup/teardown ───────────────────────────
//
// describe("UsersService (integration)", () => {
//   let service: UsersService;
//
//   beforeAll(async () => {
//     // Connect to test DB, run migrations
//     service = new UsersService(testDb);
//   });
//
//   afterAll(async () => {
//     // Close DB connection
//     await testDb.close();
//   });
//
//   beforeEach(async () => {
//     // Clean state between tests
//     await testDb.exec("TRUNCATE users RESTART IDENTITY CASCADE");
//   });
//
//   it("creates a user with a valid email", async () => {
//     const user = await service.create({ email: "a@b.com", name: "Alice" });
//     expect(user.id).toBeDefined();
//     expect(user.email).toBe("a@b.com");
//   });
// });

// ─── vitest.config.ts (place in project root) ────────────────────────────────
//
// import { defineConfig } from "vitest/config";
//
// export default defineConfig({
//   test: {
//     globals: false,        // explicit imports preferred (this file uses them)
//     environment: "node",   // or "jsdom" for browser-like tests
//     include: ["src/**/*.test.ts", "src/**/*.spec.ts"],
//     coverage: {
//       provider: "v8",
//       reporter: ["text", "html"],
//     },
//   },
// });
