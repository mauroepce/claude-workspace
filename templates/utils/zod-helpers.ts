// Common Zod schemas you keep re-writing. Import what you need.
//
// Dependencies: zod
//   npm install zod

import { z } from "zod";

// ─── Primitives ──────────────────────────────────────────────────────────────

/** Trimmed non-empty string. */
export const NonEmptyString = z.string().trim().min(1);

/** UUID v4. */
export const UUID = z.string().uuid();

/** Email (already trimmed + lowercased). */
export const Email = z
  .string()
  .trim()
  .toLowerCase()
  .email("Invalid email");

/** URL with http/https only. */
export const HttpUrl = z
  .string()
  .url()
  .refine((v) => v.startsWith("http://") || v.startsWith("https://"), {
    message: "Must be http or https URL",
  });

/** ISO 8601 datetime string. */
export const IsoDateString = z.string().datetime({ offset: true });

/** ISO 8601 datetime → Date object (transforms on parse). */
export const IsoDate = IsoDateString.transform((s) => new Date(s));

/** Positive integer. */
export const PositiveInt = z.number().int().positive();

/** Non-negative integer (0 allowed). */
export const NonNegativeInt = z.number().int().nonnegative();

/** Money in cents (avoid floats for currency). */
export const MoneyInCents = z
  .number()
  .int()
  .nonnegative()
  .describe("Amount in cents (avoids float precision issues)");

// ─── Composed schemas ────────────────────────────────────────────────────────

/** Cursor-based pagination query params (better than offset for large tables). */
export const CursorPagination = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  cursor: z.string().optional(),
});

/** Offset-based pagination (simpler but slower at scale). */
export const OffsetPagination = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

/** Standard sort param: ?sort=field:asc or ?sort=field:desc */
export const SortParam = z
  .string()
  .regex(/^[a-zA-Z_]+:(asc|desc)$/, "Format: field:asc or field:desc")
  .transform((s) => {
    const [field, dir] = s.split(":");
    return { field, dir: dir as "asc" | "desc" };
  });

/** Standard error response shape (matches the backend templates). */
export const ApiErrorShape = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.unknown().optional(),
  }),
});

// ─── Discriminated union helper ──────────────────────────────────────────────

/**
 * Build a discriminated union of possible API responses.
 *
 * @example
 *   const ApiResponse = apiResponse(z.object({ user: UserSchema }));
 *   // → { ok: true, data: { user } } | { ok: false, error: {...} }
 */
export function apiResponse<T extends z.ZodTypeAny>(dataSchema: T) {
  return z.discriminatedUnion("ok", [
    z.object({ ok: z.literal(true), data: dataSchema }),
    z.object({ ok: z.literal(false), error: ApiErrorShape.shape.error }),
  ]);
}

// ─── Inferred types (export so callers don't re-derive) ──────────────────────

export type Email = z.infer<typeof Email>;
export type UUID = z.infer<typeof UUID>;
export type CursorPagination = z.infer<typeof CursorPagination>;
export type OffsetPagination = z.infer<typeof OffsetPagination>;
export type SortParam = z.infer<typeof SortParam>;
export type ApiError = z.infer<typeof ApiErrorShape>;
