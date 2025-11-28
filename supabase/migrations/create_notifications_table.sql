-- Migration: Create notifications table for realtime alerts
-- This table stores notifications sent from patient to family members

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('zone_exit', 'zone_enter', 'reminder_missed', 'emergency', 'activity_completed', 'general')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}', -- Additional data (location, activity details, etc.)
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON public.notifications(patient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_family_member_id ON public.notifications(family_member_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- Enable Realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Comments
COMMENT ON TABLE public.notifications IS 'Stores notifications sent from patient app to family members';
COMMENT ON COLUMN public.notifications.type IS 'Type of notification: zone_exit, zone_enter, reminder_missed, emergency, activity_completed, general';
COMMENT ON COLUMN public.notifications.data IS 'Additional JSON data like location coordinates, activity details, etc.';

