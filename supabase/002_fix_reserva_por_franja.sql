-- Repara/instala la funcion usada por la pantalla Nueva reserva.
-- No borra datos ni disponibilidades.

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
  terapeuta_libre uuid;
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

  if exists (
    select 1
    from public.citas c
    where c.cliente_id = cliente
      and c.fecha_hora = p_fecha_hora
      and c.estado in ('pendiente', 'confirmada')
  ) then
    raise exception 'Ya tienes una cita reservada en esa franja';
  end if;

  select t.id
  into terapeuta_libre
  from public.terapeutas t
  join public.disponibilidad d on d.terapeuta_id = t.id
  where t.activo = true
    and d.dia_semana = dia
    and d.hora_inicio = hora
    and d.hora_fin = hora + interval '2 hours'
    and not exists (
      select 1
      from public.citas c
      where c.terapeuta_id = t.id
        and c.fecha_hora = p_fecha_hora
        and c.estado in ('pendiente', 'confirmada')
    )
  order by t.id
  limit 1
  for update of t skip locked;

  if terapeuta_libre is null then
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
    terapeuta_libre,
    p_fecha_hora,
    'confirmada',
    nullif(trim(p_notas), '')
  )
  returning id into cita_id;

  return cita_id;
exception
  when unique_violation then
    raise exception 'La ultima plaza acaba de ser ocupada. Elige otra franja';
end;
$$;

revoke all on function public.create_appointment_by_slot(timestamptz, text)
  from public;
grant execute on function public.create_appointment_by_slot(timestamptz, text)
  to authenticated;

-- Necesaria para que la app pueda leer la cita creada despues de la RPC.
-- Si ya existe una politica equivalente, esta sentencia no hace nada.
alter table public.citas enable row level security;
drop policy if exists citas_select_propias on public.citas;
create policy citas_select_propias
on public.citas
for select
to authenticated
using (cliente_id = auth.uid());
