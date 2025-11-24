-- Migration: Create location_history table to store patient location history

CREATE TABLE IF NOT EXISTS public.location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_location_history_patient_id ON public.location_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_history_created_at ON public.location_history(created_at DESC);

-- Index for efficient queries by patient and date range
CREATE INDEX IF NOT EXISTS idx_location_history_patient_date ON public.location_history(patient_id, created_at DESC);

