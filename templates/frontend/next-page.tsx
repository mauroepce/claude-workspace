// Next.js App Router page (Server Component) with data fetching, error handling, and loading states.
// Place in: app/[route]/page.tsx
// Also create: app/[route]/loading.tsx and app/[route]/error.tsx for the boundary states (commented below).
//
// Dependencies: next (built-in)

import { Suspense } from "react";

// ─── Page metadata (Next.js convention) ──────────────────────────────────────

export const metadata = {
  title: "Users — App",
  description: "List of users",
};

// ─── Data fetching — Server Component does it directly, no hooks needed ──────

interface User {
  id: string;
  email: string;
  name: string;
}

async function fetchUsers(): Promise<User[]> {
  // In Server Components, fetch is automatically deduped + cached.
  // For dynamic data, pass { cache: 'no-store' } or use revalidate.
  const res = await fetch("https://api.example.com/users", {
    next: { revalidate: 60 }, // ISR: 60 seconds
  });

  if (!res.ok) {
    // Throws hit app/.../error.tsx — let it bubble.
    throw new Error(`Failed to fetch users: ${res.status}`);
  }

  return res.json();
}

// ─── Async Server Component ──────────────────────────────────────────────────

async function UsersList() {
  const users = await fetchUsers();

  if (users.length === 0) {
    return <p className="text-gray-500">No users yet.</p>;
  }

  return (
    <ul className="space-y-2">
      {users.map((user) => (
        <li key={user.id} className="border-b py-2">
          <strong>{user.name}</strong> — {user.email}
        </li>
      ))}
    </ul>
  );
}

// ─── Page component ──────────────────────────────────────────────────────────

export default function UsersPage() {
  return (
    <main className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Users</h1>

      <Suspense fallback={<p className="text-gray-400">Loading users...</p>}>
        <UsersList />
      </Suspense>
    </main>
  );
}

// ─── Companion files to create (in same directory) ───────────────────────────
//
// app/[route]/loading.tsx — shown while page is loading (or use Suspense above)
//   export default function Loading() {
//     return <p>Loading...</p>;
//   }
//
// app/[route]/error.tsx — error boundary (must be "use client")
//   "use client";
//   export default function Error({ error, reset }: { error: Error; reset: () => void }) {
//     return (
//       <div>
//         <p>Something went wrong: {error.message}</p>
//         <button onClick={reset}>Try again</button>
//       </div>
//     );
//   }
//
// app/[route]/not-found.tsx — 404 page
//   export default function NotFound() {
//     return <p>User not found.</p>;
//   }
