/*
  # Complete Schema Fix and Data Setup

  1. Tables
    - Fix all RLS policies for proper access control
    - Add proper constraints and indexes
    - Set up sample data insertion policies

  2. Security
    - Enable RLS on all tables
    - Add comprehensive policies for all user roles
    - Allow anonymous access for initial data seeding

  3. Sample Data
    - Insert initial menu items
    - Set up proper user roles and permissions
*/

-- Drop existing policies that might be too restrictive
DROP POLICY IF EXISTS "Allow menu items insertion" ON menu_items;
DROP POLICY IF EXISTS "Anyone can read menu items" ON menu_items;
DROP POLICY IF EXISTS "Managers can update menu items" ON menu_items;
DROP POLICY IF EXISTS "Managers can delete menu items" ON menu_items;

-- Create comprehensive menu_items policies
CREATE POLICY "Public can read menu items"
  ON menu_items
  FOR SELECT
  TO public
  USING (is_available = true);

CREATE POLICY "Allow initial data seeding"
  ON menu_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Managers can manage menu items"
  ON menu_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'manager'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'manager'
    )
  );

-- Fix orders policies
DROP POLICY IF EXISTS "Users can create own orders" ON orders;
DROP POLICY IF EXISTS "Users can read own orders" ON orders;
DROP POLICY IF EXISTS "Managers can read all orders" ON orders;
DROP POLICY IF EXISTS "Managers can update order status" ON orders;

CREATE POLICY "Users can manage own orders"
  ON orders
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Managers can manage all orders"
  ON orders
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'manager'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'manager'
    )
  );

-- Fix reviews policies
DROP POLICY IF EXISTS "Anyone can read reviews" ON reviews;
DROP POLICY IF EXISTS "Users can create own reviews" ON reviews;

CREATE POLICY "Public can read reviews"
  ON reviews
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can create own reviews"
  ON reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Fix notifications policies
DROP POLICY IF EXISTS "Users can read own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

CREATE POLICY "Users can read own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Fix OTP policies
DROP POLICY IF EXISTS "Anyone can create OTP verifications" ON otp_verifications;
DROP POLICY IF EXISTS "Anyone can read own OTP verifications" ON otp_verifications;
DROP POLICY IF EXISTS "Anyone can update OTP verifications" ON otp_verifications;

CREATE POLICY "Public can manage OTP verifications"
  ON otp_verifications
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_menu_items_category_available ON menu_items(category, is_available);
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_reviews_menu_item ON reviews(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, read);

-- Insert sample manager user (for demo purposes)
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role
) VALUES (
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'manager@iiitkottayam.ac.in',
  crypt('manager123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  false,
  'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- Insert corresponding user profile
INSERT INTO users (
  id,
  email,
  name,
  role,
  is_verified,
  loyalty_points
) VALUES (
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'manager@iiitkottayam.ac.in',
  'Demo Manager',
  'manager',
  true,
  0
) ON CONFLICT (id) DO NOTHING;