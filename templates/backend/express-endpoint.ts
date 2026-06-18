// REST endpoint pattern: Zod input validation, typed handler, error class hierarchy.
// Copy this file, rename, adapt the schema and handler logic.
//
// Dependencies needed: express, zod
//   npm install express zod
//   npm install -D @types/express tsx

import { Request, Response, NextFunction, Router } from "express";
import { z } from "zod";

// ─────────────────────────────────────────────────────────────────────────────
// Error class hierarchy — catch-and-narrow pattern.
// Extend Error so stack traces work, give each a distinct name for type guards.
// ─────────────────────────────────────────────────────────────────────────────

export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
    public code: string,
    public details?: unknown,
  ) {
    super(message);
    this.name = "HttpError";
  }
}

export class ValidationError extends HttpError {
  constructor(details: unknown) {
    super(400, "Validation failed", "VALIDATION_ERROR", details);
    this.name = "ValidationError";
  }
}

export class NotFoundError extends HttpError {
  constructor(resource: string) {
    super(404, `${resource} not found`, "NOT_FOUND");
    this.name = "NotFoundError";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request schema — Zod for runtime validation.
// Types alone don't protect against bad input at the boundary.
// ─────────────────────────────────────────────────────────────────────────────

const CreateUserBody = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(18).optional(),
});

type CreateUserBody = z.infer<typeof CreateUserBody>;

// ─────────────────────────────────────────────────────────────────────────────
// Handler — async, typed Request, throws structured errors.
// Business logic stays out of the route — extract to a service when it grows.
// ─────────────────────────────────────────────────────────────────────────────

async function createUserHandler(
  req: Request<unknown, unknown, CreateUserBody>,
  res: Response,
): Promise<void> {
  const parsed = CreateUserBody.safeParse(req.body);
  if (!parsed.success) {
    throw new ValidationError(parsed.error.flatten());
  }

  // TODO(service): replace with real DB call
  const user = { id: crypto.randomUUID(), ...parsed.data };

  res.status(201).json({ user });
}

// ─────────────────────────────────────────────────────────────────────────────
// Error middleware — must be the LAST middleware registered.
// Catches thrown errors, narrows by class, returns JSON.
// ─────────────────────────────────────────────────────────────────────────────

export function errorMiddleware(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof HttpError) {
    res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
    return;
  }
  // Unknown error — don't leak internals
  console.error("[unhandled]", err);
  res.status(500).json({
    error: { code: "INTERNAL_ERROR", message: "Internal server error" },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Router wiring — async handler wrapped so thrown errors hit error middleware.
// ─────────────────────────────────────────────────────────────────────────────

const asyncHandler =
  <T>(fn: (req: Request<T>, res: Response) => Promise<void>) =>
  (req: Request<T>, res: Response, next: NextFunction) =>
    Promise.resolve(fn(req, res)).catch(next);

export const userRouter = Router();
userRouter.post("/users", asyncHandler(createUserHandler));
