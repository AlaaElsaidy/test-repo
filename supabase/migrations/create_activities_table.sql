-- Migration: Create activities table to store memory activities for patients
-- Family members can add activities for their linked patients
-- Patients can view and mark activities as done

CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    reminder_type TEXT NOT NULL DEFAULT 'alarm' CHECK (reminder_type IN ('alarm', 'vibrate')),
    is_done BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_activities_patient_id ON public.activities(patient_id);
CREATE INDEX IF NOT EXISTS idx_activities_family_member_id ON public.activities(family_member_id);
CREATE INDEX IF NOT EXISTS idx_activities_scheduled_date ON public.activities(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_activities_is_done ON public.activities(is_done);

-- Composite index for common queries (patient + date)
CREATE INDEX IF NOT EXISTS idx_activities_patient_date ON public.activities(patient_id, scheduled_date);

-- Trigger to keep updated_at fresh
DROP TRIGGER IF EXISTS trg_activities_updated_at ON public.activities;
CREATE TRIGGER trg_activities_updated_at
BEFORE UPDATE ON public.activities
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS (Row Level Security) policies
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Policy: Family members can view activities for their linked patients
CREATE POLICY "Family members can view activities for their patients"
ON public.activities
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.patient_family_relations
        WHERE patient_family_relations.patient_id = activities.patient_id
        AND patient_family_relations.family_member_id = activities.family_member_id
    )
    OR family_member_id = auth.uid()
);

-- Policy: Family members can insert activities for their linked patients
CREATE POLICY "Family members can insert activities for their patients"
ON public.activities
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.patient_family_relations
        WHERE patient_family_relations.patient_id = activities.patient_id
        AND patient_family_relations.family_member_id = activities.family_member_id
    )
    AND family_member_id = auth.uid()
);

-- Policy: Family members can update activities they created
CREATE POLICY "Family members can update their activities"
ON public.activities
FOR UPDATE
USING (
    family_member_id = auth.uid()
);

-- Policy: Patients can view their own activities
CREATE POLICY "Patients can view their own activities"
ON public.activities
FOR SELECT
USING (
    patient_id IN (
        SELECT id FROM public.patients
        WHERE user_id = auth.uid()
    )
);

-- Policy: Patients can update is_done status for their activities
-- Note: Restricting updates to is_done only should be handled in application logic or triggers
CREATE POLICY "Patients can toggle done status"
ON public.activities
FOR UPDATE
USING (
    patient_id IN (
        SELECT id FROM public.patients
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients
        WHERE user_id = auth.uid()
    )
);

-- Policy: Family members can delete activities they created
CREATE POLICY "Family members can delete their activities"
ON public.activities
FOR DELETE
USING (
    family_member_id = auth.uid()
);

