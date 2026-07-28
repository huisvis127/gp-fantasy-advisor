# Receptor privado de estadísticas de Polewise

Receptor opcional para Cloudflare Workers + D1. Guarda únicamente:

- día;
- identificador aleatorio que cambia cada día;
- versión de Polewise;
- nombre de evento permitido;
- contador agregado.

No lee ni persiste IP, cabeceras, modelo del dispositivo, ubicación, cuenta,
equipo, liga o token.

## Puesta en marcha

1. Crear una base D1 y aplicar `schema.sql`.
2. Copiar `wrangler.toml.example` como `wrangler.toml` e introducir el ID.
3. Guardar un secreto fuerte como `ADMIN_TOKEN`.
4. Desplegar el Worker.
5. En la configuración remota de Polewise, establecer:

```json
{
  "endpoints": {
    "analytics": "https://<worker>/collect"
  },
  "feature_flags": {
    "anonymous_usage_analytics": true
  }
}
```

El resumen privado se consulta con:

```text
GET https://<worker>/summary?days=30
Authorization: Bearer <ADMIN_TOKEN>
```

Devuelve dispositivos activos diarios aproximados y el uso de cada pantalla o
acción. El identificador diario no permite seguir a una persona entre días.
