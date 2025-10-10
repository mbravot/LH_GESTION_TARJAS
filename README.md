# 🏢 Sistema de Gestión de Tarjas LH

## 📋 Descripción General

**Sistema web de gestión de tarjas LH** es una aplicación Flutter web desarrollada para la gestión integral de recursos humanos, control de horas trabajadas, tarjas, colaboradores y administración empresarial. La aplicación está diseñada para optimizar los procesos de gestión de personal y control de productividad en empresas.

## 🚀 Características Principales

### 🔐 **Autenticación y Seguridad**
- Sistema de login con tokens JWT
- Autenticación de dos factores
- Gestión de permisos por roles (Administrador, Supervisor, Operador)
- Control de acceso por sucursales
- Almacenamiento seguro de credenciales

### 📊 **Dashboard y Indicadores**
- Panel de control con métricas en tiempo real
- Indicadores de productividad y rendimiento
- Estadísticas de colaboradores activos/inactivos
- Análisis de horas trabajadas vs esperadas
- Reportes de horas extras y bonificaciones

### 👥 **Gestión de Colaboradores**
- Registro y edición de colaboradores
- Control de estados (Activo, Inactivo, Finiquitado, Pre-enrolado)
- Gestión de sueldos base
- Asignación de sucursales
- Historial de actividades

### ⏰ **Control de Horas y Tarjas**
- **Revisión de Tarjas**: Visualización y validación de tarjas
- **Aprobación de Tarjas**: Proceso de aprobación de actividades
- **Horas Trabajadas**: Control detallado de horas laborales
- **Horas Extras**: Gestión de horas extraordinarias
- **Horas Extras Otros Cecos**: Control de horas extras por centro de costo
- **Tarjas Propios**: Gestión de tarjas personales

### 🏖️ **Gestión de Ausencias**
- **Licencias**: Control de licencias médicas y administrativas
- **Vacaciones**: Gestión de períodos vacacionales
- **Permisos**: Control de permisos y ausencias

### 💰 **Gestión Financiera**
- **Sueldos Base**: Administración de sueldos base por colaborador
- **Bono Especial**: Gestión de bonificaciones especiales
- **Contratistas**: Control de trabajadores externos

### 👤 **Administración de Usuarios**
- Gestión completa de usuarios del sistema
- Asignación de permisos y roles
- Control de acceso por sucursales
- Gestión de sucursales adicionales

## 🛠️ Tecnologías Utilizadas

### **Frontend**
- **Flutter 3.2.3+** - Framework principal
- **Dart** - Lenguaje de programación
- **Provider** - Gestión de estado
- **Material Design** - Sistema de diseño

### **Backend Integration**
- **REST API** - Comunicación con backend
- **JWT Authentication** - Autenticación segura
- **HTTP Client** - Comunicación HTTP

