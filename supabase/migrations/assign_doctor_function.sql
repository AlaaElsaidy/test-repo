-- Utility: assign doctor to patient using their emails
create or replace function public.assign_doctor_to_patient(
  patient_email text,
  doctor_email text
) returns void
language plpgsql
as $$
declare
  v_patient_id uuid;
  v_doctor_user_id uuid;
begin
  -- find patient id via user email
  select p.id
  into v_patient_id
  from public.patients p
  join public.users u on u.id = p.user_id
  where lower(u.email) = lower(patient_email);

  if v_patient_id is null then
    raise exception 'Patient with email % not found', patient_email;
  end if;

  -- find doctor user id
  select u.id
  into v_doctor_user_id
  from public.users u
  where lower(u.email) = lower(doctor_email)
    and u.role = 'doctor';

  if v_doctor_user_id is null then
    raise exception 'Doctor with email % not found or not a doctor', doctor_email;
  end if;

  update public.patients
  set doctor_id = v_doctor_user_id
  where id = v_patient_id;
end;
$$;

comment on function public.assign_doctor_to_patient(text, text)
  is 'Assigns doctor to patient via their emails';

