-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  family_member_id UUID REFERENCES family_members(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  reminder_type TEXT CHECK (reminder_type IN ('alarm', 'vibrate', 'none')),
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for activities
CREATE INDEX IF NOT EXISTS idx_activities_patient_id ON activities(patient_id);
CREATE INDEX IF NOT EXISTS idx_activities_family_member_id ON activities(family_member_id);
CREATE INDEX IF NOT EXISTS idx_activities_scheduled_date ON activities(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_activities_is_completed ON activities(is_completed);

-- Enable Row Level Security
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies for activities
CREATE POLICY "Family members can manage activities for their patients"
  ON activities FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM patient_family_relations pfr
      WHERE pfr.patient_id = activities.patient_id
      AND pfr.family_member_id = auth.uid()
    )
  );

CREATE POLICY "Patients can view and update their own activities"
  ON activities FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = activities.patient_id
      AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Patients can update completion status"
  ON activities FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = activities.patient_id
      AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = activities.patient_id
      AND p.user_id = auth.uid()
    )
  );