### **Dependencias Principales**
```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.0.5          # Gestión de estado
  http: ^1.1.0              # Cliente HTTP
  shared_preferences: ^2.2.0 # Almacenamiento local
  flutter_secure_storage: ^9.0.0 # Almacenamiento seguro
  intl: ^0.20.2             # Internacionalización
  fl_chart: ^0.65.0         # Gráficos y charts
  data_table_2: ^2.5.10     # Tablas de datos
  flutter_dotenv: ^5.1.0    # Variables de entorno
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── src/
│   ├── app.dart                # Configuración principal de la app
│   ├── models/                 # Modelos de datos
│   │   ├── usuario.dart        # Modelo de usuario
│   │   ├── colaborador.dart    # Modelo de colaborador
│   │   ├── tarja.dart          # Modelo de tarja
│   │   ├── sueldo_base.dart    # Modelo de sueldo base
│   │   ├── licencia.dart       # Modelo de licencia
│   │   ├── vacacion.dart       # Modelo de vacación
│   │   ├── permiso.dart        # Modelo de permiso
│   │   ├── horas_trabajadas.dart # Modelo de horas trabajadas
│   │   ├── horas_extras.dart   # Modelo de horas extras
│   │   ├── bono_especial.dart  # Modelo de bono especial
│   │   ├── contratista.dart    # Modelo de contratista
│   │   ├── trabajador.dart     # Modelo de trabajador
│   │   └── tarja_propio.dart   # Modelo de tarja propio
│   ├── providers/              # Gestión de estado
│   │   ├── auth_provider.dart  # Provider de autenticación
│   │   ├── usuario_provider.dart # Provider de usuarios
│   │   ├── colaborador_provider.dart # Provider de colaboradores
│   │   ├── tarja_provider.dart # Provider de tarjas
│   │   ├── sueldo_base_provider.dart # Provider de sueldos base
│   │   ├── licencia_provider.dart # Provider de licencias
│   │   ├── vacacion_provider.dart # Provider de vacaciones
│   │   ├── permiso_provider.dart # Provider de permisos
│   │   ├── horas_trabajadas_provider.dart # Provider de horas trabajadas
│   │   ├── horas_extras_provider.dart # Provider de horas extras
│   │   ├── bono_especial_provider.dart # Provider de bonos especiales
│   │   ├── contratista_provider.dart # Provider de contratistas
│   │   ├── trabajador_provider.dart # Provider de trabajadores
│   │   ├── tarja_propio_provider.dart # Provider de tarjas propios
│   │   ├── theme_provider.dart # Provider de tema
│   │   ├── notification_provider.dart # Provider de notificaciones
│   │   └── sidebar_provider.dart # Provider de sidebar
│   ├── screens/                # Pantallas de la aplicación
│   │   ├── indicadores_screen.dart # Dashboard principal
│   │   ├── revision_tarjas_screen.dart # Revisión de tarjas
│   │   ├── aprobacion_tarjas_screen.dart # Aprobación de tarjas
│   │   ├── colaborador_screen.dart # Gestión de colaboradores
│   │   ├── licencias_screen.dart # Gestión de licencias
│   │   ├── vacaciones_screen.dart # Gestión de vacaciones
│   │   ├── permiso_screen.dart # Gestión de permisos
│   │   ├── horas_trabajadas_screen.dart # Control de horas trabajadas
│   │   ├── horas_extras_screen.dart # Control de horas extras
│   │   ├── horas_extras_otroscecos_screen.dart # Horas extras otros cecos
│   │   ├── bono_especial_screen.dart # Gestión de bonos especiales
│   │   ├── trabajador_screen.dart # Gestión de trabajadores
│   │   ├── contratista_screen.dart # Gestión de contratistas
│   │   ├── sueldo_base_screen.dart # Gestión de sueldos base
│   │   ├── usuario_screen.dart # Gestión de usuarios
│   │   ├── tarja_propio_screen.dart # Gestión de tarjas propios
│   │   ├── info_screen.dart # Información del sistema
│   │   └── splash_screen.dart # Pantalla de carga
│   ├── services/               # Servicios
│   │   ├── api_service.dart    # Servicio de API
│   │   ├── auth_service.dart   # Servicio de autenticación
│   │   ├── data_manager.dart   # Gestor de datos
│   │   ├── loading_manager.dart # Gestor de carga
│   │   └── weather_service.dart # Servicio de clima
│   ├── widgets/                # Widgets reutilizables
│   │   ├── master_layout.dart  # Layout principal
│   │   ├── main_scaffold.dart  # Scaffold principal
│   │   ├── global_notification.dart # Notificaciones globales
│   │   ├── session_handler_wrapper.dart # Manejador de sesión
│   │   ├── sucursal_selector.dart # Selector de sucursal
│   │   ├── user_info.dart # Información de usuario
│   │   ├── user_name_widget.dart # Widget de nombre de usuario
│   │   └── weather_widget.dart # Widget de clima
│   └── theme/                  # Temas y estilos
│       ├── app_theme.dart      # Tema principal
│       └── dark_theme_colors.dart # Colores del tema oscuro
```

## 🎯 Funcionalidades por Módulo

### 📊 **Dashboard (Indicadores)**
- Métricas de productividad en tiempo real
- Indicadores de horas trabajadas vs esperadas
- Estadísticas de colaboradores por estado
- Análisis de rendimiento por sucursal
- Gráficos interactivos de tendencias

### 👥 **Gestión de Colaboradores**
- **CRUD completo** de colaboradores
- **Estados**: Activo, Inactivo, Finiquitado, Pre-enrolado
- **Filtros avanzados** por sucursal, estado, nombre
- **Búsqueda** en tiempo real
- **Exportación** de datos
- **Gestión de sueldos** base por colaborador

