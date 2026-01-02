-- Staff Table

-- Create the staff table
CREATE TABLE IF NOT EXISTS staff (
    staff_id TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    role TEXT,
    email TEXT,
    phone_number TEXT,
    address TEXT,
    profile_image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO "public"."staff" ("staff_id", "password", "first_name", "last_name", "role", "email", "phone_number", "address", "profile_image", "created_at", "updated_at") VALUES ('2501', '492fd042a429a2924875f6744e20563f6ce107e7da82c1095f4e3a5447ce2a1d', 'Alice', 'Tan', 'Operational Support', 'azlan.rahman@example.com', '012-345 6789', 'No. 12, Jalan Ampang, 50450 Kuala Lumpur, Wilayah Persekutuan', null, '2025-09-11 08:42:22.559252+00', '2025-09-11 08:42:22.559252+00'), ('2502', 'e42af7e87ee8d028993bcfa46b85d20b3f37ee521e041ce7db083fa467dc2162', 'Ben', 'Lim', 'Vehicle Maintenance & Repair', 'siti.noraini@example.com', '016-789 1234', '45, Taman Melawati, 53100 Kuala Lumpur, Selangor', null, '2025-09-11 08:42:22.559252+00', '2025-09-11 08:42:22.559252+00'), ('2503', 'db8a4fa02cc41279f522c810707af3ec1ea1caa741e16d75eb9b329797119725', 'Cheryl', 'Ng', 'Inspection & Safety', 'rajesh.kumar@example.com', '017-222 3344', '88, Jalan Tun Razak, 50400 Kuala Lumpur, Wilayah Persekutuan', null, '2025-09-11 08:42:22.559252+00', '2025-09-11 08:42:22.559252+00'), ('2504', '6d91b84c273452dc3d92fd880232a527c59568fd3852c588a15d2af67ab8efec', 'David', 'Lee', 'Workshop & Equipment Handling', 'lim.mei.yen@example.com', '019-555 6677', '27, Jalan Bukit Bintang, 55100 Kuala Lumpur, Wilayah Persekutuan\r\n\r\n5.', null, '2025-09-11 08:42:22.559252+00', '2025-09-11 08:42:22.559252+00'), ('2505', '6879922a77248297623c2f4f6b597e77d4be05f22e6fe601a9752ba1fd87f78f', 'Evelyn', 'Wong', 'Customer & Team Support', 'farid.hakim@example.com', '013-444 8899', '102, Jalan Gurney, 54000 Kuala Lumpur, Wilayah Persekutuan', null, '2025-09-11 08:42:22.559252+00', '2025-09-11 08:42:22.559252+00');


CREATE INDEX IF NOT EXISTS idx_staff_staff_id ON staff(staff_id);

-- Customer Table
CREATE TABLE IF NOT EXISTS customer (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    vehicle_make TEXT,
    vehicle_model TEXT,
    vehicle_registration TEXT,
    equipment_type TEXT,
    equipment_serial TEXT
);

-- Demo customer data (integer auto-increment IDs)
INSERT INTO "public"."customer" ("name", "phone", "email", "vehicle_make", "vehicle_model", "vehicle_registration", "equipment_type", "equipment_serial") VALUES
('Mei Ling', '+65 8123 9876', 'mei.ling@email.com', 'Toyota', 'Corolla Altis', 'SGX1234A', NULL, NULL),
('Alex Lim', '+65 8234 5678', 'alex.lim@email.com', NULL, NULL, NULL, 'Forklift', 'EQ-998877'),
('John Tan', '+65 9123 4567', 'john.tan@email.com', 'Honda', 'Civic', 'SGY5678B', NULL, NULL),
('Sarah Goh', '+65 8111 2233', 'sarah.goh@email.com', 'Mazda', 'CX-5', 'SGZ4321C', NULL, NULL),
('Mohd Rizal', '+65 8222 3344', 'rizal.mohd@email.com', NULL, NULL, NULL, 'Excavator', 'EQ-112233'),
('Priya Singh', '+65 8333 4455', 'priya.singh@email.com', 'Hyundai', 'Elantra', 'SGA8765D', NULL, NULL),
('James Lee', '+65 8444 5566', 'james.lee@email.com', NULL, NULL, NULL, 'Generator', 'EQ-445566'),
('Wei Chen', '+65 8555 6677', 'wei.chen@email.com', 'Nissan', 'Teana', 'SGD2345E', NULL, NULL),
('Nurul Aini', '+65 8666 7788', 'nurul.aini@email.com', NULL, NULL, NULL, 'Compressor', 'EQ-778899'),
('David Ong', '+65 8777 8899', 'david.ong@email.com', 'Subaru', 'Forester', 'SGF6789F', NULL, NULL),
('Lina Tan', '+65 8888 9900', 'lina.tan@email.com', NULL, NULL, NULL, 'Welding Machine', 'EQ-990011'),
('Kelvin Chua', '+65 8999 0011', 'kelvin.chua@email.com', 'Volkswagen', 'Golf', 'SGH3456G', NULL, NULL);


-- Task Table (added customer_id to link to customer table)
-- Status field is synchronized with Dart TaskStatus enum values
CREATE TABLE IF NOT EXISTS task (
    task_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    order_id TEXT,
    customer_id INTEGER REFERENCES customer(customer_id) ON DELETE SET NULL,
    description TEXT,
    status TEXT CHECK (status IN ('assigned', 'accepted', 'completed')),
    deadline TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    staff_id TEXT NOT NULL REFERENCES staff(staff_id) ON DELETE SET NULL,
    repair_image_path TEXT[],
    upload_image_path TEXT[],
    signature_path TEXT
);

-- Demo task data (now includes customer_id for each mock row)
-- Updated mock data for 'task' table:
-- All statuses now use only "assigned", "accepted", or "completed".

-- The full image URL should be constructed as:
-- storage_endpoint + image_path
-- where storage_endpoint is 'https://wulwkmigfhltbjklnyef.storage.supabase.co/storage/v1/s3'
-- Task INSERT statement now includes customer_id to link tasks to customers
-- Customer IDs are distributed across tasks to demonstrate the relationship
-- Insert demo data into the task table without specifying task_id (auto-increment)
INSERT INTO "public"."task" ("title", "order_id", "customer_id", "description", "status", "deadline", "created_at", "staff_id", "repair_image_path", "upload_image_path", "signature_path") VALUES
('Repair headlight', 'ORD-1013', '1', 'Fix malfunctioning left headlight', 'assigned', '2025-10-17 10:00:00+00', '2025-09-11 08:42:22.559252+00', '2503', '{"repair_parts/part13.jpg"}', '{}', null),
('Check steering alignment', 'ORD-1025', '2', 'Perform steering wheel alignment check', 'assigned', '2025-10-29 01:00:00+00', '2025-09-11 08:42:22.559252+00', '2505', '{"repair_parts/part25.jpg"}', '{}', null),
('Replace radiator', 'ORD-1024', '3', 'Install new radiator for cooling system', 'assigned', '2025-10-28 05:00:00+00', '2025-09-11 08:42:22.559252+00', '2505', '{"Repairs/1_replace_rediator.jpg","Repairs/2_replace_rediator.jpg"}', '{}', null),
('Check transmission fluid', 'ORD-1020', '1', 'Inspect and refill transmission fluid', 'assigned', '2025-10-24 02:00:00+00', '2025-09-11 08:42:22.559252+00', '2504', '{"repair_parts/part20.jpg"}', '{}', null),
('Rotate tires', 'ORD-1008', '2', 'Rotate all four tires for even wear', 'assigned', '2025-10-12 03:00:00+00', '2025-09-11 08:42:22.559252+00', '2502', '{"repair_parts/part8.jpg"}', '{}', null),
('Install air filter', 'ORD-1006', '3', 'Install new air filter for routine maintenance', 'assigned', '2025-10-10 04:00:00+00', '2025-09-11 08:42:22.559252+00', '2502', '{"repair_parts/part6.jpg"}', '{}', null),
('Inspect tire wear', 'ORD-1002', '1', 'Check tire tread depth and wear patterns', 'assigned', '2025-10-06 01:00:00+00', '2025-09-11 08:42:22.559252+00', '2501', '{"repair_parts/part2.jpg"}', '{}', null),
('Replace rear lights', 'ORD-1019', '2', 'Install new rear light assemblies', 'assigned', '2025-10-23 09:00:00+00', '2025-09-11 08:42:22.559252+00', '2504', '{"repair_parts/part19.jpg"}', '{}', null),
('Inspect suspension', 'ORD-1016', '3', 'Check suspension system for wear and damage', 'assigned', '2025-10-20 08:00:00+00', '2025-09-11 08:42:22.559252+00', '2504', '{"repair_parts/part16.jpg"}', '{}', null),
('Repair window motor', 'ORD-1022', '1', 'Fix faulty window motor on driver side', 'assigned', '2025-10-26 04:00:00+00', '2025-09-11 08:42:22.559252+00', '2505', '{"repair_parts/part22.jpg"}', '{}', null),
('Clean fuel injectors', 'ORD-1004', '2', 'Perform cleaning of all fuel injectors', 'assigned', '2025-10-08 02:00:00+00', '2025-09-11 08:42:22.559252+00', '2501', '{"Repairs/1_fuel_injector.jpg"}', '{}', null),
('Replace timing belt', 'ORD-1015', '3', 'Install new timing belt as per schedule', 'assigned', '2025-10-19 03:00:00+00', '2025-09-11 08:42:22.559252+00', '2503', '{"repair_parts/part15.jpg"}', '{}', null),
('Test air conditioning', 'ORD-1018', '1', 'Diagnose and test air conditioning system', 'assigned', '2025-10-22 07:00:00+00', '2025-09-11 08:42:22.559252+00', '2504', '{"repair_parts/part18.jpg"}', '{}', null),
('Replace spark plugs', 'ORD-1009', '2', 'Install new spark plugs for improved performance', 'assigned', '2025-10-13 05:00:00+00', '2025-09-11 08:42:22.559252+00', '2502', '{"repair_parts/part9.jpg"}', '{}', null),
('Check brake fluid', 'ORD-1014', '3', 'Inspect and top up brake fluid', 'assigned', '2025-10-18 01:00:00+00', '2025-09-11 08:42:22.559252+00', '2503', '{"repair_parts/part14.jpg"}', '{}', null),
('Replace alternator', 'ORD-1017', '1', 'Install new alternator for charging system', 'assigned', '2025-10-21 05:00:00+00', '2025-09-11 08:42:22.559252+00', '2504', '{"repair_parts/part17.jpg"}', '{}', null),
('Diagnose engine noise', 'ORD-1011', '2', 'Investigate and diagnose unusual engine noise', 'accepted', '2025-10-15 01:00:00+00', '2025-09-11 08:42:22.559252+00', '2503', '{"repair_parts/part11.jpg"}', '{}', null),
('Replace brake pads', 'ORD-1001', '3', 'Replace front brake pads for customer vehicle', 'assigned', '2025-10-05 09:00:00+00', '2025-09-11 08:42:22.559252+00', '2501', '{"repair_parts/part1.jpg"}', '{}', null),
('Change engine oil', 'ORD-1007', '1', 'Replace engine oil and oil filter', 'assigned', '2025-10-11 07:00:00+00', '2025-09-11 08:42:22.559252+00', '2502', '{"repair_parts/part7.jpg"}', '{}', null),
('Replace exhaust pipe', 'ORD-1021', '2', 'Install new exhaust pipe for reduced emissions', 'assigned', '2025-10-25 06:00:00+00', '2025-09-11 08:42:22.559252+00', '2505', '{"repair_parts/part21.jpg"}', '{}', null),
('Replace fuse box', 'ORD-1026', '3', 'Install new fuse box for electrical system', 'assigned', '2025-10-30 03:00:00+00', '2025-09-11 08:42:22.559252+00', '2505', '{"repair_parts/part26.jpg"}', '{}', null),
('Replace cabin filter', 'ORD-1012', '1', 'Install new cabin air filter', 'assigned', '2025-10-16 02:00:00+00', '2025-09-11 08:42:22.559252+00', '2503', '{"repair_parts/part12.jpg"}', '{}', null),
('Replace wiper blades', 'ORD-1005', '2', 'Install new front and rear wiper blades', 'assigned', '2025-10-09 00:00:00+00', '2025-09-11 08:42:22.559252+00', '2501', '{"repair_parts/part5.jpg"}', '{}', null),
('Flush coolant system', 'ORD-1010', '3', 'Flush and refill coolant system', 'assigned', '2025-10-14 08:00:00+00', '2025-09-11 08:42:22.559252+00', '2502', '{"repair_parts/part10.jpg"}', '{}', null),
('Install new horn', 'ORD-1023', '1', 'Replace broken horn with new unit', 'assigned', '2025-10-27 08:00:00+00', '2025-09-11 08:42:22.559252+00', '2505', '{"repair_parts/part23.jpg"}', '{}', null),
('Test battery health', 'ORD-1003', '2', 'Run battery diagnostics for voltage and capacity', 'assigned', '2025-10-07 06:00:00+00', '2025-09-11 08:42:22.559252+00', '2501', '{"repair_parts/part3.jpg"}', '{}', null);


CREATE INDEX IF NOT EXISTS idx_task_staff_id ON task(staff_id);

-- Notifications Table
CREATE TABLE public.notifications (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id text NOT NULL,
  task_id integer NULL,
  title text NOT NULL,
  subtitle text NULL,
  description text NULL,
  icon_type text NULL DEFAULT 'notifications'::text,
  icon_color text NULL DEFAULT 'blue'::text,
  is_read boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  CONSTRAINT notifications_staff_id_fkey FOREIGN KEY (staff_id)
      REFERENCES staff (staff_id) ON DELETE CASCADE,
  CONSTRAINT notifications_task_id_fkey FOREIGN KEY (task_id)
      REFERENCES task (task_id) ON DELETE CASCADE,
  -- 🚨 Unique constraint to prevent duplicates
  CONSTRAINT notifications_unique UNIQUE (staff_id, task_id, title)
);

CREATE INDEX IF NOT EXISTS idx_notifications_staff_id ON notifications(staff_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Task Time Log Table
CREATE TABLE IF NOT EXISTS task_time_logs (
    log_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES task(task_id) ON DELETE CASCADE,
    staff_id TEXT NOT NULL REFERENCES staff(staff_id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('start', 'pause', 'resume', 'complete')),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTERVAL
);

-- Vehicle Parts Table
create table public.vehicle_parts (
  part_id uuid not null default gen_random_uuid (),
  barcode text not null,
  part_name text not null,
  part_number text null,
  description text null,
  category text null,
  stock_quantity integer null default 0,
  unit_price numeric(10, 2) null,
  supplier text null,
  location text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint vehicle_parts_pkey primary key (part_id),
  constraint vehicle_parts_barcode_key unique (barcode)
) TABLESPACE pg_default;

create index IF not exists idx_vehicle_parts_barcode on public.vehicle_parts using btree (barcode) TABLESPACE pg_default;

create index IF not exists idx_vehicle_parts_category on public.vehicle_parts using btree (category) TABLESPACE pg_default;

INSERT INTO "public"."vehicle_parts" ("part_id", "barcode", "part_name", "part_number", "description", "category", "stock_quantity", "unit_price", "supplier", "location", "created_at", "updated_at") VALUES
('005d53e7-ee0e-4f4a-a58d-0071b44f57e9', 'BP002-REAR', 'Rear Brake Pads', 'BP-002', 'Premium brake pads for rear wheels', 'Brakes', '20', '74.99', 'AutoParts Plus', 'Shelf A1', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 'WB-001', '24" front windshield wiper blades - pair', 'Wipers', '22', '28.99', 'ClearView', 'Shelf D4', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('2a99ea43-30f8-4bb9-a73f-91420a1bc927', 'TF001-ATF', 'Transmission Fluid', 'TF-001', 'Automatic transmission fluid - 4 liters', 'Fluids', '12', '38.99', 'FluidPro', 'Storage Room', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 'BF-001', '1 liter DOT4 brake fluid', 'Fluids', '25', '12.99', 'BrakeMax', 'Storage Room', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 'SP-001', 'Set of 4 NGK iridium spark plugs', 'Ignition', '40', '32.99', 'NGK Parts', 'Shelf C3', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('6065a188-7b4b-403a-9fbf-fa3f11b62d32', 'TB001-HONDA', 'Timing Belt', 'TB-001', 'Timing belt for Honda engines', 'Belts', '8', '125.99', 'Honda OEM', 'Shelf E5', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 'CF-001', 'HEPA cabin air filter', 'Filters', '18', '19.99', 'FilterMax', 'Shelf B2', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 'AF-001', 'Standard air filter for engine intake', 'Filters', '30', '24.99', 'FilterMax', 'Shelf B2', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 'OF-001', '5 liter synthetic engine oil 5W-30', 'Oils', '15', '45.99', 'LubeTech', 'Storage Room', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00'),
('ba017fb7-f58a-4ca0-b33c-93063b1265d3', 'BP001-FRONT', 'Front Brake Pads', 'BP-001', 'High-performance ceramic brake pads for front wheels', 'Brakes', '25', '89.99', 'AutoParts Plus', 'Shelf A1', '2025-09-13 11:52:02.30385+00', '2025-09-13 11:52:02.30385+00');


-- Task Parts Requirements Table
CREATE TABLE public.task_parts_requirements (
  requirement_id uuid not null default gen_random_uuid (),
  task_id integer not null,
  part_id uuid not null,
  barcode text not null,
  part_name text not null,
  required_quantity integer not null default 1,
  verified_quantity integer null default 0,
  is_verified boolean null default false,
  verified_date timestamp with time zone null,
  notes text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint task_parts_requirements_pkey primary key (requirement_id),
  constraint task_parts_requirements_task_id_fkey foreign key (task_id) 
    references task (task_id) on delete cascade,
  constraint task_parts_requirements_part_id_fkey foreign key (part_id) 
    references vehicle_parts (part_id) on delete cascade,
  constraint task_parts_requirements_required_quantity_check check ((required_quantity > 0)),
  constraint task_parts_requirements_verified_quantity_check check ((verified_quantity >= 0))
) tablespace pg_default;

-- Indexes for performance
create index if not exists idx_task_parts_requirements_task_id 
  on public.task_parts_requirements using btree (task_id) tablespace pg_default;

create index if not exists idx_task_parts_requirements_part_id 
  on public.task_parts_requirements using btree (part_id) tablespace pg_default;

create index if not exists idx_task_parts_requirements_barcode 
  on public.task_parts_requirements using btree (barcode) tablespace pg_default;

create index if not exists idx_task_parts_requirements_is_verified 
  on public.task_parts_requirements using btree (is_verified) tablespace pg_default;

-- Demo data for task parts requirements
-- These link existing tasks with required parts
INSERT INTO "public"."task_parts_requirements" 
("requirement_id", "task_id", "part_id", "barcode", "part_name", "required_quantity", "verified_quantity", "is_verified", "verified_date", "notes", "created_at", "updated_at") 
VALUES
-- Task 1 (Repair headlight) - already completed, should show as verified
(gen_random_uuid(), 1, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 1, true, '2025-09-11 09:00:00+00', 'Required for headlight repair job', '2025-09-11 08:45:00+00', '2025-09-11 09:00:00+00'),

-- Task 18 (Replace brake pads) - accepted status, should show as required
(gen_random_uuid(), 18, 'ba017fb7-f58a-4ca0-b33c-93063b1265d3', 'BP001-FRONT', 'Front Brake Pads', 1, 0, false, null, 'Front brake pads required for replacement', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 18, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 0, false, null, 'Brake fluid needed for brake system', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 19 (Change engine oil) - accepted status
(gen_random_uuid(), 19, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 1, 0, false, null, '5W-30 oil for engine oil change', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 5 (Rotate tires) - accepted status
(gen_random_uuid(), 5, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 1, 0, false, null, 'Wiper blades may need replacement during tire rotation', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 13 (Test air conditioning) - accepted status  
(gen_random_uuid(), 13, '89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 1, 0, false, null, 'Cabin filter required for AC system check', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 17 (Diagnose engine noise) - accepted status
(gen_random_uuid(), 17, '51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 4, 0, false, null, 'Spark plugs may be needed for engine diagnosis', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 25 (Install new horn) - accepted status
(gen_random_uuid(), 25, '2a99ea43-30f8-4bb9-a73f-91420a1bc927', 'TF001-ATF', 'Transmission Fluid', 1, 0, false, null, 'May need transmission service during horn installation', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 26 (Test battery health) - accepted status
(gen_random_uuid(), 26, '6065a188-7b4b-403a-9fbf-fa3f11b62d32', 'TB001-HONDA', 'Timing Belt', 1, 0, false, null, 'Timing belt inspection during battery test', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Additional assigned tasks with requirements for more testing scenarios
-- Task 3 (Replace radiator) - assigned status
(gen_random_uuid(), 3, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 2, 0, false, null, 'Oil change needed during radiator replacement', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 3, '89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 1, 0, false, null, 'Filter replacement during radiator work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 8 (Replace rear lights) - assigned status  
(gen_random_uuid(), 8, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 2, 0, false, null, 'Replace wiper blades with rear light job', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 9 (Inspect suspension) - assigned status
(gen_random_uuid(), 9, '005d53e7-ee0e-4f4a-a58d-0071b44f57e9', 'BP002-REAR', 'Rear Brake Pads', 1, 0, false, null, 'Brake pads inspection during suspension check', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 11 (Clean fuel injectors) - assigned status
(gen_random_uuid(), 11, '51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 4, 0, false, null, 'Spark plugs replacement with fuel injector cleaning', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 11, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 0, false, null, 'Air filter replacement during fuel system service', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 14 (Replace spark plugs) - assigned status
(gen_random_uuid(), 14, '51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 4, 0, false, null, 'Primary spark plugs for replacement', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 15 (Check brake fluid) - assigned status
(gen_random_uuid(), 15, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 0, false, null, 'DOT4 brake fluid for top-up', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 20 (Replace exhaust pipe) - assigned status
(gen_random_uuid(), 20, '2a99ea43-30f8-4bb9-a73f-91420a1bc927', 'TF001-ATF', 'Transmission Fluid', 1, 0, false, null, 'Transmission service during exhaust work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 21 (Replace fuse box) - assigned status
(gen_random_uuid(), 21, '6065a188-7b4b-403a-9fbf-fa3f11b62d32', 'TB001-HONDA', 'Timing Belt', 1, 0, false, null, 'Timing belt inspection during electrical work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 22 (Replace cabin filter) - assigned status
(gen_random_uuid(), 22, '89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 1, 0, false, null, 'Primary cabin filter for replacement', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Additional comprehensive task requirements for better testing scenarios

-- Task 2 (Check steering alignment) - completed status, add more requirements
(gen_random_uuid(), 2, 'ba017fb7-f58a-4ca0-b33c-93063b1265d3', 'BP001-FRONT', 'Front Brake Pads', 2, 2, true, '2025-09-12 08:30:00+00', 'Brake pads checked during alignment - already verified', '2025-09-11 08:45:00+00', '2025-09-12 08:30:00+00'),
(gen_random_uuid(), 2, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 1, true, '2025-09-12 08:45:00+00', 'Brake fluid topped up - verified', '2025-09-11 08:45:00+00', '2025-09-12 08:45:00+00'),

-- Task 4 (Check transmission fluid) - completed status, add requirements
(gen_random_uuid(), 4, '2a99ea43-30f8-4bb9-a73f-91420a1bc927', 'TF001-ATF', 'Transmission Fluid', 2, 2, true, '2025-09-12 10:15:00+00', 'Transmission fluid refilled - verified', '2025-09-11 08:45:00+00', '2025-09-12 10:15:00+00'),
(gen_random_uuid(), 4, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 1, true, '2025-09-12 10:30:00+00', 'Air filter checked during service - verified', '2025-09-11 08:45:00+00', '2025-09-12 10:30:00+00'),

-- Task 6 (Install air filter) - completed status
(gen_random_uuid(), 6, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 1, true, '2025-09-12 11:00:00+00', 'Primary air filter installed - verified', '2025-09-11 08:45:00+00', '2025-09-12 11:00:00+00'),
(gen_random_uuid(), 6, '89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 1, 1, true, '2025-09-12 11:15:00+00', 'Cabin filter also replaced - verified', '2025-09-11 08:45:00+00', '2025-09-12 11:15:00+00'),

-- Task 7 (Inspect tire wear) - completed status, multiple requirements
(gen_random_uuid(), 7, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 1, 1, true, '2025-09-13 09:00:00+00', 'Wiper blades replaced during inspection - verified', '2025-09-11 08:45:00+00', '2025-09-13 09:00:00+00'),
(gen_random_uuid(), 7, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 1, true, '2025-09-13 09:15:00+00', 'Brake fluid checked during tire inspection - verified', '2025-09-11 08:45:00+00', '2025-09-13 09:15:00+00'),

-- Task 10 (Repair window motor) - completed status
(gen_random_uuid(), 10, '6065a188-7b4b-403a-9fbf-fa3f11b62d32', 'TB001-HONDA', 'Timing Belt', 1, 1, true, '2025-09-13 14:00:00+00', 'Timing belt inspected during window repair - verified', '2025-09-11 08:45:00+00', '2025-09-13 14:00:00+00'),

-- Task 12 (Replace timing belt) - completed status
(gen_random_uuid(), 12, '6065a188-7b4b-403a-9fbf-fa3f11b62d32', 'TB001-HONDA', 'Timing Belt', 1, 1, true, '2025-09-14 10:00:00+00', 'Primary timing belt replaced - verified', '2025-09-11 08:45:00+00', '2025-09-14 10:00:00+00'),
(gen_random_uuid(), 12, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 2, 2, true, '2025-09-14 10:30:00+00', 'Oil changed with timing belt - verified', '2025-09-11 08:45:00+00', '2025-09-14 10:30:00+00'),
(gen_random_uuid(), 12, '51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 4, 4, true, '2025-09-14 11:00:00+00', 'Spark plugs replaced during timing belt job - verified', '2025-09-11 08:45:00+00', '2025-09-14 11:00:00+00'),

-- Task 16 (Replace alternator) - completed status
(gen_random_uuid(), 16, 'ba017fb7-f58a-4ca0-b33c-93063b1265d3', 'BP001-FRONT', 'Front Brake Pads', 1, 1, true, '2025-09-15 13:00:00+00', 'Brake inspection during alternator replacement - verified', '2025-09-11 08:45:00+00', '2025-09-15 13:00:00+00'),

-- Task 23 (Replace wiper blades) - completed status
(gen_random_uuid(), 23, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 2, 2, true, '2025-09-15 16:00:00+00', 'Front and rear wiper blades replaced - verified', '2025-09-11 08:45:00+00', '2025-09-15 16:00:00+00'),

-- Task 24 (Flush coolant system) - completed status  
(gen_random_uuid(), 24, '2a99ea43-30f8-4bb9-a73f-91420a1bc927', 'TF001-ATF', 'Transmission Fluid', 1, 1, true, '2025-09-16 11:00:00+00', 'Transmission service during coolant flush - verified', '2025-09-11 08:45:00+00', '2025-09-16 11:00:00+00'),
(gen_random_uuid(), 24, '89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 1, 1, true, '2025-09-16 11:30:00+00', 'Cabin filter replaced during coolant service - verified', '2025-09-11 08:45:00+00', '2025-09-16 11:30:00+00'),

-- Add more requirements to existing accepted tasks for more comprehensive testing

-- Task 18 (Replace brake pads) - accepted status, add more requirements
(gen_random_uuid(), 18, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 1, 0, false, null, 'Wiper blade inspection during brake work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 19 (Change engine oil) - accepted status, add more requirements  
(gen_random_uuid(), 19, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 0, false, null, 'Air filter check during oil change', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 19, '89c30537-976c-4ba2-acae-c719486a5418', 'CF001-CABIN', 'Cabin Air Filter', 1, 0, false, null, 'Cabin filter inspection during service', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 5 (Rotate tires) - accepted status, add more requirements
(gen_random_uuid(), 5, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 0, false, null, 'Brake system check during tire rotation', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 5, 'ba017fb7-f58a-4ca0-b33c-93063b1265d3', 'BP001-FRONT', 'Front Brake Pads', 1, 0, false, null, 'Brake pad inspection during tire service', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 13 (Test air conditioning) - accepted status, add more requirements
(gen_random_uuid(), 13, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 1, 0, false, null, 'Engine service during AC diagnostics', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 17 (Diagnose engine noise) - accepted status, add more requirements
(gen_random_uuid(), 17, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 2, 0, false, null, 'Oil change may be needed for engine diagnosis', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 17, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 0, false, null, 'Air filter check during engine diagnostics', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 25 (Install new horn) - accepted status, add more requirements  
(gen_random_uuid(), 25, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 0, false, null, 'Brake system check during electrical work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 26 (Test battery health) - accepted status, add more requirements
(gen_random_uuid(), 26, '51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 4, 0, false, null, 'Spark plug inspection during battery diagnostics', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 26, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 1, 0, false, null, 'Engine service during battery test', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Add requirements to more assigned tasks for comprehensive testing

-- Task 8 (Replace rear lights) - assigned status, add more requirements
(gen_random_uuid(), 8, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 0, false, null, 'Brake light system check during rear light replacement', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 9 (Inspect suspension) - assigned status, add more requirements  
(gen_random_uuid(), 9, '3de45dbd-182f-425b-9564-e08ddec840f1', 'BF001-DOT4', 'Brake Fluid DOT4', 1, 0, false, null, 'Brake system inspection during suspension check', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 9, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 1, 0, false, null, 'General maintenance during suspension inspection', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 15 (Check brake fluid) - assigned status, add more requirements
(gen_random_uuid(), 15, 'ba017fb7-f58a-4ca0-b33c-93063b1265d3', 'BP001-FRONT', 'Front Brake Pads', 2, 0, false, null, 'Brake pad inspection during fluid check', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 15, '005d53e7-ee0e-4f4a-a58d-0071b44f57e9', 'BP002-REAR', 'Rear Brake Pads', 2, 0, false, null, 'Rear brake pad inspection during fluid service', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 20 (Replace exhaust pipe) - assigned status, add more requirements
(gen_random_uuid(), 20, 'b756ae74-7cee-4746-a77a-038460aa7d67', 'OF001-5W30', 'Engine Oil 5W-30', 1, 0, false, null, 'Engine service during exhaust replacement', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 20, '948452f8-e369-4fe6-8f8e-d828f53a6420', 'AF001-STD', 'Air Filter', 1, 0, false, null, 'Air filter check during exhaust work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),

-- Task 21 (Replace fuse box) - assigned status, add more requirements
(gen_random_uuid(), 21, '1ae05d73-09fe-43a9-a0ff-6e46806d4c50', 'WB001-FRONT', 'Front Wiper Blades', 1, 0, false, null, 'Wiper electrical check during fuse box work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00'),
(gen_random_uuid(), 21, '51b47ace-e1f2-4d4e-9ca7-61ea89122b8c', 'SP001-NGK', 'NGK Spark Plugs', 4, 0, false, null, 'Ignition system check during electrical work', '2025-09-11 08:45:00+00', '2025-09-11 08:45:00+00');
