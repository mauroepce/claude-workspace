// Next.js App Router API route handler (route.ts).
// Place in: app/api/[resource]/route.ts
//
// Dependencies: next, zod
//   npm install zod  (next is built-in)

import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";

// ─── Schemas ─────────────────────────────────────────────────────────────────

const CreateUserBody = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

const QueryParams = z.object({
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
  cursor: z.string().optional(),
});

// ─── Error helper ────────────────────────────────────────────────────────────
// Centralize JSON error responses so the shape is consistent.

function errorResponse(
  status: number,
  code: string,
  message: string,
  details?: unknown,
): NextResponse {
  return NextResponse.json(
    { error: { code, message, ...(details ? { details } : {}) } },
    { status },
  );
}

// ─── GET — list with cursor pagination ───────────────────────────────────────

export async function GET(request: NextRequest): Promise<NextResponse> {
  const params = QueryParams.safeParse(
    Object.fromEntries(request.nextUrl.searchParams),
  );
  if (!params.success) {
    return errorResponse(
      400,
      "VALIDATION_ERROR",
      "Invalid query params",
      params.error.flatten(),
    );
  }

  try {
    // TODO(repository): replace with real DB call
    const users = [{ id: "1", email: "a@b.com", name: "Demo" }];
    const nextCursor = users.length === params.data.limit ? "next-cursor" : null;

    return NextResponse.json({ users, nextCursor });
  } catch (err) {
    console.error("[GET /users]", err);
    return errorResponse(500, "INTERNAL_ERROR", "Internal server error");
  }
}

// ─── POST — create ───────────────────────────────────────────────────────────

export async function POST(request: NextRequest): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return errorResponse(400, "INVALID_JSON", "Invalid JSON body");
  }

  const parsed = CreateUserBody.safeParse(body);
  if (!parsed.success) {
    return errorResponse(
      400,
      "VALIDATION_ERROR",
      "Validation failed",
      parsed.error.flatten(),
    );
  }

  try {
    // TODO(repository): replace with real DB call
    const user = { id: crypto.randomUUID(), ...parsed.data };

    return NextResponse.json({ user }, { status: 201 });
  } catch (err) {
    console.error("[POST /users]", err);
    return errorResponse(500, "INTERNAL_ERROR", "Internal server error");
  }
}
