-- Migration: Create Safe Zones Table
CREATE TABLE IF NOT EXISTS "public"."safe_zones" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "patient_id" UUID NOT NULL REFERENCES "public"."patients"("id") ON DELETE CASCADE,
  "name" TEXT NOT NULL,
  "address" TEXT,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "radius_meters" DOUBLE PRECISION NOT NULL DEFAULT 200,
  "is_active" BOOLEAN DEFAULT true,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_patient_zone UNIQUE(patient_id, name)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "idx_safe_zones_patient_id" ON "public"."safe_zones"("patient_id");
CREATE INDEX IF NOT EXISTS "idx_safe_zones_active" ON "public"."safe_zones"("patient_id", "is_active");

-- Enable RLS
ALTER TABLE "public"."safe_zones" ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see safe zones for patients they have access to
CREATE POLICY "safe_zones_select" ON "public"."safe_zones"
  FOR SELECT
  USING (
    -- Patient can see their own safe zones
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
    OR
    -- Doctor can see safe zones for their patients
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
    OR
    -- Family can see safe zones for patients they're assigned to
    EXISTS (
      SELECT 1 FROM "public"."family_members"
      WHERE patient_id = safe_zones.patient_id
      AND id = auth.uid()
    )
  );

-- RLS Policy: Only doctor or patient can insert safe zones
CREATE POLICY "safe_zones_insert" ON "public"."safe_zones"
  FOR INSERT
  WITH CHECK (
    -- Patient can add their own zones
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
    OR
    -- Doctor can add zones for their patients
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
  );

-- RLS Policy: Only doctor or patient can update safe zones
CREATE POLICY "safe_zones_update" ON "public"."safe_zones"
  FOR UPDATE
  USING (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
    OR
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
  );

-- RLS Policy: Only doctor or patient can delete safe zones
CREATE POLICY "safe_zones_delete" ON "public"."safe_zones"
  FOR DELETE
  USING (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
    OR
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = safe_zones.patient_id
    )
  );

-- Migration: Create Location Updates Table
CREATE TABLE IF NOT EXISTS "public"."location_updates" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "patient_id" UUID NOT NULL REFERENCES "public"."patients"("id") ON DELETE CASCADE,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "address" TEXT,
  "accuracy" DOUBLE PRECISION,
  "timestamp" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "idx_location_updates_patient_id" ON "public"."location_updates"("patient_id");
CREATE INDEX IF NOT EXISTS "idx_location_updates_timestamp" ON "public"."location_updates"("patient_id", "timestamp" DESC);

-- Enable RLS
ALTER TABLE "public"."location_updates" ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see location updates for patients they have access to
CREATE POLICY "location_updates_select" ON "public"."location_updates"
  FOR SELECT
  USING (
    -- Patient can see their own location
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = location_updates.patient_id
    )
    OR
    -- Doctor can see location of their patients
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = location_updates.patient_id
    )
    OR
    -- Family can see location of their assigned patient
    EXISTS (
      SELECT 1 FROM "public"."family_members"
      WHERE patient_id = location_updates.patient_id
      AND id = auth.uid()
    )
  );

-- RLS Policy: Only patient can insert their own location
CREATE POLICY "location_updates_insert" ON "public"."location_updates"
  FOR INSERT
  WITH CHECK (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = location_updates.patient_id
    )
  );

-- Migration: Create Location History Table
CREATE TABLE IF NOT EXISTS "public"."location_history" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "patient_id" UUID NOT NULL REFERENCES "public"."patients"("id") ON DELETE CASCADE,
  "place_name" TEXT,
  "address" TEXT,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "arrived_at" TIMESTAMP WITH TIME ZONE NOT NULL,
  "departed_at" TIMESTAMP WITH TIME ZONE,
  "duration_minutes" INTEGER,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS "idx_location_history_patient_id" ON "public"."location_history"("patient_id");
CREATE INDEX IF NOT EXISTS "idx_location_history_arrived_at" ON "public"."location_history"("patient_id", "arrived_at" DESC);

-- Enable RLS
ALTER TABLE "public"."location_history" ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see history for patients they have access to
CREATE POLICY "location_history_select" ON "public"."location_history"
  FOR SELECT
  USING (
    -- Patient can see their own history
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = location_history.patient_id
    )
    OR
    -- Doctor can see history of their patients
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = location_history.patient_id
    )
    OR
    -- Family can see history of their assigned patient
    EXISTS (
      SELECT 1 FROM "public"."family_members"
      WHERE patient_id = location_history.patient_id
      AND id = auth.uid()
    )
  );

-- RLS Policy: Only patient can insert history (backend should populate)
CREATE POLICY "location_history_insert" ON "public"."location_history"
  FOR INSERT
  WITH CHECK (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = location_history.patient_id
    )
  );

-- RLS Policy: Only patient can update history
CREATE POLICY "location_history_update" ON "public"."location_history"
  FOR UPDATE
  USING (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = location_history.patient_id
    )
  );

-- Migration: Create Emergency Contacts Table
CREATE TABLE IF NOT EXISTS "public"."emergency_contacts" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "patient_id" UUID NOT NULL REFERENCES "public"."patients"("id") ON DELETE CASCADE,
  "name" TEXT NOT NULL,
  "phone" TEXT NOT NULL,
  "relationship" TEXT,
  "is_primary" BOOLEAN DEFAULT false,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_patient_emergency_contact UNIQUE(patient_id, phone)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_emergency_contacts_patient_id" ON "public"."emergency_contacts"("patient_id");

-- Enable RLS
ALTER TABLE "public"."emergency_contacts" ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access emergency contacts for patients they have access to
CREATE POLICY "emergency_contacts_select" ON "public"."emergency_contacts"
  FOR SELECT
  USING (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
    OR
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
  );

-- RLS Policy: Only patient or doctor can manage emergency contacts
CREATE POLICY "emergency_contacts_insert" ON "public"."emergency_contacts"
  FOR INSERT
  WITH CHECK (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
    OR
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
  );

CREATE POLICY "emergency_contacts_update" ON "public"."emergency_contacts"
  FOR UPDATE
  USING (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
    OR
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
  );

CREATE POLICY "emergency_contacts_delete" ON "public"."emergency_contacts"
  FOR DELETE
  USING (
    auth.uid() = (
      SELECT user_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
    OR
    auth.uid() = (
      SELECT doctor_id FROM "public"."patients" WHERE id = emergency_contacts.patient_id
    )
  );
