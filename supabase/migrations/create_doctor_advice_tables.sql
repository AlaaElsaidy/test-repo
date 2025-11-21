-- Create doctor_advice table
CREATE TABLE IF NOT EXISTS doctor_advice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT,
  tips TEXT[], -- Array of tips
  video_url TEXT,
  video_storage_path TEXT,
  is_draft BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctor_advice_recipients table to link advice to family members
CREATE TABLE IF NOT EXISTS doctor_advice_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advice_id UUID NOT NULL REFERENCES doctor_advice(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES family_members(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(advice_id, family_member_id)
);

-- Create index for doctor_advice
CREATE INDEX IF NOT EXISTS idx_doctor_advice_doctor_id ON doctor_advice(doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_advice_is_draft ON doctor_advice(is_draft);
CREATE INDEX IF NOT EXISTS idx_doctor_advice_created_at ON doctor_advice(created_at DESC);

-- Create index for doctor_advice_recipients
CREATE INDEX IF NOT EXISTS idx_doctor_advice_recipients_advice_id ON doctor_advice_recipients(advice_id);
CREATE INDEX IF NOT EXISTS idx_doctor_advice_recipients_family_member_id ON doctor_advice_recipients(family_member_id);

-- Enable Row Level Security
ALTER TABLE doctor_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_advice_recipients ENABLE ROW LEVEL SECURITY;

-- RLS Policies for doctor_advice
CREATE POLICY "Doctors can manage their own advice"
  ON doctor_advice FOR ALL
  USING (doctor_id = auth.uid());

CREATE POLICY "Family members can view advice sent to them"
  ON doctor_advice FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM doctor_advice_recipients dar
      WHERE dar.advice_id = doctor_advice.id
      AND dar.family_member_id = auth.uid()
    )
    OR is_draft = false
  );

-- RLS Policies for doctor_advice_recipients
CREATE POLICY "Doctors can manage recipients"
  ON doctor_advice_recipients FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM doctor_advice da
      WHERE da.id = doctor_advice_recipients.advice_id
      AND da.doctor_id = auth.uid()
    )
  );

CREATE POLICY "Family members can view and update their own recipient records"
  ON doctor_advice_recipients FOR SELECT
  USING (family_member_id = auth.uid());

CREATE POLICY "Family members can update read status"
  ON doctor_advice_recipients FOR UPDATE
  USING (family_member_id = auth.uid())
  WITH CHECK (family_member_id = auth.uid());

