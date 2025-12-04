-- Verify Realtime publication configuration for chat_messages

-- 1. Check if chat_messages is in the realtime publication
SELECT 
    pubname,
    schemaname,
    tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND schemaname = 'public'
  AND tablename = 'chat_messages';

-- 2. If not found, add it
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
    RAISE NOTICE 'Added chat_messages to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'chat_messages is already in supabase_realtime publication';
  END IF;
END
$$;

-- 3. Verify Realtime is enabled for the table
SELECT 
    schemaname,
    tablename,
    CASE 
      WHEN EXISTS (
        SELECT 1 
        FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
          AND schemaname = 'public' 
          AND tablename = 'chat_messages'
      ) THEN 'Enabled'
      ELSE 'Disabled'
    END as realtime_status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'chat_messages';

-- 4. Force reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';


