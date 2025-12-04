-- Migration: Create isolated chat_conversations table and enums

DROP TYPE IF EXISTS public.chat_sender_type_enum CASCADE;
CREATE TYPE public.chat_sender_type_enum AS ENUM ('doctor', 'patient', 'family_member');

DROP TYPE IF EXISTS public.chat_message_type_enum CASCADE;
CREATE TYPE public.chat_message_type_enum AS ENUM ('text', 'image', 'file');

CREATE TABLE IF NOT EXISTS public.chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
    family_member_id UUID REFERENCES public.family_members(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_message_at TIMESTAMPTZ,
    last_message_preview TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT chat_conversations_participant_chk CHECK (
      (patient_id IS NOT NULL AND family_member_id IS NULL) OR
      (patient_id IS NULL AND family_member_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_chat_conv_doctor ON public.chat_conversations(doctor_id);
CREATE INDEX IF NOT EXISTS idx_chat_conv_patient ON public.chat_conversations(patient_id);
CREATE INDEX IF NOT EXISTS idx_chat_conv_family ON public.chat_conversations(family_member_id);
CREATE INDEX IF NOT EXISTS idx_chat_conv_is_active ON public.chat_conversations(is_active);
CREATE INDEX IF NOT EXISTS idx_chat_conv_last_msg ON public.chat_conversations(last_message_at DESC NULLS LAST);

DROP TRIGGER IF EXISTS trg_chat_conv_updated_at ON public.chat_conversations;
CREATE TRIGGER trg_chat_conv_updated_at
BEFORE UPDATE ON public.chat_conversations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.chat_conversations IS 'New isolated chat container table';

