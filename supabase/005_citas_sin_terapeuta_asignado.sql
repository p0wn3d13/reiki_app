-- Modelo de sesiones grupales: una cita es una plaza de una franja,
-- no una relacion con un terapeuta concreto.
-- Ejecutar despues de 004_agenda_compartida.sql.
-- Conserva clientes, terapeutas y horas; limpia solo la asignacion antigua.

begin;

alter table public.citas
  alter column terapeuta_id drop not null;

-- Las citas ya no ocupan una plaza individual de terapeuta.
drop index if exists public.citas_terapeuta_franja_activa_uidx;

-- No se permite que un cliente reserve dos veces la misma franja.
drop index if exists public.citas_cliente_franja_activa_uidx;
create unique index if not exists citas_cliente_franja_activa_uidx
  on public.citas (cliente_id, fecha_hora)
  where estado in ('confirmada', 'completada');

-- Elimina la asignacion individual previa. Las citas pasan a ser grupales.
update public.citas
set terapeuta_id = null
where terapeuta_id is not null;

create or replace function public.create_appointment_by_slot(
  p_fecha_hora timestamptz,
  p_notas text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  cliente uuid := auth.uid();
  plazas_totales integer;
  plazas_ocupadas integer;
  cita_id uuid;
  dia smallint := extract(isodow from p_fecha_hora at time zone 'Europe/Madrid');
  hora time := (p_fecha_hora at time zone 'Europe/Madrid')::time;
begin
  if cliente is null then
    raise exception 'Debes iniciar sesion para reservar';
  end if;

  if p_fecha_hora <= now() then
    raise exception 'La franja debe estar en el futuro';
  end if;

  -- Serializa reservas de la misma franja para no superar la capacidad.
  perform pg_advisory_xact_lock(
    hashtextextended((p_fecha_hora at time zone 'UTC')::text, 0)
  );

  select count(distinct t.id)::integer
  into plazas_totales
  from public.terapeutas t
  join public.disponibilidad d on d.terapeuta_id = t.id
  where t.activo = true
    and d.dia_semana = dia
    and d.hora_inicio = hora
    and d.hora_fin = hora + interval '2 hours';

  select count(*)::integer
  into plazas_ocupadas
  from public.citas c
  where c.fecha_hora = p_fecha_hora
    and c.estado in ('confirmada', 'completada');

  if plazas_totales = 0 then
    raise exception 'No hay terapeutas apuntados a esa franja';
  end if;

  if plazas_ocupadas >= plazas_totales then
    raise exception 'No quedan plazas disponibles para esa franja';
  end if;

  insert into public.citas (
    cliente_id,
    terapeuta_id,
    fecha_hora,
    estado,
    notas
  )
  values (
    cliente,
    null,
    p_fecha_hora,
    'confirmada',
    nullif(trim(p_notas), '')
  )
  returning id into cita_id;

  return cita_id;
exception
  when unique_violation then
    raise exception 'Ya tienes una reserva en esa franja';
end;
$$;

revoke all on function public.create_appointment_by_slot(timestamptz, text)
  from public;
grant execute on function public.create_appointment_by_slot(timestamptz, text)
  to authenticated;

-- Como ya no existe un terapeuta asignado, cualquier miembro del equipo
-- puede actualizar el estado operativo de una sesion grupal.
drop policy if exists citas_update on public.citas;
create policy citas_update
on public.citas for update to authenticated
using (
  cliente_id = auth.uid()
  or public.usuario_es_staff()
  or public.usuario_es_admin()
)
with check (
  cliente_id = auth.uid()
  or public.usuario_es_staff()
  or public.usuario_es_admin()
);

commit;
