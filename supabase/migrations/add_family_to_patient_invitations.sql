-- Migration: Add support for Family-to-Patient invitations
-- This migration adds new columns to the invitations table to support bidirectional invitations

-- Make patient_id nullable (for family-to-patient invitations)
ALTER TABLE invitations 
ALTER COLUMN patient_id DROP NOT NULL;

-- Add new columns for family-to-patient invitations
ALTER TABLE invitations 
ADD COLUMN IF NOT EXISTS patient_email TEXT,
ADD COLUMN IF NOT EXISTS patient_phone TEXT,
ADD COLUMN IF NOT EXISTS family_member_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS invitation_type TEXT;

-- Add check constraint to ensure invitation_type is valid
ALTER TABLE invitations 
ADD CONSTRAINT check_invitation_type 
CHECK (invitation_type IS NULL OR invitation_type IN ('patient_to_family', 'family_to_patient'));

-- Create index on family_member_id for faster queries
CREATE INDEX IF NOT EXISTS idx_invitations_family_member_id 
ON invitations(family_member_id);

-- Create index on invitation_type for faster filtering
CREATE INDEX IF NOT EXISTS idx_invitations_type 
ON invitations(invitation_type);

-- Update existing invitations to have invitation_type = 'patient_to_family'
UPDATE invitations 
SET invitation_type = 'patient_to_family' 
WHERE invitation_type IS NULL AND patient_id IS NOT NULL;

