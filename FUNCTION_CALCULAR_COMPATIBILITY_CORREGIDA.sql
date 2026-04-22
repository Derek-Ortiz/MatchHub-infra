-- =====================================================
-- FUNCTION: fn_calcular_compatibility_score
-- Proposito: calcular score al crear solicitud_match
-- =====================================================

CREATE OR REPLACE FUNCTION fn_calcular_compatibility_score(
  p_jugador_a_id INTEGER,
  p_jugador_b_id INTEGER
)
RETURNS NUMERIC(5, 2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_dias_a INTEGER := 0;
  v_dias_solapan INTEGER := 0;
  v_juegos_comun INTEGER := 0;
  v_juegos_total_a INTEGER := 0;
  v_prefs_comun INTEGER := 0;
  v_prefs_total_a INTEGER := 0;
  v_score_horario NUMERIC(5, 2) := 0;
  v_score_juegos NUMERIC(5, 2) := 0;
  v_score_prefs NUMERIC(5, 2) := 0;
  v_score_total NUMERIC(5, 2) := 0;
BEGIN
  SELECT COUNT(*) INTO v_total_dias_a
  FROM disponibilidad
  WHERE jugador_id = p_jugador_a_id AND activo = TRUE;

  IF v_total_dias_a = 0 THEN
    RETURN 0;
  END IF;

  SELECT COUNT(DISTINCT da.dia_semana) INTO v_dias_solapan
  FROM disponibilidad da
  JOIN disponibilidad db ON da.dia_semana = db.dia_semana
  WHERE da.jugador_id = p_jugador_a_id
    AND db.jugador_id = p_jugador_b_id
    AND da.activo = TRUE
    AND db.activo = TRUE
    AND da.hora_inicio < db.hora_fin
    AND da.hora_fin > db.hora_inicio;

  v_score_horario := ROUND((v_dias_solapan::numeric / v_total_dias_a) * 100 * 0.40, 2);

  SELECT COUNT(*) INTO v_juegos_total_a
  FROM videojuegos_jugador
  WHERE jugador_id = p_jugador_a_id;

  IF v_juegos_total_a > 0 THEN
    SELECT COUNT(DISTINCT va.videojuego_id) INTO v_juegos_comun
    FROM videojuegos_jugador va
    JOIN videojuegos_jugador vb ON va.videojuego_id = vb.videojuego_id
    WHERE va.jugador_id = p_jugador_a_id
      AND vb.jugador_id = p_jugador_b_id;

    v_score_juegos := ROUND((v_juegos_comun::numeric / v_juegos_total_a) * 100 * 0.30, 2);
  END IF;

  SELECT COUNT(*) INTO v_prefs_total_a
  FROM jugador_preferencias
  WHERE jugador_id = p_jugador_a_id;

  IF v_prefs_total_a > 0 THEN
    SELECT COUNT(DISTINCT pa.preferencia_id) INTO v_prefs_comun
    FROM jugador_preferencias pa
    JOIN jugador_preferencias pb ON pa.preferencia_id = pb.preferencia_id
    WHERE pa.jugador_id = p_jugador_a_id
      AND pb.jugador_id = p_jugador_b_id;

    v_score_prefs := ROUND((v_prefs_comun::numeric / v_prefs_total_a) * 100 * 0.30, 2);
  END IF;

  v_score_total := v_score_horario + v_score_juegos + v_score_prefs;
  RETURN v_score_total;
END;
$$;

-- =====================================================
-- PRUEBA
-- SELECT fn_calcular_compatibility_score(1, 2) AS score;
-- =====================================================
