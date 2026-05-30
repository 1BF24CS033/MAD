-- ============================================================
-- Benkyo – Supabase Database Schema
-- ============================================================
-- Run this entire file in the Supabase SQL Editor to set up
-- all tables, indexes, RLS policies, and seed data.
-- ============================================================

-- Enable UUID extension (already enabled on Supabase by default)
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. PROFILES
-- Extends Supabase auth.users with app-specific data.
-- One row per authenticated user.
-- ============================================================
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  name            text        not null default 'Student',
  college         text        not null default 'BMS College of Engineering',
  semester        int         not null default 1 check (semester between 1 and 8),
  topics_of_interest  text[]  not null default '{}',
  is_mentor       boolean     not null default false,
  mentor_points   int         not null default 0 check (mentor_points >= 0),
  mentor_topics   text[]      not null default '{}',
  avatar_url      text,
  onboarding_complete boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Auto-create a profile row whenever a new user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto-update updated_at on every row change
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 2. MENTORS  (denormalised view of profiles that are mentors)
-- Stores mentor-specific stats that change frequently.
-- ============================================================
create table if not exists public.mentors (
  id              uuid primary key default uuid_generate_v4(),
  profile_id      uuid not null unique references public.profiles(id) on delete cascade,
  rating          numeric(3,1) not null default 5.0 check (rating between 0 and 5),
  total_sessions  int          not null default 0 check (total_sessions >= 0),
  created_at      timestamptz  not null default now(),
  updated_at      timestamptz  not null default now()
);

create trigger mentors_updated_at
  before update on public.mentors
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 3. PEER WORK SESSIONS
-- Records every study session between a mentor and a learner.
-- ============================================================
create table if not exists public.peer_work_sessions (
  id               uuid        primary key default uuid_generate_v4(),
  topic            text        not null,
  mentor_id        uuid        not null references public.profiles(id) on delete cascade,
  learner_id       uuid        not null references public.profiles(id) on delete cascade,
  date             timestamptz not null default now(),
  duration_minutes int         not null default 30 check (duration_minutes > 0),
  points_awarded   int         not null default 10 check (points_awarded >= 0),
  completed        boolean     not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint no_self_session check (mentor_id <> learner_id)
);

create index if not exists idx_sessions_mentor  on public.peer_work_sessions(mentor_id);
create index if not exists idx_sessions_learner on public.peer_work_sessions(learner_id);
create index if not exists idx_sessions_date    on public.peer_work_sessions(date desc);

create trigger sessions_updated_at
  before update on public.peer_work_sessions
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 4. STUDY HISTORY
-- Tracks topics a user has studied (ordered by recency).
-- ============================================================
create table if not exists public.study_history (
  id         uuid        primary key default uuid_generate_v4(),
  user_id    uuid        not null references public.profiles(id) on delete cascade,
  topic      text        not null,
  studied_at timestamptz not null default now()
);

create index if not exists idx_study_history_user on public.study_history(user_id, studied_at desc);

-- ============================================================
-- 5. PROJECTS
-- Collaborative projects posted by students.
-- ============================================================
create table if not exists public.projects (
  id               uuid        primary key default uuid_generate_v4(),
  title            text        not null,
  description      text        not null,
  posted_by        uuid        not null references public.profiles(id) on delete cascade,
  skills_required  text[]      not null default '{}',
  team_size        int         not null default 4 check (team_size between 2 and 20),
  current_members  int         not null default 1 check (current_members >= 1),
  posted_date      timestamptz not null default now(),
  is_open          boolean     not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint members_lte_team check (current_members <= team_size)
);

create index if not exists idx_projects_posted_by on public.projects(posted_by);
create index if not exists idx_projects_date      on public.projects(posted_date desc);
create index if not exists idx_projects_skills    on public.projects using gin(skills_required);

create trigger projects_updated_at
  before update on public.projects
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 6. PROJECT MEMBERS
-- Junction table: which users have joined which projects.
-- ============================================================
create table if not exists public.project_members (
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (project_id, user_id)
);

