-- =====================================================
-- SEED DATA - PREFERENCIAS ACTUALIZADAS (16 TOTALES)
-- =====================================================

DELETE FROM preferencias WHERE creador_id IS NULL;

INSERT INTO preferencias (nombre, descripcion, creador_id, activo) VALUES
('Competitivo', 'Juego enfocado en ganar y mejorar habilidades', NULL, TRUE),
('Casual', 'Juego sin presion, por diversion y entretenimiento', NULL, TRUE),
('Comunicativo', 'Preferencia por comunicacion constante con el equipo', NULL, TRUE),
('Estrategico', 'Enfoque en planificacion y tactica', NULL, TRUE),
('Agresivo', 'Preferencia por juego ofensivo y directo', NULL, TRUE),
('Defensivo', 'Preferencia por juego defensivo y cuidadoso', NULL, TRUE),
('Flexible', 'Adaptable a diferentes estilos de juego', NULL, TRUE),
('Paciente', 'Preferencia por juego lento y meticuloso', NULL, TRUE),
('Serio', 'Ambiente serio y enfocado en el juego', NULL, TRUE),
('Divertido', 'Ambiente relajado, risas y buen ambiente', NULL, TRUE),
('Nocturno', 'Preferencia por jugar en horarios nocturnos', NULL, TRUE),
('Social', 'Preferencia por jugar con amigos y socializar', NULL, TRUE);

-- =====================================================
-- SEED LISTO
-- =====================================================
