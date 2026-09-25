# Raíces y Estrellas

**Raíces y Estrellas: Un viaje personal de 30 días.**

Aplicación móvil Flutter de bienestar y crecimiento personal. Acompaña durante 30 días de
autoconocimiento, reflexión, pequeñas acciones y hábitos saludables. Funciona **100 % offline**,
sin cuentas, sin servidores y sin enviar datos fuera del dispositivo.

> «Tu grandeza no consiste en ser perfecto. Consiste en descubrir lo que eres capaz de construir.»

## Objetivo

Ofrecer un viaje guiado (no una colección de frases) donde cada día combina reflexión, una
interacción distinta, un microreto, meditación y progreso visual: 30 estrellas, 4 constelaciones,
un árbol que crece y 7 raíces que se iluminan. La app acompaña, no impone, y nunca castiga
por ausencias.

## Funcionalidades

| Área | Qué hace |
| --- | --- |
| Onboarding | 5 pantallas, solo la primera vez. Guarda etapa de vida (13–17, 18–30, 31–50, 51+) y objetivo opcional. |
| Viaje de 30 días | Progresión estrictamente secuencial (bloqueado, disponible, en progreso, completado). Contenido completo en `assets/content/days_es.json`, adaptado por etapa de vida. |
| Sesión diaria | Bienvenida → check-in emocional → enseñanza y filosofía práctica → interacción (12 tipos) → microreto → meditación y ambiente → cierre y recompensa. |
| Carta del Día 1 | Editable hasta completar el Día 1, sellada hasta el Día 30, respuesta al yo futuro y declaración final guardadas en el diario. |
| Hitos | Días 7, 14, 21 y 30 con constelaciones que se conectan, árbol que evoluciona, partículas, sonido y vibración (según ajustes). |
| Mi Viaje | Mapa de 30 estrellas, rachas, XP y nivel, insignias, raíces, microretos, meditaciones y ciclos anteriores. |
| Árbol | Semilla → brote → árbol joven → árbol en crecimiento → árbol completo. Raíces tocables con detalle. |
| Medítate | 8 tipos × 1/3/5/10 min, animación Inhala · Mantén · Exhala, temporizador, texto guía y sonido opcional. |
| Pausa | Refugio accesible desde Inicio, Hoy, Medítate y cada día: respiración, temporizador, frases, sonido, detener y volver. |
| Diario | Entradas libres, respuestas guiadas, cartas, etiquetas, relación con días, edición y eliminación. |
| Emociones | Check-in diario, tendencia semanal, distribución, promedio y eliminación de registros. Sin diagnósticos. |
| Guía local | Mensajes basados en reglas (día, progreso, emoción, constelación, raíz, racha, microreto). Sin IA externa. |
| Ajustes | Tema claro/oscuro/sistema, tamaño de texto, reducir animaciones, música, ambiente, efectos, vibración, recordatorio y privacidad. |

## Cómo ejecutar

Requisitos: Flutter estable (probado con la plantilla de Flutter 3.47), JDK 17 y Android SDK.

```bash
flutter pub get
flutter run
```

## Cómo ejecutar las pruebas

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Pruebas incluidas:

- `test/progress_service_test.dart`: desbloqueo secuencial, Día 30, rachas, persistencia,
  estrellas, constelaciones, raíces, árbol, carta sellada y reinicios.
- `test/services_test.dart`: contenido de 30 días, check-in emocional, diario, guía local,
  respuesta segura, validaciones, recordatorios, preferencias de audio y borrado de datos.
- `test/widget_test.dart`: onboarding, Inicio, navegación a Hoy / Mi Viaje / Medítate,
  registro de emoción, cambio de tema y estados de un día.

## Cómo generar el APK

```bash
flutter build apk --release
```

Se genera un único APK universal en `build/app/outputs/flutter-apk/app-release.apk`.

En GitHub, el workflow **Build APK** (`.github/workflows/build_apk.yml`) se ejecuta manualmente
(*workflow_dispatch*) o al subir un tag `v*` (por ejemplo `git tag v1.0.0 && git push --tags`),
y publica el artifact `raices-y-estrellas-apk`. El workflow **Flutter CI** valida formato,
análisis y pruebas en `main`, `develop` y en pull requests hacia `main`.

> El APK de release se firma con la clave de depuración para poder instalarlo directamente.
> Para publicarlo en una tienda, configura tu propia firma de forma local (nunca subas claves al repositorio).

## Estructura de carpetas

