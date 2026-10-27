-- Habilitar extensión para generación de UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tabla de Usuarios
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  correo TEXT NOT NULL UNIQUE,
  rol TEXT NOT NULL DEFAULT 'user' CHECK (rol IN ('admin', 'user')),
  estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tabla Foro (Recetas)
CREATE TABLE IF NOT EXISTS public.foro (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  categoria TEXT NOT NULL CHECK (categoria IN ('FRIOS', 'FRITOS', 'CALIENTES')),
  nombre TEXT NOT NULL,
  duracion TEXT NOT NULL,
  ingredientes TEXT NOT NULL,
  preparacion TEXT NOT NULL,
  imagen TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Actualizar la restricción categoria en instalaciones existentes
ALTER TABLE public.foro
DROP CONSTRAINT IF EXISTS foro_categoria_check;

ALTER TABLE public.foro
ADD CONSTRAINT foro_categoria_check
CHECK (categoria IN ('FRIOS', 'FRITOS', 'CALIENTES'));

-- Índice de búsqueda
CREATE INDEX IF NOT EXISTS idx_foro_user_id ON public.foro(user_id);

-- --------------------------------------------------------
-- ACTIVACIÓN Y CONFIGURACIÓN DE RLS (SEGURIDAD)
-- --------------------------------------------------------

-- Habilitar RLS en las dos tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foro ENABLE ROW LEVEL SECURITY;

-- Permitir a usuarios autenticados y anónimos leer y escribir en la tabla users
CREATE POLICY "Permitir todo en users"
ON public.users
FOR ALL
USING (true)
WITH CHECK (true);

-- Permitir a usuarios autenticados y anónimos leer y escribir en la tabla foro
CREATE POLICY "Permitir todo en foro"
ON public.foro
FOR ALL
USING (true)
WITH CHECK (true);
