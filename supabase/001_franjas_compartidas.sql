-- Franjas compartidas de Reiki.
-- Ejecutar en Supabase SQL Editor con el proyecto detenido.
-- Conserva usuarios, perfiles y citas existentes.

begin;

-- Una ficha de terapeuta pertenece a un unico usuario.
create unique index if not exists terapeutas_user_id_uidx
  on public.terapeutas (user_id);

-- Evita dos bloques identicos para el mismo terapeuta.
create unique index if not exists disponibilidad_terapeuta_franja_uidx
  on public.disponibilidad (terapeuta_id, dia_semana, hora_inicio, hora_fin);

-- Una plaza solo puede ocuparse una vez en una franja activa.
create unique index if not exists citas_terapeuta_franja_activa_uidx
  on public.citas (terapeuta_id, fecha_hora)
  where estado in ('pendiente', 'confirmada');

-- Un cliente no puede reservar dos veces la misma franja.
create unique index if not exists citas_cliente_franja_activa_uidx
  on public.citas (cliente_id, fecha_hora)
  where estado in ('pendiente', 'confirmada');

-- Horario comun: miercoles y jueves, una franja de manana y otra de tarde.
-- 3 = miercoles, 4 = jueves. Cada terapeuta tendra cuatro franjas semanales.
delete from public.disponibilidad;

insert into public.disponibilidad (
  terapeuta_id,
  dia_semana,
  hora_inicio,
  hora_fin
)
select
  t.id,
  franjas.dia_semana,
  franjas.hora_inicio::time,
  franjas.hora_fin::time
from public.terapeutas t
cross join (
  values
    (3, '10:00', '12:00'),
    (3, '16:00', '18:00'),
    (4, '10:00', '12:00'),
    (4, '16:00', '18:00')
) as franjas(dia_semana, hora_inicio, hora_fin)
where t.activo = true;

-- Comprueba que la franja solicitada pertenece a la disponibilidad
-- y asigna una plaza libre de forma atomica.
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

commit;

-- Comprobacion: cada franja muestra la capacidad por numero de terapeutas.
select
  d.dia_semana,
  d.hora_inicio,
  d.hora_fin,
  count(distinct d.terapeuta_id) as plazas_totales,
  count(distinct c.id) filter (
    where c.estado in ('pendiente', 'confirmada')
  ) as plazas_ocupadas
from public.disponibilidad d
join public.terapeutas t on t.id = d.terapeuta_id and t.activo = true
left join public.citas c
  on c.terapeuta_id = d.terapeuta_id
 and c.fecha_hora::time = d.hora_inicio
 and extract(isodow from c.fecha_hora at time zone 'Europe/Madrid') = d.dia_semana
 group by d.dia_semana, d.hora_inicio, d.hora_fin
 order by d.dia_semana, d.hora_inicio;