-- ============================================================
-- 7. REWARDS
-- Catalogue of rewards available in the store.
-- ============================================================
create table if not exists public.rewards (
  id          uuid    primary key default uuid_generate_v4(),
  title       text    not null,
  description text    not null,
  points_cost int     not null check (points_cost > 0),
  icon_name   text    not null default 'card_giftcard',
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- 8. REWARD REDEMPTIONS
-- Tracks which users have redeemed which rewards.
-- ============================================================
create table if not exists public.reward_redemptions (
  id          uuid        primary key default uuid_generate_v4(),
  user_id     uuid        not null references public.profiles(id) on delete cascade,
  reward_id   uuid        not null references public.rewards(id) on delete cascade,
  redeemed_at timestamptz not null default now()
);

create index if not exists idx_redemptions_user on public.reward_redemptions(user_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

alter table public.profiles           enable row level security;
alter table public.mentors            enable row level security;
alter table public.peer_work_sessions enable row level security;
alter table public.study_history      enable row level security;
alter table public.projects           enable row level security;
alter table public.project_members    enable row level security;
alter table public.rewards            enable row level security;
alter table public.reward_redemptions enable row level security;

-- PROFILES
create policy "Users can view all profiles"
  on public.profiles for select using (true);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- MENTORS
create policy "Anyone can view mentors"
  on public.mentors for select using (true);

create policy "Mentor can manage own record"
  on public.mentors for all using (
    profile_id = auth.uid()
  );

-- PEER WORK SESSIONS
create policy "Users can view their own sessions"
  on public.peer_work_sessions for select using (
    mentor_id = auth.uid() or learner_id = auth.uid()
  );

create policy "Users can insert sessions they are part of"
  on public.peer_work_sessions for insert with check (
    mentor_id = auth.uid() or learner_id = auth.uid()
  );

create policy "Participants can update their sessions"
  on public.peer_work_sessions for update using (
    mentor_id = auth.uid() or learner_id = auth.uid()
  );

-- STUDY HISTORY
create policy "Users can view own study history"
  on public.study_history for select using (user_id = auth.uid());

create policy "Users can insert own study history"
  on public.study_history for insert with check (user_id = auth.uid());

-- PROJECTS
create policy "Anyone can view open projects"
  on public.projects for select using (true);

create policy "Authenticated users can post projects"
  on public.projects for insert with check (auth.uid() = posted_by);

create policy "Project owner can update their project"
  on public.projects for update using (auth.uid() = posted_by);

-- PROJECT MEMBERS
create policy "Anyone can view project members"
  on public.project_members for select using (true);

create policy "Authenticated users can join projects"
  on public.project_members for insert with check (auth.uid() = user_id);

-- REWARDS
create policy "Anyone can view active rewards"
  on public.rewards for select using (is_active = true);

-- REWARD REDEMPTIONS
create policy "Users can view own redemptions"
  on public.reward_redemptions for select using (user_id = auth.uid());

create policy "Users can redeem rewards"
  on public.reward_redemptions for insert with check (auth.uid() = user_id);

-- ============================================================
-- SEED DATA – Rewards catalogue
-- (Safe to re-run; uses ON CONFLICT DO NOTHING)
-- ============================================================
insert into public.rewards (id, title, description, points_cost, icon_name) values
  ('00000000-0000-0000-0000-000000000001', 'Premium Notes Access',
   'Get access to premium study notes for any one subject.', 50, 'menu_book'),
  ('00000000-0000-0000-0000-000000000002', 'Mock Test Pack',
   'A set of 5 mock tests for your upcoming exams.', 100, 'quiz'),
  ('00000000-0000-0000-0000-000000000003', 'Certificate Badge',
   'A verified mentor badge for your profile.', 200, 'verified'),
  ('00000000-0000-0000-0000-000000000004', 'Study Group Pass',
   'Priority access to premium study groups.', 75, 'groups')
on conflict (id) do nothing;

-- Add status to peer_work_sessions
ALTER TABLE public.peer_work_sessions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'completed', 'declined'));


-- 1. Safely increment mentor_points (avoids race conditions)
create or replace function public.increment_mentor_points(
  user_id uuid,
  delta   int
)
returns void language plpgsql security definer as $$
begin
  update public.profiles
  set mentor_points = mentor_points + delta
  where id = user_id;
end;
$$;

