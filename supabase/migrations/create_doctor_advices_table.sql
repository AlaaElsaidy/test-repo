-- Migration: Create doctor_advices table to store tips/videos sent from doctors to family members

CREATE TABLE IF NOT EXISTS public.doctor_advices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    patient_id UUID REFERENCES public.patients(id) ON DELETE SET NULL,
    family_member_id UUID REFERENCES public.family_members(id) ON DELETE CASCADE,
    title TEXT,
    tips JSONB NOT NULL DEFAULT '[]'::jsonb,
    video_url TEXT,
    thumbnail_url TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_doctor_advices_doctor_id ON public.doctor_advices(doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_advices_family_id ON public.doctor_advices(family_member_id);
CREATE INDEX IF NOT EXISTS idx_doctor_advices_patient_id ON public.doctor_advices(patient_id);

-- Trigger to keep updated_at fresh
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trg_doctor_advices_updated_at ON public.doctor_advices;
CREATE TRIGGER trg_doctor_advices_updated_at
BEFORE UPDATE ON public.doctor_advices
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS (Row Level Security) policies
ALTER TABLE public.doctor_advices ENABLE ROW LEVEL SECURITY;

-- Policy: Doctors can view their own advice
CREATE POLICY "Doctors can view their own advice"
ON public.doctor_advices
FOR SELECT
USING (
    doctor_id IN (
        SELECT id FROM public.users
        WHERE id = auth.uid()
    )
);

-- Policy: Doctors can insert their own advice
CREATE POLICY "Doctors can insert their own advice"
ON public.doctor_advices
FOR INSERT
WITH CHECK (
    doctor_id IN (
        SELECT id FROM public.users
        WHERE id = auth.uid()
    )
);

-- Policy: Doctors can update their own advice
CREATE POLICY "Doctors can update their own advice"
ON public.doctor_advices
FOR UPDATE
USING (
    doctor_id IN (
        SELECT id FROM public.users
        WHERE id = auth.uid()
    )
)
WITH CHECK (
    doctor_id IN (
        SELECT id FROM public.users
        WHERE id = auth.uid()
    )
);

-- Policy: Doctors can delete their own advice
CREATE POLICY "Doctors can delete their own advice"
ON public.doctor_advices
FOR DELETE
USING (
    doctor_id IN (
        SELECT id FROM public.users
        WHERE id = auth.uid()
    )
);

-- Policy: Family members can view advice sent to them
CREATE POLICY "Family members can view their advice"
ON public.doctor_advices
FOR SELECT
USING (
    family_member_id = auth.uid()
);

