-- Supabase PostgreSQL Schema for Social Media Multi-Brand SaaS Performance Dashboard
-- Safe Idempotent Script (Can be run multiple times safely)

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Table: brands
create table if not exists public.brands (
    id uuid default uuid_generate_v4() primary key,
    name text not null unique,
    group_type text not null check (group_type in ('group_a', 'group_b')),
    target_feed_monthly integer not null default 30,
    target_story_daily integer default 10,
    target_reels_weekly integer default 4,
    target_reels_monthly integer default 16,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Seed initial 4 brands
insert into public.brands (name, group_type, target_feed_monthly, target_story_daily, target_reels_weekly, target_reels_monthly)
values 
    ('Tosca Care', 'group_a', 30, 10, 4, 16),
    ('Daily Health & Clean', 'group_a', 30, 10, 4, 16),
    ('Doughnut & Donut', 'group_b', 15, 10, 0, 15),
    ('Jakarta Oleh-oleh', 'group_b', 15, 10, 0, 15)
on conflict (name) do update set
    group_type = excluded.group_type,
    target_feed_monthly = excluded.target_feed_monthly,
    target_story_daily = excluded.target_story_daily,
    target_reels_weekly = excluded.target_reels_weekly,
    target_reels_monthly = excluded.target_reels_monthly;

-- 2. Table: daily_reports
create table if not exists public.daily_reports (
    id uuid default uuid_generate_v4() primary key,
    brand_name text not null,
    pic_name text not null,
    report_title text not null,
    month_name text not null,
    platform text not null,
    reels_count integer default 0,
    poster_count integer default 0,
    total_views text,
    chat_response text,
    notes text,
    progress_percentage integer default 0,
    completed_days integer default 0,
    total_days integer default 0,
    raw_wa_text text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Indexing for fast search in Executive Dashboard
create index if not exists idx_daily_reports_brand on public.daily_reports(brand_name);
create index if not exists idx_daily_reports_month on public.daily_reports(month_name);
create index if not exists idx_daily_reports_created on public.daily_reports(created_at desc);

-- 3. Table: report_checklists
create table if not exists public.report_checklists (
    id uuid default uuid_generate_v4() primary key,
    report_id uuid references public.daily_reports(id) on delete cascade,
    day_number integer not null,
    status text not null check (status in ('done', 'process', 'pending')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. View for Executive Dashboard Summary
create or replace view public.v_executive_brand_kpis as
select 
    brand_name,
    count(id) as total_reports_submitted,
    coalesce(sum(poster_count), 0) as total_posters_uploaded,
    coalesce(sum(reels_count), 0) as total_reels_uploaded,
    coalesce(avg(progress_percentage), 0) as avg_quota_completion,
    max(created_at) as last_report_date
from public.daily_reports
group by brand_name;

-- Enable Row Level Security (RLS)
alter table public.brands enable row level security;
alter table public.daily_reports enable row level security;
alter table public.report_checklists enable row level security;

-- Drop existing policies if any (to prevent error 42710)
drop policy if exists "Allow public read access to brands" on public.brands;
drop policy if exists "Allow public read access to daily_reports" on public.daily_reports;
drop policy if exists "Allow public insert access to daily_reports" on public.daily_reports;
drop policy if exists "Allow public read access to report_checklists" on public.report_checklists;
drop policy if exists "Allow public insert access to report_checklists" on public.report_checklists;

-- Create policies for public access
create policy "Allow public read access to brands" on public.brands for select using (true);
create policy "Allow public read access to daily_reports" on public.daily_reports for select using (true);
create policy "Allow public insert access to daily_reports" on public.daily_reports for insert with check (true);
create policy "Allow public read access to report_checklists" on public.report_checklists for select using (true);
create policy "Allow public insert access to report_checklists" on public.report_checklists for insert with check (true);