-- 2. Safely increment current_members on a project
create or replace function public.increment_project_members(
  project_id uuid
)
returns void language plpgsql security definer as $$
begin
  update public.projects
  set current_members = current_members + 1
  where id = project_id
    and current_members < team_size;

  if not found then
    raise exception 'Project is full or does not exist';
  end if;
end;
$$;

-- 3. Atomically redeem a reward (deduct points + record redemption)
create or replace function public.redeem_reward(
  p_user_id    uuid,
  p_reward_id  uuid,
  p_points_cost int
)
returns void language plpgsql security definer as $$
declare
  v_current_points int;
begin
  -- Lock the profile row
  select mentor_points into v_current_points
  from public.profiles
  where id = p_user_id
  for update;

  if v_current_points < p_points_cost then
    raise exception 'Insufficient MentorPoints';
  end if;

  -- Deduct points
  update public.profiles
  set mentor_points = mentor_points - p_points_cost
  where id = p_user_id;

  -- Record redemption
  insert into public.reward_redemptions (user_id, reward_id)
  values (p_user_id, p_reward_id);
end;
$$;

-- ============================================================
-- 9. HELP REQUESTS
-- Learners post doubts; mentors browse and accept them.
-- ============================================================
create table if not exists public.help_requests (
  id               uuid        primary key default uuid_generate_v4(),
  learner_id       uuid        not null references public.profiles(id) on delete cascade,
  mentor_id        uuid        references public.profiles(id) on delete set null,
  topic            text        not null,
  description      text        not null default '',
  duration_minutes int         not null default 30 check (duration_minutes > 0),
  status           text        not null default 'open'
                               check (status in ('open','accepted','completed','cancelled')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists idx_help_requests_learner on public.help_requests(learner_id);
create index if not exists idx_help_requests_status  on public.help_requests(status);

create trigger help_requests_updated_at
  before update on public.help_requests
  for each row execute procedure public.set_updated_at();

-- RLS
alter table public.help_requests enable row level security;

create policy "Anyone can view open help requests"
  on public.help_requests for select using (true);

create policy "Learners can post help requests"
  on public.help_requests for insert with check (auth.uid() = learner_id);

create policy "Participants can update their requests"
  on public.help_requests for update using (
    auth.uid() = learner_id or auth.uid() = mentor_id
  );

-- ============================================================
-- 10. REMINDERS
-- Users set reminders tied to a help request or a custom note.
-- ============================================================
create table if not exists public.reminders (
  id           uuid        primary key default uuid_generate_v4(),
  user_id      uuid        not null references public.profiles(id) on delete cascade,
  request_id   uuid        references public.help_requests(id) on delete cascade,
  title        text        not null,
  body         text        not null default '',
  remind_at    timestamptz not null,
  is_sent      boolean     not null default false,
  created_at   timestamptz not null default now()
);

create index if not exists idx_reminders_user    on public.reminders(user_id, remind_at);
create index if not exists idx_reminders_pending on public.reminders(remind_at) where is_sent = false;

alter table public.reminders enable row level security;

create policy "Users can manage own reminders"
  on public.reminders for all using (auth.uid() = user_id);

-- ============================================================
-- 11. MESSAGES (in-app chat per help request)
-- ============================================================
create table if not exists public.messages (
  id           uuid        primary key default uuid_generate_v4(),
  request_id   uuid        not null references public.help_requests(id) on delete cascade,
  sender_id    uuid        not null references public.profiles(id) on delete cascade,
  content      text        not null,
  created_at   timestamptz not null default now()
);
create index if not exists idx_messages_request on public.messages(request_id, created_at);
alter table public.messages enable row level security;
create policy "Participants can read messages"
  on public.messages for select using (
    exists (
      select 1 from public.help_requests hr
      where hr.id = request_id
      and (hr.learner_id = auth.uid() or hr.mentor_id = auth.uid())
    )
  );
create policy "Participants can send messages"
  on public.messages for insert with check (
    auth.uid() = sender_id and
    exists (
      select 1 from public.help_requests hr
      where hr.id = request_id
      and (hr.learner_id = auth.uid() or hr.mentor_id = auth.uid())
    )
  );
