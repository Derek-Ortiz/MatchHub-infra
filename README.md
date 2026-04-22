# 🎮 MatchHub - Infraestructura de Base de Datos

**MatchHub** es una plataforma de matching para gamers que conecta jugadores basándose en preferencias y compatibilidad de estilos de juego. Este repositorio contiene la infraestructura de base de datos PostgreSQL, scripts de inicialización y configuración con Docker.

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Base de Datos](#base-de-datos)
- [Despliegue](#despliegue)
- [Seguridad](#seguridad)
- [Troubleshooting](#troubleshooting)

---

## 📝 Descripción

MatchHub es un sistema de **Aplicaciones Web Orientadas a Servicios (AWOS)** que integra:

- ✅ **PostgreSQL 16**: Base de datos relacional con esquema optimizado
- ✅ **Docker**: Containerización para garantizar portabilidad
- ✅ **Stored Procedures**: Búsqueda inteligente de jugadores compatibles
- ✅ **Funciones SQL**: Cálculo automático de scores de compatibilidad
- ✅ **ENUM Types**: Tipado fuerte para datos categóricos
- ✅ **Índices Optimizados**: Performance en búsquedas frecuentes

**Características Principales:**
- Matching de jugadores por videojuegos en común
- Cálculo de compatibilidad basado en múltiples factores
- Sistema de solicitudes y matches
- Datos seeded de videojuegos iniciales

---

## 💻 Requisitos

### Opción 1: Con Docker (RECOMENDADO)
- Docker Desktop 4.0+ ([Descargar](https://www.docker.com/products/docker-desktop))
- Docker Compose 2.0+
- Git

### Opción 2: PostgreSQL Local
- PostgreSQL 16+ ([Descargar](https://www.postgresql.org/download/))
- Git
- Ejecutar scripts SQL manualmente

---

## 🚀 Instalación

### Opción 1: Docker Compose (RECOMENDADO)

```bash
# 1. Clonar repositorio
git clone https://github.com/yourusername/matchhub.git
cd matchhub/MatchHub-infra

# 2. Crear archivo .env
cp .env.example .env

# 3. Iniciar PostgreSQL
docker-compose up -d

# 4. Verificar que está listo
docker-compose ps
docker-compose exec postgres pg_isready -U gaminguser
```

**Acceder a la base de datos:**
```bash
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2
```

### Opción 2: PostgreSQL Local

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-16

# macOS (Homebrew)
brew install postgresql@16

# Crear BD
createdb -U postgres gaming_platform_v2

# Ejecutar scripts en orden
psql -U postgres -d gaming_platform_v2 -f SCHEMA_MODIFICADO_V2.sql
psql -U postgres -d gaming_platform_v2 -f SEED_VIDEOJUEGOS_FINAL.sql
psql -U postgres -d gaming_platform_v2 -f SEED_PREFERENCIAS_FINAL.sql
psql -U postgres -d gaming_platform_v2 -f SP_BUSCAR_COMPATIBLES_CORREGIDO.sql
psql -U postgres -d gaming_platform_v2 -f FUNCTION_CALCULAR_COMPATIBILITY_CORREGIDA.sql
```

---

## ⚙️ Configuración

### Variables de Entorno (.env)

El archivo `.env.example` contiene todas las variables disponibles. Copia y personaliza:

## 🗄️ Base de Datos

### Estructura del Schema

```
┌─────────────────────────────────────────────────────────────┐
│                      JUGADORES (Usuarios)                   │
│  - id (PK), clerk_user_id (UQ), username, email, discord_id │
│  - estilo_juego (ENUM), region (ENUM), estado (ENUM)        │
│  - plataformas (JSONB), is_online, created_at               │
└──────────┬──────────────────────────────────────────────────┘
           │
           │ 1:N
           ▼
┌─────────────────────────────────────────────────────────────┐
│            PREFERENCIAS_JUGADORES                           │
│  - id, jugador_id (FK), videojuego_id (FK)                  │
│  - horas_jugadas, skill_level, disponibilidad_horaria       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│               VIDEOJUEGOS (Catálogo)                        │
│  - id (PK), nombre, generos, url_rawg, rating              │
│  - origen (ENUM: rawg/custom), created_at                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│            SOLICITUDES_MATCH                                │
│  - id, jugador_emisor (FK), jugador_receptor (FK)          │
│  - estado (ENUM: pendiente/aceptada/rechazada)              │
│  - mensaje, created_at                                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  MATCHES (Resultados)                       │
│  - id, jugador1 (FK), jugador2 (FK), estado (ENUM)          │
│  - rating1, rating2, created_at                             │
└─────────────────────────────────────────────────────────────┘
```

### Tipos ENUM Definidos

```sql
estilo_juego_enum      → 'casual' | 'competitivo'
region_enum            → 'norte' | 'centro' | 'sur'
estado_jugador_enum    → 'activo' | 'baneado' | 'suspendido'
origen_videojuego_enum → 'rawg' | 'custom'
estado_solicitud_enum  → 'pendiente' | 'aceptada' | 'rechazada' | 'cancelada'
estado_match_enum      → 'activo' | 'completado' | 'cancelado'
```

### Funciones SQL Importantes

#### 1. **FUNCTION_CALCULAR_COMPATIBILITY_CORREGIDA**

Calcula score de compatibilidad entre dos jugadores (0-100):

```sql
SELECT calcular_compatibilidad(1, 2) AS compatibility_score;
-- Resultado: 85
```

**Factores considerados:**
- Videojuegos en común (40%)
- Estilo de juego similar (30%)
- Nivel de habilidad cercano (20%)
- Disponibilidad horaria (10%)

#### 2. **SP_BUSCAR_COMPATIBLES_CORREGIDO**

Busca jugadores compatibles para un usuario específico:

```sql
CALL sp_buscar_compatibles(
  p_jugador_id := 1,
  p_limite := 10
);
```

**Retorna:** Top 10 jugadores más compatibles con su compatibilidad %

### Índices para Optimización

```sql
-- Búsquedas por usuario
CREATE UNIQUE INDEX idx_jugadores_clerk_id ON jugadores(clerk_user_id);
CREATE UNIQUE INDEX idx_jugadores_username ON jugadores(username);

-- Filtros por región y estado
CREATE INDEX idx_jugadores_region_estado ON jugadores(region, estado);

-- Búsquedas de preferencias
CREATE INDEX idx_preferencias_jugador ON preferencias_jugadores(jugador_id);
CREATE INDEX idx_matches_jugadores ON matches(jugador1_id, jugador2_id);
```

---

## 🐳 Despliegue

### Iniciar Servicios

```bash
# Iniciar PostgreSQL en background
docker-compose up -d postgres

# Ver logs
docker-compose logs -f postgres

# Ver estado
docker-compose ps
```

### Parar Servicios

```bash
# Parar sin eliminar datos
docker-compose stop

# Parar y eliminar (CUIDADO: elimina volúmenes)
docker-compose down
docker-compose down -v  # con datos
```

### Backup y Restore

```bash
# Crear backup
docker-compose exec postgres pg_dump -U gaminguser gaming_platform_v2 > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar desde backup
docker-compose exec -T postgres psql -U gaminguser gaming_platform_v2 < backup_20240101_120000.sql
```

### Verificar Estado de BD

```bash
# Conectar a la BD
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2

# Dentro de psql:
\dt                        -- Listar todas las tablas
\d jugadores              -- Describir tabla
SELECT COUNT(*) FROM jugadores;  -- Contar registros
```

---

## 🔒 Seguridad

### Control de Acceso

✅ **PostgreSQL:**
- Usuario `gaminguser` con permisos limitados (solo lectura/escritura)
- Contraseña en archivo `.env` (no versionado)
- Base de datos NO expuesta directamente (solo puerto 5432 local)

✅ **Variables Sensibles:**
- Almacenadas en `.env` (ignorado por Git)
- Diferentes para desarrollo y producción
- Jamás hardcodeadas en código

✅ **SQL Injection Prevention:**
- Todos los scripts usan Prepared Statements
- Stored Procedures validados
- Tipos ENUM para datos categóricos

✅ **Auditoría:**
- Logs de conexión en PostgreSQL
- Timestamps en todas las tablas (created_at, updated_at)
- Tracking de cambios en operaciones críticas

---

## 📊 Estadísticas y Monitoreo

```bash
# Ver cantidad de registros
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2 << EOF
SELECT 
  'jugadores' AS tabla, COUNT(*) AS total FROM jugadores UNION ALL
SELECT 'videojuegos', COUNT(*) FROM videojuegos UNION ALL
SELECT 'matches', COUNT(*) FROM matches;
EOF

# Ver índices creados
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2 -c "\di"

# Ver conexiones activas
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2 -c "SELECT * FROM pg_stat_activity;"
```

---

## 🐛 Troubleshooting

### PostgreSQL no inicia

```bash
# Ver logs
docker-compose logs postgres

# Verificar puertos
docker-compose ps

# Limpiar y reiniciar
docker-compose down -v
docker-compose up -d
```

### Error de conexión desde API

```bash
# Verificar que está corriendo
docker-compose exec postgres pg_isready -U gaminguser

# Probar conexión
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2 -c "SELECT 1"
```

### Puerto 5432 en uso

```bash
# Windows
netstat -ano | findstr :5432
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :5432
kill -9 <PID>
```

### Restaurar esquema si falla

```bash
# Conectar a BD
docker-compose exec postgres psql -U gaminguser -d gaming_platform_v2

# Recrear schema
\i SCHEMA_MODIFICADO_V2.sql
\i SEED_VIDEOJUEGOS_FINAL.sql
\i SEED_PREFERENCIAS_FINAL.sql
\i SP_BUSCAR_COMPATIBLES_CORREGIDO.sql
\i FUNCTION_CALCULAR_COMPATIBILITY_CORREGIDA.sql
```

---

## 📦 Archivos del Proyecto

- **`.env.example`** - Plantilla de variables de entorno
- **`.env`** - Variables actuales (no commitear)
- **`docker-compose.yml`** - Configuración Docker
- **`SCHEMA_MODIFICADO_V2.sql`** - Esquema de tablas
- **`SEED_VIDEOJUEGOS_FINAL.sql`** - Datos iniciales de juegos
- **`SEED_PREFERENCIAS_FINAL.sql`** - Datos iniciales de preferencias
- **`SP_BUSCAR_COMPATIBLES_CORREGIDO.sql`** - Stored Procedure de búsqueda
- **`FUNCTION_CALCULAR_COMPATIBILITY_CORREGIDA.sql`** - Función de cálculo
- **`QUERIES_MATCHING_FINAL.sql`** - Queries útiles de consulta
- **`postgres.conf`** - Configuración PostgreSQL
- **`.gitignore`** - Archivos a ignorar en Git
- **`README.md`** - Este archivo

---

## 🔗 Referencias

- [PostgreSQL 16 Docs](https://www.postgresql.org/docs/16/)
- [Docker Compose](https://docs.docker.com/compose/)
- [RAWG API](https://rawg.io/api)

---
