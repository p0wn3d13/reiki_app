-- Seguridad RLS para la app Reiki.
-- Ejecutar despues de 001_franjas_compartidas.sql y 002_fix_reserva_por_franja.sql.
-- No borra datos.

begin;

-- Helpers SECURITY DEFINER para que las politicas no consulten perfiles
-- recursivamente con el mismo usuario.
create or replace function public.usuario_es_admin()
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.perfiles
    where id = auth.uid()
      and rol = 'admin'
  );
$$;

create or replace function public.usuario_es_terapeuta_de(p_terapeuta_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.terapeutas
    where id = p_terapeuta_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.perfil_es_terapeuta_activo(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.terapeutas
    where user_id = p_user_id
      and activo = true
  );
$$;

create or replace function public.rol_usuario_actual()
returns text
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select rol
  from public.perfiles
  where id = auth.uid();
$$;

revoke all on function public.usuario_es_admin() from public;
revoke all on function public.usuario_es_terapeuta_de(uuid) from public;
revoke all on function public.perfil_es_terapeuta_activo(uuid) from public;
revoke all on function public.rol_usuario_actual() from public;
grant execute on function public.usuario_es_admin() to authenticated;
grant execute on function public.usuario_es_terapeuta_de(uuid) to authenticated;
grant execute on function public.perfil_es_terapeuta_activo(uuid) to authenticated;
grant execute on function public.rol_usuario_actual() to authenticated;

-- PERF files: cada usuario ve su fila; admin ve y gestiona todas.
alter table public.perfiles enable row level security;
drop policy if exists perfiles_select on public.perfiles;
drop policy if exists perfiles_insert on public.perfiles;
drop policy if exists perfiles_update on public.perfiles;
create policy perfiles_select
on public.perfiles for select to authenticated
using (
  id = auth.uid()
  or public.usuario_es_admin()
  or public.perfil_es_terapeuta_activo(id)
);
create policy perfiles_insert
on public.perfiles for insert to authenticated
with check (
  public.usuario_es_admin()
  or (id = auth.uid() and rol = 'cliente')
);
create policy perfiles_update
on public.perfiles for update to authenticated
using (id = auth.uid() or public.usuario_es_admin())
with check (
  public.usuario_es_admin()
  or (id = auth.uid() and rol = public.rol_usuario_actual())
);

-- TERAPEUTAS: usuarios autenticados ven fichas activas; admin y el propio
-- terapeuta pueden trabajar con cualquier estado necesario.
alter table public.terapeutas enable row level security;
drop policy if exists terapeutas_select on public.terapeutas;
drop policy if exists terapeutas_insert on public.terapeutas;
drop policy if exists terapeutas_update on public.terapeutas;
drop policy if exists terapeutas_delete on public.terapeutas;
create policy terapeutas_select
on public.terapeutas for select to authenticated
using (activo = true or user_id = auth.uid() or public.usuario_es_admin());
create policy terapeutas_insert
on public.terapeutas for insert to authenticated
with check (public.usuario_es_admin());
create policy terapeutas_update
on public.terapeutas for update to authenticated
using (user_id = auth.uid() or public.usuario_es_admin())
with check (user_id = auth.uid() or public.usuario_es_admin());
create policy terapeutas_delete
on public.terapeutas for delete to authenticated
using (public.usuario_es_admin());

-- DISPONIBILIDAD: lectura para usuarios autenticados; escritura para el
-- terapeuta propietario o un administrador.
alter table public.disponibilidad enable row level security;
drop policy if exists disponibilidad_select on public.disponibilidad;
drop policy if exists disponibilidad_insert on public.disponibilidad;
drop policy if exists disponibilidad_update on public.disponibilidad;
drop policy if exists disponibilidad_delete on public.disponibilidad;
create policy disponibilidad_select
on public.disponibilidad for select to authenticated
using (true);
create policy disponibilidad_insert
on public.disponibilidad for insert to authenticated
with check (
  public.usuario_es_admin()
  or public.usuario_es_terapeuta_de(terapeuta_id)
);
create policy disponibilidad_update
on public.disponibilidad for update to authenticated
using (
  public.usuario_es_admin()
  or public.usuario_es_terapeuta_de(terapeuta_id)
)
with check (
  public.usuario_es_admin()
  or public.usuario_es_terapeuta_de(terapeuta_id)
);
create policy disponibilidad_delete
on public.disponibilidad for delete to authenticated
using (
  public.usuario_es_admin()
  or public.usuario_es_terapeuta_de(terapeuta_id)
);

-- CITAS: cada parte solo ve sus citas; solo cliente, terapeuta asignado o
-- admin puede cancelar/actualizar. La insercion se hace por RPC.
alter table public.citas enable row level security;
drop policy if exists citas_select on public.citas;
drop policy if exists citas_insert on public.citas;
drop policy if exists citas_update on public.citas;
drop policy if exists citas_delete on public.citas;
create policy citas_select
on public.citas for select to authenticated
using (
  cliente_id = auth.uid()
  or public.usuario_es_terapeuta_de(terapeuta_id)
  or public.usuario_es_admin()
);
create policy citas_insert
on public.citas for insert to authenticated
with check (false);
create policy citas_update
on public.citas for update to authenticated
using (
  cliente_id = auth.uid()
  or public.usuario_es_terapeuta_de(terapeuta_id)
  or public.usuario_es_admin()
)
with check (
  cliente_id = auth.uid()
  or public.usuario_es_terapeuta_de(terapeuta_id)
  or public.usuario_es_admin()
);
create policy citas_delete
on public.citas for delete to authenticated
using (public.usuario_es_admin());

commit;

-- Comprobacion rapida: RLS debe estar activo en estas tablas.
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('perfiles', 'terapeutas', 'disponibilidad', 'citas')
order by tablename;
