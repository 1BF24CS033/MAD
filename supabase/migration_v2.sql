-- ============================================================
-- Benkyo – Migration V2: New Features
-- Run in the Supabase SQL Editor after schema.sql
-- ============================================================

-- 1. Add email to profiles (populated from auth on sign-up)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email text;

-- Update trigger to copy email on new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

-- 2. Enhance help_requests table
-- Add email_shared flag (learner opt-in to share contact)
ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS email_shared boolean NOT NULL DEFAULT false;

-- Add request type (help vs group_study)
ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'help';

-- Add max_participants for group studies
ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS max_participants int NOT NULL DEFAULT 1;

-- Add wants_meet flag (learner opts in to Google Meet)
ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS wants_meet boolean NOT NULL DEFAULT false;

-- Add meet_link (populated when Meet is created)
ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS meet_link text;

-- Update status CHECK to include pending_review
-- Drop old constraint, add new one
ALTER TABLE public.help_requests DROP CONSTRAINT IF EXISTS help_requests_status_check;
ALTER TABLE public.help_requests
  ADD CONSTRAINT help_requests_status_check
  CHECK (status IN ('open','accepted','pending_review','completed','cancelled'));

-- Add type CHECK
ALTER TABLE public.help_requests DROP CONSTRAINT IF EXISTS help_requests_type_check;
ALTER TABLE public.help_requests
  ADD CONSTRAINT help_requests_type_check
  CHECK (type IN ('help', 'group_study'));

-- 3. Reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
  id          uuid        PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id  uuid        NOT NULL REFERENCES public.help_requests(id) ON DELETE CASCADE,
  reviewer_id uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  mentor_id   uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating      int         NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     text        NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE(request_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_mentor ON public.reviews(mentor_id);

-- RLS for reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT USING (true);

CREATE POLICY "Learners can post reviews"
  ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- 4. Group study members junction table
CREATE TABLE IF NOT EXISTS public.group_study_members (
  request_id uuid NOT NULL REFERENCES public.help_requests(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (request_id, user_id)
);

ALTER TABLE public.group_study_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view group study members"
  ON public.group_study_members FOR SELECT USING (true);

CREATE POLICY "Users can join group studies"
  ON public.group_study_members FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave group studies"
  ON public.group_study_members FOR DELETE USING (auth.uid() = user_id);

-- 5. RPC: Calculate average mentor rating from reviews
CREATE OR REPLACE FUNCTION public.update_mentor_rating(p_mentor_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_avg numeric(3,1);
BEGIN
  SELECT COALESCE(AVG(rating), 5.0) INTO v_avg
  FROM public.reviews
  WHERE mentor_id = p_mentor_id;

  UPDATE public.mentors
  SET rating = v_avg
  WHERE profile_id = p_mentor_id;
END;
$$;

-- 6. RPC: Increment group study participant count
CREATE OR REPLACE FUNCTION public.join_group_study(p_request_id uuid, p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current int;
  v_max int;
BEGIN
  -- Check capacity
  SELECT
    (SELECT COUNT(*) FROM public.group_study_members WHERE request_id = p_request_id),
    max_participants
  INTO v_current, v_max
  FROM public.help_requests
  WHERE id = p_request_id;

  IF v_current >= v_max THEN
    RAISE EXCEPTION 'Group study is full';
  END IF;

  -- Insert member
  INSERT INTO public.group_study_members (request_id, user_id)
  VALUES (p_request_id, p_user_id)
  ON CONFLICT DO NOTHING;
END;
$$;
