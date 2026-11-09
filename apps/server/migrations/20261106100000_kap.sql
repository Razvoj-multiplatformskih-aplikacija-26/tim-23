-- migrate:up

-- Nalozi: davaoci (mobilna aplikacija) i osoblje (backoffice). Lozinka samo kao Argon2id heš.
CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('donor', 'nurse', 'coordinator')),
  login text UNIQUE,
  password_hash text
);

-- Podaci davaoca; id je isti kao id njegovog naloga.
CREATE TABLE donors (
  id text PRIMARY KEY REFERENCES users (id),
  birth_date date NOT NULL,
  sex text NOT NULL CHECK (sex IN ('male', 'female')),
  blood_group text NOT NULL CHECK (
    blood_group IN ('oPositive', 'oNegative', 'aPositive', 'aNegative', 'bPositive', 'bNegative', 'abPositive', 'abNegative')
  ),
  city text NOT NULL,
  last_donation date
);

-- Akcije davanja krvi.
CREATE TABLE drives (
  id text PRIMARY KEY,
  title text NOT NULL,
  city text NOT NULL,
  address text NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  slot_minutes int NOT NULL DEFAULT 30 CHECK (slot_minutes > 0),
  slot_capacity int NOT NULL CHECK (slot_capacity > 0),
  CHECK (ends_at > starts_at)
);

-- Termini davanja (glavni pojam).
CREATE TABLE appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  donor_id text NOT NULL REFERENCES donors (id),
  drive_id text NOT NULL REFERENCES drives (id),
  slot_start timestamptz NOT NULL,
  slot_minutes int NOT NULL DEFAULT 30,
  status text NOT NULL CHECK (
    status IN ('scheduled', 'confirmed', 'checked-in', 'donated', 'deferred', 'cancelled', 'no-show')
  ),
  status_at timestamptz,
  status_reason text,
  by_staff boolean,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Pravilo „najviše jedan aktivan termin“ čuva i baza: dva istovremena zakazivanja
-- istog davaoca ne mogu oba da prođu, čak ni sa dva uređaja.
CREATE UNIQUE INDEX appointments_one_active_per_donor ON appointments (donor_id)
  WHERE status IN ('scheduled', 'confirmed', 'checked-in');

CREATE INDEX appointments_by_drive ON appointments (drive_id, slot_start);
CREATE INDEX appointments_by_donor ON appointments (donor_id);

-- migrate:down
DROP TABLE appointments;
DROP TABLE drives;
DROP TABLE donors;
DROP TABLE users;
