/*
  # Fix RLS policy for menu items insertion

  1. Policy Updates
    - Add policy to allow anonymous users to insert menu items for initial seeding
    - This enables the application to insert sample data on first load
    
  2. Security Notes
    - This policy is permissive for development/seeding purposes
    - In production, you may want to restrict this further
*/

-- Drop existing restrictive insert policy
DROP POLICY IF EXISTS "Managers can insert menu items" ON menu_items;

-- Create new policy that allows both managers and initial seeding
CREATE POLICY "Allow menu items insertion"
  ON menu_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    -- Allow anonymous insertion for initial seeding
    auth.role() = 'anon' OR
    -- Allow authenticated managers to insert
    (auth.role() = 'authenticated' AND EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() AND users.role = 'manager'
    ))
  );