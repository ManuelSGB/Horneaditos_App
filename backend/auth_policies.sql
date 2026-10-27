-- Remove the unrestricted policies before enabling app authentication.
DROP POLICY IF EXISTS "Permitir todo en users" ON public.users;
DROP POLICY IF EXISTS "Permitir todo en foro" ON public.foro;
DROP POLICY IF EXISTS "Users can read their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can create their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Anyone can read forum recipes" ON public.foro;
DROP POLICY IF EXISTS "Users can create their own recipes" ON public.foro;
DROP POLICY IF EXISTS "Users can update their own recipes" ON public.foro;
DROP POLICY IF EXISTS "Users can delete their own recipes" ON public.foro;

CREATE POLICY "Users can read their own profile"
ON public.users
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can create their own profile"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT auth.uid()) = id
  AND rol = 'user'
  AND estado = 'activo'
);

CREATE POLICY "Users can update their own profile"
ON public.users
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "Anyone can read forum recipes"
ON public.foro
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Users can create their own recipes"
ON public.foro
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own recipes"
ON public.foro
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete their own recipes"
ON public.foro
FOR DELETE
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- A user may update profile fields, but never promote their own role or status.
REVOKE ALL ON public.users FROM anon;
REVOKE UPDATE ON public.users FROM authenticated;
GRANT UPDATE (id, nombre, apellido, correo, updated_at)
ON public.users TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.foro FROM anon;
GRANT SELECT ON public.users TO authenticated;
GRANT INSERT ON public.users TO authenticated;
GRANT SELECT ON public.foro TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.foro TO authenticated;
