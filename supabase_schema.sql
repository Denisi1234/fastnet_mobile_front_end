-- ====================================================================
-- FASTNET STAYS - SUPABASE DATABASE SCHEMA MIGRATION SCRIPT
-- Project: https://potpocgevsyoxxopwtaq.supabase.co
-- ====================================================================

-- 1. Create Bookings Table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_code TEXT NOT NULL UNIQUE,
    lodge_name TEXT NOT NULL,
    room_number TEXT NOT NULL,
    guest_name TEXT NOT NULL,
    guest_phone TEXT,
    guest_email TEXT,
    dates TEXT NOT NULL,
    nights INT NOT NULL DEFAULT 1,
    total_price BIGINT NOT NULL,
    payment_method TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Confirmed',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Index for fast lookups by booking code & phone
CREATE INDEX IF NOT EXISTS idx_bookings_code ON public.bookings(booking_code);
CREATE INDEX IF NOT EXISTS idx_bookings_phone ON public.bookings(guest_phone);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS Policies for Anon access
CREATE POLICY "Allow public insert to bookings" 
ON public.bookings FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Allow public read to bookings" 
ON public.bookings FOR SELECT 
USING (true);

-- 5. Create Storage Bucket for E-Receipt PDFs
INSERT INTO storage.buckets (id, name, public) 
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

-- 6. Storage Policies for PDF Uploads
CREATE POLICY "Allow public upload to receipts bucket" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'receipts');

CREATE POLICY "Allow public read from receipts bucket" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'receipts');
