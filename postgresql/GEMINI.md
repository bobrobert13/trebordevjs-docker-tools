<!-- Buenas Prácticas al Escribir Contexto

- Sé conciso: 1-3 frases por sección cuando sea posible.
- Ejemplos concretos: incluye comandos y resultados esperados.
- Seguridad: no incluyas contraseñas reales en el repositorio.
- **Trazabilidad: actualiza la sección `Changelog` cuando cambies. -->


# GEMINI — Contexto del Proyecto

> Resumen corto: escribe 1-2 oraciones que expliquen el propósito general.

## 1. Metadatos

- **Nombre del proyecto:** [Nombre del proyecto]
- **Fecha:** [YYYY-MM-DD]
- **Autor / Contacto:** [Nombre <email@ejemplo>]
- **Versión / Tag:** [v0.1.0]


## 2. Objetivo y Alcance

- **Objetivo:** Describe qué intenta lograr el repositorio/servicio.
- **Alcance:** Indica qué está cubierto y qué queda fuera.

<!-- Ejemplo:
Objetivo: Proveer una instancia local de NocoDB sobre PostgreSQL
para pruebas de integración de la app web.
Alcance: Solo incluye servicios Docker para desarrollo local; no
incluye despliegue en producción ni backups.
-->

## 6. Variables de Entorno y Configuración

- **Formato recomendado:** usa `.env` o `docker-compose.override.yml`.
- **Variables críticas (ejemplos):**

```
POSTGRES_USER=admin
POSTGRES_PASSWORD=changeme
POSTGRES_DB=nocodb
NOCO_PORT=8080
```

## 8. Ejemplo de Contexto Llenado (Rápido)

- **Resumen corto:** Orquestación local de NocoDB + PostgreSQL para pruebas.
- **Nombre del proyecto:** TREBOR.JS - services-compose
- **Fecha:** 2025-12-05
- **Autor / Contacto:** Robert <robert@ejemplo.com>
- **Objetivo:** Permitir a desarrolladores levantar una DB y UI rápida.
- **Requisitos:** Docker >=20.10, 4GB RAM.


<!-- ========================================================================= -->
## 10. Changelog / Historial

- `2025-12-05` — Plantilla inicial creada por [autor].


## 11. Referencias

- Enlaces a documentación externa o tickets relevantes.
<!-- ========================================================================= -->