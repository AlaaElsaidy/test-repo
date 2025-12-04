-- ============================================================
-- FINAL FIX: Complete Chat System Setup
-- Run this script in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1) Drop existing policies (clean slate)
-- ============================================================

-- chat_conversations policies
DROP POLICY IF EXISTS chat_conv_doctor_select ON public.chat_conversations;
DROP POLICY IF EXISTS chat_conv_patient_select ON public.chat_conversations;
DROP POLICY IF EXISTS chat_conv_family_select ON public.chat_conversations;
DROP POLICY IF EXISTS chat_conv_doctor_insert ON public.chat_conversations;
DROP POLICY IF EXISTS chat_conv_patient_insert ON public.chat_conversations;
DROP POLICY IF EXISTS chat_conv_family_insert ON public.chat_conversations;
DROP POLICY IF EXISTS chat_conv_update ON public.chat_conversations;

-- chat_messages policies
DROP POLICY IF EXISTS chat_msgs_select ON public.chat_messages;
DROP POLICY IF EXISTS chat_msgs_insert ON public.chat_messages;
DROP POLICY IF EXISTS chat_msgs_update ON public.chat_messages;

-- ============================================================
-- 2) Recreate chat_messages table with correct schema
-- ============================================================

DROP TABLE IF EXISTS public.chat_messages CASCADE;

CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    sender_type public.chat_sender_type_enum NOT NULL,
    message_type public.chat_message_type_enum NOT NULL DEFAULT 'text',
    content TEXT,
    file_url TEXT,
    file_name TEXT,
    file_size INTEGER,
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chat_messages_content_chk CHECK (
        (message_type = 'text' AND content IS NOT NULL)
        OR (message_type IN ('image','file') AND file_url IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_chat_msgs_conversation ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_msgs_sender ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_msgs_created ON public.chat_messages(created_at DESC);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 3) Add to realtime publication (if not already)
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_messages'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages';
  END IF;
END
$$;

-- ============================================================
-- 4) Create CORRECT RLS Policies
-- NOTE: family_members.id = auth.uid() directly (no user_id column)
--       patients.id requires lookup via user_id
-- ============================================================

-- === chat_conversations SELECT ===

CREATE POLICY chat_conv_doctor_select
ON public.chat_conversations FOR SELECT
USING (doctor_id::text = auth.uid()::text AND is_active = true);

CREATE POLICY chat_conv_patient_select
ON public.chat_conversations FOR SELECT
USING (
  patient_id::text IN (
    SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
  ) AND is_active = true
);

-- family_members.id = auth.uid() directly
CREATE POLICY chat_conv_family_select
ON public.chat_conversations FOR SELECT
USING (family_member_id::text = auth.uid()::text AND is_active = true);

-- === chat_conversations INSERT ===

CREATE POLICY chat_conv_doctor_insert
ON public.chat_conversations FOR INSERT
WITH CHECK (doctor_id::text = auth.uid()::text);

CREATE POLICY chat_conv_patient_insert
ON public.chat_conversations FOR INSERT
WITH CHECK (
  patient_id::text IN (
    SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
  )
);

-- family_members.id = auth.uid() directly
CREATE POLICY chat_conv_family_insert
ON public.chat_conversations FOR INSERT
WITH CHECK (family_member_id::text = auth.uid()::text);

-- === chat_conversations UPDATE ===

CREATE POLICY chat_conv_update
ON public.chat_conversations FOR UPDATE
USING (
    doctor_id::text = auth.uid()::text
    OR patient_id::text IN (
        SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
    )
    OR family_member_id::text = auth.uid()::text
)
WITH CHECK (
    doctor_id::text = auth.uid()::text
    OR patient_id::text IN (
        SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
    )
    OR family_member_id::text = auth.uid()::text
);

-- === chat_messages SELECT ===

CREATE POLICY chat_msgs_select
ON public.chat_messages FOR SELECT
USING (
  conversation_id IN (
    SELECT id FROM public.chat_conversations
    WHERE is_active = true AND (
      doctor_id::text = auth.uid()::text
      OR patient_id::text IN (
          SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
        )
      OR family_member_id::text = auth.uid()::text
    )
  )
);

-- === chat_messages INSERT ===

CREATE POLICY chat_msgs_insert
ON public.chat_messages FOR INSERT
WITH CHECK (
  sender_id::text = auth.uid()::text AND
  conversation_id IN (
    SELECT id FROM public.chat_conversations
    WHERE is_active = true AND (
      doctor_id::text = auth.uid()::text
      OR patient_id::text IN (
          SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
        )
      OR family_member_id::text = auth.uid()::text
    )
  )
);

-- === chat_messages UPDATE ===

CREATE POLICY chat_msgs_update
ON public.chat_messages FOR UPDATE
USING (
  conversation_id IN (
    SELECT id FROM public.chat_conversations
    WHERE is_active = true AND (
      doctor_id::text = auth.uid()::text
      OR patient_id::text IN (
          SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
        )
      OR family_member_id::text = auth.uid()::text
    )
  )
)
WITH CHECK (
  conversation_id IN (
    SELECT id FROM public.chat_conversations
    WHERE is_active = true AND (
      doctor_id::text = auth.uid()::text
      OR patient_id::text IN (
          SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
        )
      OR family_member_id::text = auth.uid()::text
    )
  )
);

-- ============================================================
-- 5) Force PostgREST to reload schema cache
-- ============================================================

NOTIFY pgrst, 'reload schema';

-- ============================================================
-- 6) Verify setup
-- ============================================================

-- Show all chat_messages columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'chat_messages' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename IN ('chat_conversations', 'chat_messages')
ORDER BY tablename, policyname;
