-- =====================================================
-- SP BUSCAR COMPATIBLES - VERSION POSTGRES
-- Logica: compara todos los dias y calcula porcentaje proporcional
-- =====================================================

CREATE OR REPLACE FUNCTION sp_buscar_compatibles(
  p_usuario_id INTEGER,
  p_page INTEGER DEFAULT 1,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id INTEGER,
  username VARCHAR,
  avatar_url VARCHAR,
  estilo_juego estilo_juego_enum,
  region region_enum,
  plataformas JSONB,
  is_online BOOLEAN,
  horario_score NUMERIC(5, 2),
  juego_score NUMERIC(5, 2),
  preferencia_score NUMERIC(5, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INTEGER;
  v_total_dias_usuario INTEGER;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  SELECT COUNT(*) INTO v_total_dias_usuario
  FROM disponibilidad
  WHERE jugador_id = p_usuario_id
    AND activo = TRUE;

  IF v_total_dias_usuario = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT *
  FROM (
    SELECT
      j.id,
      j.username,
      j.avatar_url,
      j.estilo_juego,
      j.region,
      j.plataformas,
      j.is_online,
      ROUND(
        (
          SELECT COUNT(DISTINCT da.dia_semana)::numeric
          FROM disponibilidad da
          JOIN disponibilidad db ON da.dia_semana = db.dia_semana
          WHERE da.jugador_id = p_usuario_id
            AND db.jugador_id = j.id
            AND da.activo = TRUE
            AND db.activo = TRUE
            AND da.hora_inicio < db.hora_fin
            AND da.hora_fin > db.hora_inicio
        ) / v_total_dias_usuario * 100 * 0.40,
        2
      ) AS horario_score,
      ROUND(
        CASE
          WHEN (SELECT COUNT(*) FROM videojuegos_jugador WHERE jugador_id = p_usuario_id) = 0 THEN 0
          ELSE (
            SELECT COUNT(DISTINCT va.videojuego_id)::numeric
            FROM videojuegos_jugador va
            JOIN videojuegos_jugador vb ON va.videojuego_id = vb.videojuego_id
            WHERE va.jugador_id = p_usuario_id
              AND vb.jugador_id = j.id
          ) / (
            SELECT COUNT(*) FROM videojuegos_jugador WHERE jugador_id = p_usuario_id
          ) * 100 * 0.30
        END,
        2
      ) AS juego_score,
      ROUND(
        CASE
          WHEN (SELECT COUNT(*) FROM jugador_preferencias WHERE jugador_id = p_usuario_id) = 0 THEN 0
          ELSE (
            SELECT COUNT(DISTINCT pa.preferencia_id)::numeric
            FROM jugador_preferencias pa
            JOIN jugador_preferencias pb ON pa.preferencia_id = pb.preferencia_id
            WHERE pa.jugador_id = p_usuario_id
              AND pb.jugador_id = j.id
          ) / (
            SELECT COUNT(*) FROM jugador_preferencias WHERE jugador_id = p_usuario_id
          ) * 100 * 0.30
        END,
        2
      ) AS preferencia_score
    FROM jugadores j
    WHERE j.id <> p_usuario_id
      AND j.estado = 'activo'
      AND j.deleted_at IS NULL
      AND NOT EXISTS (
        SELECT 1
        FROM match m
        WHERE (m.jugador_1_id = p_usuario_id AND m.jugador_2_id = j.id)
           OR (m.jugador_1_id = j.id AND m.jugador_2_id = p_usuario_id)
          AND m.estado IN ('activo', 'completado')
      )
      AND NOT EXISTS (
        SELECT 1
        FROM solicitudes_match sm
        WHERE (sm.jugador_solicitante_id = p_usuario_id AND sm.jugador_receptor_id = j.id)
           OR (sm.jugador_solicitante_id = j.id AND sm.jugador_receptor_id = p_usuario_id)
          AND sm.estado = 'pendiente'
          AND sm.fecha_expiracion > NOW()
      )
  ) AS s
  WHERE (s.horario_score + s.juego_score + s.preferencia_score) > 0
  ORDER BY (s.horario_score + s.juego_score + s.preferencia_score) DESC
  LIMIT p_limit OFFSET v_offset;
END;
$$;

-- =====================================================
-- PRUEBA
-- SELECT * FROM sp_buscar_compatibles(1, 1, 20);
-- =====================================================
