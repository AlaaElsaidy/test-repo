-- Migration: Create safe_zones table to store safe zones for patients

CREATE TABLE IF NOT EXISTS public.safe_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_safe_zones_patient_id ON public.safe_zones(patient_id);
CREATE INDEX IF NOT EXISTS idx_safe_zones_is_active ON public.safe_zones(is_active);

-- Trigger to keep updated_at fresh
DROP TRIGGER IF EXISTS trg_safe_zones_updated_at ON public.safe_zones;
CREATE TRIGGER trg_safe_zones_updated_at
BEFORE UPDATE ON public.safe_zones
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

