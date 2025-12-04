-- Migration: RLS policies for new chat_conversations & chat_messages tables
-- NOTE: family_members.id = auth.uid() directly (no user_id column)
--       patients.id requires lookup via user_id

-- ================= chat_conversations =================

DROP POLICY IF EXISTS chat_conv_doctor_select ON public.chat_conversations;
CREATE POLICY chat_conv_doctor_select
ON public.chat_conversations FOR SELECT
USING (doctor_id::text = auth.uid()::text AND is_active = true);

DROP POLICY IF EXISTS chat_conv_patient_select ON public.chat_conversations;
CREATE POLICY chat_conv_patient_select
ON public.chat_conversations FOR SELECT
USING (
  patient_id::text IN (
    SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
  ) AND is_active = true
);

-- family_members.id = auth.uid() directly
DROP POLICY IF EXISTS chat_conv_family_select ON public.chat_conversations;
CREATE POLICY chat_conv_family_select
ON public.chat_conversations FOR SELECT
USING (family_member_id::text = auth.uid()::text AND is_active = true);

DROP POLICY IF EXISTS chat_conv_doctor_insert ON public.chat_conversations;
CREATE POLICY chat_conv_doctor_insert
ON public.chat_conversations FOR INSERT
WITH CHECK (doctor_id::text = auth.uid()::text);

DROP POLICY IF EXISTS chat_conv_patient_insert ON public.chat_conversations;
CREATE POLICY chat_conv_patient_insert
ON public.chat_conversations FOR INSERT
WITH CHECK (
  patient_id::text IN (
    SELECT id::text FROM public.patients WHERE user_id::text = auth.uid()::text
  )
);

-- family_members.id = auth.uid() directly
DROP POLICY IF EXISTS chat_conv_family_insert ON public.chat_conversations;
CREATE POLICY chat_conv_family_insert
ON public.chat_conversations FOR INSERT
WITH CHECK (family_member_id::text = auth.uid()::text);

DROP POLICY IF EXISTS chat_conv_update ON public.chat_conversations;
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

-- ================= chat_messages =================

DROP POLICY IF EXISTS chat_msgs_select ON public.chat_messages;
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

DROP POLICY IF EXISTS chat_msgs_insert ON public.chat_messages;
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

DROP POLICY IF EXISTS chat_msgs_update ON public.chat_messages;
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

-- Force reload schema cache
NOTIFY pgrst, 'reload schema';