```
lib/
  main.dart                 Arranque
  app.dart                  MaterialApp, temas, escala de texto, ciclo de vida
  models/                   UserProfile, LifeStage, DayContent, DailyProgress, EmotionCheckIn,
                            JournalEntry, MicroChallenge, MeditationSession, Achievement,
                            RootProgress, ConstellationProgress, AppSettings, ReminderSettings
  data/                     Insignias, guiones de meditación, catálogo de sonidos, mensajes
  services/                 ProgressService, ContentService, JournalService, EmotionService,
                            MeditationService, AudioService, NotificationService,
                            PersonalGuideService, SafetyResponseService, SettingsService,
                            StorageService, AppController
  screens/                  Onboarding, Inicio, Hoy, Sesión del día, Mi Viaje, Árbol, Medítate,
                            Pausa, Diario, Emociones, Microretos, Ajustes, hitos y cierre
  widgets/                  Mapa de constelaciones, árbol, respiración, partículas, etc.
  theme/                    Paleta y temas claro/oscuro
  utils/                    Fechas y validaciones
assets/
  content/days_es.json      Contenido completo de los 30 días (separado del diseño)
  images/                   Ilustración de la app
  audio/music/              Música ambiental (generada para el proyecto)
  audio/nature/             Lluvia, mar, bosque, viento, fuego, agua y noche
  audio/effects/            Efectos de estrella, día, insignia, raíz, constelación, viaje, campana
test/                       Pruebas unitarias y de widgets
docs/README.md              Guía breve de uso
android/                    Proyecto Android (com.josuecr1801.raicesyestrellas)
.github/workflows/          flutter_ci.yml y build_apk.yml
```

## Persistencia local

Todo se guarda con `shared_preferences` en el propio dispositivo (claves con prefijo `rye.`):
perfil, etapa, objetivo, onboarding, progreso (`completedDays`, `currentDay`, `unlockedDay`,
`startedDays`, `lastActivityDate`, `currentStreak`, `longestStreak`, XP), respuestas de cada día,
cartas, diario, emociones, microretos, meditaciones, insignias y ajustes. Estrellas, raíces,
constelaciones y nivel se calculan a partir de esos datos. No hay backend, login ni sincronización.

## Audio local

- Todos los sonidos están en `assets/audio/` en formato OGG y **fueron generados
  procedimentalmente para este proyecto** (ruido filtrado, ondas sinusoidales y envolventes),
  por lo que no tienen derechos de terceros.
- `lib/services/audio_service.dart` controla música, sonidos ambientales y efectos: un solo
  reproductor por canal en bucle (sin reproducciones simultáneas descontroladas), volumen bajo,
  pausa, detención, pausa automática al pasar a segundo plano y liberación de recursos.
- Cada interruptor de Ajustes cambia el comportamiento real: al desactivar un canal se detiene
  lo que suena y ya no se reproduce.
- La **voz guiada no está incluida** en esta versión, por eso no aparece ningún control para ella.

**Añadir un sonido nuevo**

1. Copia el archivo (OGG o MP3, libre de derechos) en `assets/audio/nature/`, `music/` o `effects/`.
2. Regístralo en `lib/data/sound_catalog.dart` (`ambientSounds`, `musicTracks` o `SoundEffect`).
3. Aparecerá automáticamente en los selectores de Pausa, Medítate y Ajustes.

## Notificaciones locales

`lib/services/notification_service.dart` usa `flutter_local_notifications` + `timezone` para un
recordatorio diario programado localmente (`zonedSchedule` con repetición diaria, modo inexacto
para no requerir alarmas exactas). Se puede activar, desactivar, cambiar de hora, probar y
reintentar el permiso desde Ajustes. En Android 13+ se solicita `POST_NOTIFICATIONS`; si se
rechaza, la app sigue funcionando y explica cómo reintentar. Los recordatorios se reprograman al
abrir la app y tras reiniciar el teléfono. Sin push, sin servidor y sin Internet.

## Advertencia de bienestar

Raíces y Estrellas es una herramienta de reflexión y crecimiento personal. **No diagnostica,
no ofrece consejo clínico y no sustituye a psicólogos, psiquiatras, médicos ni terapeutas.**
Si en el diario o en una respuesta aparece contenido relacionado con autolesión, suicidio,
violencia inmediata o emergencia, la app muestra localmente un mensaje que invita a buscar
apoyo inmediato de una persona de confianza, un profesional o los servicios de emergencia.
Esta detección es simple (palabras clave) y no reemplaza la ayuda profesional.

## Limitaciones del MVP

- Solo en español y orientado a Android (el código Flutter es multiplataforma, pero no se
  incluyen carpetas de iOS ni configuración de firma para tiendas).
- La detección de mensajes de riesgo se basa en palabras clave locales.
- La zona horaria del recordatorio se deduce del desfase horario del dispositivo; en zonas con
  horario de verano puede desplazarse una hora hasta que se vuelva a abrir la app.
- No hay voz guiada, copias de seguridad ni exportación del diario.
- Los datos se pierden si se desinstala la app (no hay sincronización en la nube por diseño).
