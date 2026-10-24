create table if not exists public.foro (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  categoria text not null check (categoria in ('PASTEL', 'GALLETA', 'PAN', 'POSTRE')),
  nombre text not null,
  duracion text not null,
  ingredientes text not null,
  preparacion text not null,
  imagen text,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create index if not exists recetas_user_updated_index
  on public.foro (user_id, updated_at desc);

alter table public.foro enable row level security;

create policy "Users can read their recipes"
  on public.foro for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their recipes"
  on public.foro for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their recipes"
  on public.foro for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
