-- Agenda compartida para coordinacion del equipo.
-- Ejecutar despues de 003_rls_policies.sql.
-- No modifica ni borra citas.

begin;

create or replace function public.usuario_es_staff()
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
      and rol in ('terapeuta', 'admin')
  );
$$;

revoke all on function public.usuario_es_staff() from public;
grant execute on function public.usuario_es_staff() to authenticated;

-- El equipo necesita identificar al cliente y al terapeuta asignado
-- para coordinar la franja.
drop policy if exists perfiles_select on public.perfiles;
create policy perfiles_select
on public.perfiles for select to authenticated
using (
  id = auth.uid()
  or public.usuario_es_admin()
  or public.perfil_es_terapeuta_activo(id)
  or public.usuario_es_staff()
);

drop policy if exists citas_select on public.citas;
create policy citas_select
on public.citas for select to authenticated
using (
  cliente_id = auth.uid()
  or public.usuario_es_terapeuta_de(terapeuta_id)
  or public.usuario_es_staff()
  or public.usuario_es_admin()
);

commit;
