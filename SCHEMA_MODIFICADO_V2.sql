DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estilo_juego_enum') THEN
    CREATE TYPE estilo_juego_enum AS ENUM ('casual', 'competitivo');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'region_enum') THEN
    CREATE TYPE region_enum AS ENUM ('norte', 'centro', 'sur');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_jugador_enum') THEN
    CREATE TYPE estado_jugador_enum AS ENUM ('activo', 'baneado', 'suspendido');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'origen_videojuego_enum') THEN
    CREATE TYPE origen_videojuego_enum AS ENUM ('rawg', 'custom');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_solicitud_enum') THEN
    CREATE TYPE estado_solicitud_enum AS ENUM ('pendiente', 'aceptada', 'rechazada', 'cancelada');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_match_enum') THEN
    CREATE TYPE estado_match_enum AS ENUM ('activo', 'completado', 'cancelado');
  END IF;
END$$;


CREATE TABLE jugadores (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  clerk_user_id VARCHAR(64) NOT NULL UNIQUE,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255),
  discord_id VARCHAR(30) NOT NULL UNIQUE,
  avatar_url VARCHAR(500),
  descripcion TEXT,
  estilo_juego estilo_juego_enum NOT NULL,
  region region_enum NOT NULL,
  plataformas JSONB NOT NULL,
  is_online BOOLEAN DEFAULT FALSE,
  estado estado_jugador_enum DEFAULT 'activo',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_jugadores_discord_id ON jugadores (discord_id);
CREATE INDEX idx_jugadores_email ON jugadores (email);
CREATE INDEX idx_jugadores_estado ON jugadores (estado);
CREATE INDEX idx_jugadores_region ON jugadores (region);


