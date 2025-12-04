-- Migration: Create isolated chat_messages table

-- Drop old table if exists (to ensure clean migration)
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chat_messages_content_chk CHECK (
        (message_type = 'text' AND content IS NOT NULL) OR
        (message_type IN ('image','file') AND file_url IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_chat_msgs_conversation ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_msgs_sender ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_msgs_created ON public.chat_messages(created_at DESC);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_messages'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages';
  END IF;
END
$$;

COMMENT ON TABLE public.chat_messages IS 'New isolated chat messages table';

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

