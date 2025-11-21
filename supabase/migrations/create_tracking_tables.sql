-- Create patient_locations table for storing real-time patient locations
CREATE TABLE IF NOT EXISTS patient_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_patient_locations_patient_id ON patient_locations(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_locations_created_at ON patient_locations(created_at DESC);

-- Create safe_zones table
CREATE TABLE IF NOT EXISTS safe_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  family_member_id UUID REFERENCES family_members(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters DOUBLE PRECISION NOT NULL DEFAULT 100,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for safe_zones
CREATE INDEX IF NOT EXISTS idx_safe_zones_patient_id ON safe_zones(patient_id);
CREATE INDEX IF NOT EXISTS idx_safe_zones_family_member_id ON safe_zones(family_member_id);

-- Create location_history table for tracking patient movement history
CREATE TABLE IF NOT EXISTS location_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  place_name TEXT,
  arrived_at TIMESTAMP WITH TIME ZONE NOT NULL,
  left_at TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for location_history
CREATE INDEX IF NOT EXISTS idx_location_history_patient_id ON location_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_history_arrived_at ON location_history(arrived_at DESC);

-- Enable Row Level Security
ALTER TABLE patient_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE safe_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for patient_locations
CREATE POLICY "Family members can view their patients' locations"
  ON patient_locations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM patient_family_relations pfr
      WHERE pfr.patient_id = patient_locations.patient_id
      AND pfr.family_member_id = auth.uid()
    )
  );

CREATE POLICY "Patients can view their own locations"
  ON patient_locations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_locations.patient_id
      AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Patients can insert their own locations"
  ON patient_locations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_locations.patient_id
      AND p.user_id = auth.uid()
    )
  );

-- RLS Policies for safe_zones
CREATE POLICY "Family members can manage safe zones for their patients"
  ON safe_zones FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM patient_family_relations pfr
      WHERE pfr.patient_id = safe_zones.patient_id
      AND pfr.family_member_id = auth.uid()
    )
  );

CREATE POLICY "Patients can view safe zones"
  ON safe_zones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = safe_zones.patient_id
      AND p.user_id = auth.uid()
    )
  );

-- RLS Policies for location_history
CREATE POLICY "Family members can view their patients' location history"
  ON location_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM patient_family_relations pfr
      WHERE pfr.patient_id = location_history.patient_id
      AND pfr.family_member_id = auth.uid()
    )
  );

CREATE POLICY "Patients can view their own location history"
  ON location_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = location_history.patient_id
      AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Patients can insert their own location history"
  ON location_history FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = location_history.patient_id
      AND p.user_id = auth.uid()
    )
  );