CREATE TABLE disponibilidad (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  jugador_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  dia_semana SMALLINT NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  timezone VARCHAR(50) NOT NULL DEFAULT 'America/Mexico_City',
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_disponibilidad_jugador_id ON disponibilidad (jugador_id);
CREATE INDEX idx_disponibilidad_dia_semana ON disponibilidad (dia_semana);


CREATE TABLE videojuegos (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  rawg_id INTEGER UNIQUE,
  plataformas JSONB NOT NULL,
  origen origen_videojuego_enum DEFAULT 'custom',
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_videojuego_nombre ON videojuegos (nombre);
CREATE INDEX idx_videojuego_rawg_id ON videojuegos (rawg_id);
CREATE INDEX idx_videojuego_activo ON videojuegos (activo);
CREATE INDEX idx_videojuego_origen ON videojuegos (origen);


CREATE TABLE preferencias (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  creador_id INTEGER REFERENCES jugadores(id) ON DELETE SET NULL,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (nombre, creador_id)
);

CREATE INDEX idx_preferencias_creador_id ON preferencias (creador_id);
CREATE INDEX idx_preferencias_activo ON preferencias (activo);


CREATE TABLE jugador_preferencias (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  jugador_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  preferencia_id INTEGER NOT NULL REFERENCES preferencias(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (jugador_id, preferencia_id)
);

CREATE INDEX idx_jugador_preferencias_jugador_id ON jugador_preferencias (jugador_id);
CREATE INDEX idx_jugador_preferencias_preferencia_id ON jugador_preferencias (preferencia_id);


CREATE TABLE videojuegos_jugador (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  jugador_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  videojuego_id INTEGER NOT NULL REFERENCES videojuegos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (jugador_id, videojuego_id)
);

CREATE INDEX idx_videojuegos_jugador_jugador_id ON videojuegos_jugador (jugador_id);
CREATE INDEX idx_videojuegos_jugador_videojuego_id ON videojuegos_jugador (videojuego_id);


CREATE TABLE solicitudes_match (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  jugador_solicitante_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  jugador_receptor_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  videojuego_id INTEGER NOT NULL REFERENCES videojuegos(id) ON DELETE CASCADE,
  estado estado_solicitud_enum DEFAULT 'pendiente',
  mensaje TEXT,
  fecha_expiracion TIMESTAMPTZ NOT NULL,
  fecha_rechazo TIMESTAMPTZ,
  compatibility_score NUMERIC(5, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT check_diferentes_jugadores CHECK (jugador_solicitante_id <> jugador_receptor_id)
);

CREATE INDEX idx_solicitudes_receptor ON solicitudes_match (jugador_receptor_id);
CREATE INDEX idx_solicitudes_estado ON solicitudes_match (estado);
CREATE INDEX idx_solicitudes_fecha_expiracion ON solicitudes_match (fecha_expiracion);
CREATE INDEX idx_solicitudes_fecha_rechazo ON solicitudes_match (fecha_rechazo);
CREATE INDEX idx_solicitudes_solicitante ON solicitudes_match (jugador_solicitante_id);
CREATE INDEX idx_solicitudes_compatibility_score ON solicitudes_match (compatibility_score DESC);
CREATE INDEX idx_solicitudes_pendiente_expiracion ON solicitudes_match (estado, fecha_expiracion);


CREATE TABLE historial_estados_match (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  solicitud_match_id INTEGER NOT NULL REFERENCES solicitudes_match(id) ON DELETE CASCADE,
  estado_anterior VARCHAR(20),
  estado_nuevo VARCHAR(20) NOT NULL,
  usuario_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  razon TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_historial_solicitud_match_id ON historial_estados_match (solicitud_match_id);
CREATE INDEX idx_historial_usuario_id ON historial_estados_match (usuario_id);


CREATE TABLE match (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  jugador_1_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  jugador_2_id INTEGER NOT NULL REFERENCES jugadores(id) ON DELETE CASCADE,
  videojuego_id INTEGER NOT NULL REFERENCES videojuegos(id) ON DELETE CASCADE,
  discord_link VARCHAR(500),
  estado estado_match_enum DEFAULT 'activo',
  fecha_juego_planeada TIMESTAMPTZ,
  confirmado_por_receptor_en TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT check_diferentes_jugadores_match CHECK (jugador_1_id <> jugador_2_id)
);

CREATE INDEX idx_match_jugador_1 ON match (jugador_1_id);
CREATE INDEX idx_match_jugador_2 ON match (jugador_2_id);
CREATE INDEX idx_match_estado ON match (estado);


CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_created_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.created_at IS NULL THEN
    NEW.created_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_created_and_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.created_at IS NULL THEN
    NEW.created_at = NOW();
  END IF;
  IF NEW.updated_at IS NULL THEN
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_jugadores
BEFORE UPDATE ON jugadores
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_created_at_jugadores
BEFORE INSERT ON jugadores
FOR EACH ROW EXECUTE FUNCTION set_created_and_updated_at();

CREATE TRIGGER set_updated_at_disponibilidad
BEFORE UPDATE ON disponibilidad
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_created_at_disponibilidad
BEFORE INSERT ON disponibilidad
FOR EACH ROW EXECUTE FUNCTION set_created_and_updated_at();

CREATE TRIGGER set_updated_at_videojuegos
BEFORE UPDATE ON videojuegos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_created_at_videojuegos
BEFORE INSERT ON videojuegos
FOR EACH ROW EXECUTE FUNCTION set_created_and_updated_at();

CREATE TRIGGER set_updated_at_preferencias
BEFORE UPDATE ON preferencias
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_created_at_preferencias
BEFORE INSERT ON preferencias
FOR EACH ROW EXECUTE FUNCTION set_created_and_updated_at();

CREATE TRIGGER set_created_at_jugador_preferencias
BEFORE INSERT ON jugador_preferencias
FOR EACH ROW EXECUTE FUNCTION set_created_at();

CREATE TRIGGER set_created_at_videojuegos_jugador
BEFORE INSERT ON videojuegos_jugador
FOR EACH ROW EXECUTE FUNCTION set_created_at();

CREATE TRIGGER set_updated_at_solicitudes_match
BEFORE UPDATE ON solicitudes_match
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_created_at_solicitudes_match
BEFORE INSERT ON solicitudes_match
FOR EACH ROW EXECUTE FUNCTION set_created_and_updated_at();

CREATE TRIGGER set_created_at_historial_estados_match
BEFORE INSERT ON historial_estados_match
FOR EACH ROW EXECUTE FUNCTION set_created_at();

CREATE TRIGGER set_updated_at_match
BEFORE UPDATE ON match
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_created_at_match
BEFORE INSERT ON match
FOR EACH ROW EXECUTE FUNCTION set_created_and_updated_at();


CREATE OR REPLACE VIEW jugadores_buscables AS
SELECT
  j.id,
  j.username,
  j.estilo_juego,
  j.region,
  j.plataformas,
  j.is_online,
  string_agg(DISTINCT vj.videojuego_id::text, ',') AS videojuego_ids,
  string_agg(DISTINCT jp.preferencia_id::text, ',') AS preferencia_ids
FROM jugadores j
LEFT JOIN videojuegos_jugador vj ON j.id = vj.jugador_id
LEFT JOIN jugador_preferencias jp ON j.id = jp.jugador_id
WHERE j.estado = 'activo' AND j.deleted_at IS NULL
GROUP BY j.id, j.username, j.estilo_juego, j.region, j.plataformas, j.is_online;