### ⏰ **Control de Tarjas**
- **Revisión**: Visualización detallada de tarjas
- **Aprobación**: Proceso de validación y aprobación
- **Estados**: Pendiente, Aprobada, Rechazada
- **Filtros**: Por fecha, colaborador, estado, sucursal
- **Exportación**: Reportes en diferentes formatos

### 🏖️ **Gestión de Ausencias**
- **Licencias**: Control de licencias médicas y administrativas
- **Vacaciones**: Programación y seguimiento de vacaciones
- **Permisos**: Gestión de permisos y ausencias justificadas
- **Estados**: Programada, En curso, Completada
- **Aprobación**: Flujo de aprobación de ausencias

### 💰 **Gestión Financiera**
- **Sueldos Base**: Administración de sueldos por colaborador
- **Bonos Especiales**: Gestión de bonificaciones
- **Contratistas**: Control de trabajadores externos
- **Reportes**: Análisis financiero y reportes de costos

### 👤 **Administración de Usuarios**
- **Gestión completa** de usuarios del sistema
- **Roles**: Administrador, Supervisor, Operador
- **Permisos**: Control granular de acceso
- **Sucursales**: Asignación de sucursales adicionales
- **Seguridad**: Control de acceso y autenticación

## 🔧 Configuración y Despliegue

### **Requisitos del Sistema**
- Flutter SDK 3.2.3 o superior
- Dart 3.2.3 o superior
- Node.js (para Firebase)
- Git

### **Instalación**
```bash
# Clonar el repositorio
git clone https://github.com/mbravot/LH_GESTION_TARJAS.git

# Navegar al directorio
cd web_lh_tarja

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run -d chrome --web-port=8080
```

### **Build para Producción**
```bash
# Build para web
flutter build web --release

# Deploy a Firebase
firebase deploy --only hosting
```

### **Variables de Entorno**
Crear archivo `.env` en la raíz del proyecto:
```env
API_BASE_URL=https://api-lh-gestion-tarjas-927498545444.us-central1.run.app
WEATHER_API_KEY=tu_api_key_aqui
```

## 🚀 Optimizaciones Implementadas

### **Rendimiento**
- **Carga bajo demanda**: Los datos se cargan solo cuando se necesitan
- **Cache inteligente**: Sistema de caché para evitar llamadas duplicadas
- **Lazy loading**: Carga diferida de componentes pesados
- **Optimización de API**: Reducción del 40-50% en llamadas duplicadas

### **UX/UI**
- **Responsive design**: Compatible con todos los dispositivos
- **Tema oscuro/claro**: Soporte para ambos modos
- **Navegación intuitiva**: Sidebar colapsible y navegación fluida
- **Filtros avanzados**: Sistema de filtros potente y flexible

### **Seguridad**
- **Autenticación JWT**: Tokens seguros para autenticación
- **Control de permisos**: Acceso granular por rol y sucursal
- **Almacenamiento seguro**: Credenciales encriptadas
- **Validación de datos**: Validación robusta en frontend y backend

## 📱 Compatibilidad

### **Navegadores Soportados**
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### **Dispositivos**
- Desktop (Windows, macOS, Linux)
- Tablet (iPad, Android tablets)
- Mobile (iOS, Android) - Responsive

## 🔗 URLs de Acceso

- **Producción**: https://gestion-la-hornilla.web.app
- **Firebase Console**: https://console.firebase.google.com/project/gestion-la-hornilla/overview
- **GitHub**: https://github.com/mbravot/LH_GESTION_TARJAS

## 📞 Soporte y Contacto

Para soporte técnico o consultas sobre el sistema:
- **Email**: soporte@lh-gestion.com
- **Teléfono**: +56 9 1234 5678
- **Horario**: Lunes a Viernes, 9:00 - 18:00

## 📄 Licencia

Este proyecto es propiedad de La Hornilla y está destinado para uso interno de la empresa.

---

**Versión**: 1.0.0+1  
**Última actualización**: Diciembre 2024  
**Desarrollado por**: Equipo de Desarrollo LH