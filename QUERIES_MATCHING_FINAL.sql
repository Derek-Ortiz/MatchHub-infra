CREATE OR REPLACE FUNCTION sp_obtener_preferencias_con_porcentaje(
  p_usuario_id INTEGER,
  p_otro_usuario_id INTEGER
)
RETURNS TABLE (
  preferencia_id INTEGER,
  nombre VARCHAR,
  descripcion TEXT,
  estado_coincidencia TEXT,
  porcentaje_coincidencia INTEGER
)
LANGUAGE sql
AS $$
WITH preferencias_usuario_actual AS (
  SELECT jp.preferencia_id, p.nombre, p.descripcion
  FROM jugador_preferencias jp
  JOIN preferencias p ON jp.preferencia_id = p.id
  WHERE jp.jugador_id = p_usuario_id
),
preferencias_otro_usuario AS (
  SELECT preferencia_id
  FROM jugador_preferencias
  WHERE jugador_id = p_otro_usuario_id
),
preferencias_con_coincidencia AS (
  SELECT
    pua.preferencia_id,
    pua.nombre,
    pua.descripcion,
    CASE
      WHEN pua.preferencia_id IN (SELECT preferencia_id FROM preferencias_otro_usuario)
      THEN 'coincide'
      ELSE 'no_coincide'
    END AS estado_coincidencia
  FROM preferencias_usuario_actual pua
)
SELECT
  preferencia_id,
  nombre,
  descripcion,
  estado_coincidencia,
  CASE
    WHEN estado_coincidencia = 'coincide' THEN 100
    ELSE 0
  END AS porcentaje_coincidencia
FROM preferencias_con_coincidencia
ORDER BY estado_coincidencia DESC, nombre ASC;
$$;


CREATE OR REPLACE PROCEDURE sp_limpiar_solicitudes_expiradas()
LANGUAGE plpgsql
AS $$
BEGIN
  WITH updated AS (
    UPDATE solicitudes_match
    SET
      estado = 'rechazada',
      fecha_rechazo = NOW(),
      updated_at = NOW()
    WHERE estado = 'pendiente'
      AND fecha_expiracion < NOW()
      AND deleted_at IS NULL
    RETURNING id, jugador_receptor_id
  )
  INSERT INTO historial_estados_match (
    solicitud_match_id,
    estado_anterior,
    estado_nuevo,
    usuario_id,
    razon,
    created_at
  )
  SELECT
    id,
    'pendiente',
    'rechazada',
    jugador_receptor_id,
    'Auto-rechazada: expiracion de 7 dias',
    NOW()
  FROM updated;
END;
$$;


CREATE OR REPLACE FUNCTION sp_obtener_solicitudes_recibidas(
  p_usuario_id INTEGER
)
RETURNS TABLE (
  id INTEGER,
  jugador_solicitante_id INTEGER,
  solicitante_username VARCHAR,
  solicitante_avatar VARCHAR,
  solicitante_estilo estilo_juego_enum,
  solicitante_region region_enum,
  solicitante_plataformas JSONB,
  videojuego_id INTEGER,
  juego_nombre VARCHAR,
  estado estado_solicitud_enum,
  compatibility_score NUMERIC(5, 2),
  mensaje TEXT,
  fecha_expiracion TIMESTAMPTZ,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
AS $$
SELECT
  sm.id,
  sm.jugador_solicitante_id,
  j.username AS solicitante_username,
  j.avatar_url AS solicitante_avatar,
  j.estilo_juego AS solicitante_estilo,
  j.region AS solicitante_region,
  j.plataformas AS solicitante_plataformas,
  sm.videojuego_id,
  v.nombre AS juego_nombre,
  sm.estado,
  sm.compatibility_score,
  sm.mensaje,
  sm.fecha_expiracion,
  sm.created_at
FROM solicitudes_match sm
JOIN jugadores j ON sm.jugador_solicitante_id = j.id
JOIN videojuegos v ON sm.videojuego_id = v.id
WHERE sm.jugador_receptor_id = p_usuario_id
  AND sm.estado = 'pendiente'
  AND sm.fecha_expiracion > NOW()
  AND sm.deleted_at IS NULL
ORDER BY sm.compatibility_score DESC;
$$;
