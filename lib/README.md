# Trabajo Terminal  
**Prototipo de sistema web para enseñanza con recursos digitales y compartición en Facebook: caso UA Cálculo**

Este archivo `README.md` documenta el desarrollo de mi Trabajo Terminal para la **Ingeniería en Sistemas Computacionales (ESCOM-IPN)**, donde implementé un sistema web educativo enfocado en el aprendizaje colaborativo de Cálculo, permitiendo a estudiantes compartir ejercicios, materiales y participar en autoevaluaciones, todo integrado con funciones de gamificación, chat y publicación en Facebook.

---

## Organización y estructura de mi sistema

El sistema está organizado en distintas páginas y módulos principales:

1. **Inicio (Home)**  
   Página principal con bienvenida personalizada, resumen de ejercicios y materiales.

2. **Registro / Inicio de sesión**  
   Formularios para crear cuenta, login y recuperación de contraseña con verificación de correo.

3. **Perfil de usuario**  
   Visualización, edición y verificación de datos personales, cambio de contraseña y eliminación de cuenta.

4. **Contenidos**  
   Sección donde se visualizan materiales educativos clasificados por tema y tipo (PDF, videos, imágenes, enlaces, notas).

5. **Ejercicios**  
   - **Lista de ejercicios:** Filtros por tema y búsqueda avanzada.  
   - **Ver ejercicio:** Detalle de cada ejercicio, solución paso a paso en LaTeX, comentarios, calificaciones, versiones previas y compartir en Facebook.
   - **Subir ejercicio:** Formulario dinámico para redactar ejercicios y soluciones por pasos en LaTeX, con vista previa en vivo y teclado matemático personalizado.

6. **Materiales**  
   Página para subir, visualizar y descargar recursos (PDFs, videos, enlaces, imágenes, notas).

7. **Autoevaluación**  
   Módulo de preguntas generadas por IA, selección de temas, puntaje final y guardado de resultados en el sistema.

8. **Ranking**  
   Sistema de gamificación y recompensas, mostrando top de usuarios según participación y calificaciones.

9. **Chat**  
   Chat en tiempo real entre estudiantes y tutores, con reacciones, edición/eliminación, indicador de escritura y notificaciones.

10. **Notificaciones**  
    Sistema de alertas en tiempo real para mensajes, comentarios, calificaciones y logros.

---

## Características técnicas implementadas

En el desarrollo de la plataforma utilicé múltiples tecnologías y componentes de Flutter y Firebase, incluyendo:

- **Flutter Web**  
  Uso de `<MaterialApp>`, `<Scaffold>`, `<AppBar>`, `<Drawer>`, `<Column>`, `<Row>`, `<Expanded>`, widgets personalizados y responsive design.

- **Firebase**  
  - **Authentication:** Registro, login, verificación de correo y teléfono (OTP), recuperación de contraseña.
  - **Firestore:** Gestión de usuarios, ejercicios, materiales, comentarios, calificaciones, chat y notificaciones.
  - **Storage:** Almacenamiento y descarga de archivos.
  - **Cloud Functions:** Automatización de notificaciones, generación de preguntas por IA, borrado automático de usuarios no verificados.

- **LaTeX en Flutter**  
  Integración de `flutter_math_fork` para renderizar notación matemática.

- **Compartir en Facebook**  
  Integración de la dependencia de Shareplus para compartir ejercicios o materiales (tanto por captura como por enlace).

- **Gamificación**  
  Ranking, medallas, recompensas y notificaciones automáticas.

- **UI/UX Responsive**  
  Diseño responsivo, uso de Google Fonts, iconografía moderna y colores personalizados.

- **Test y debugging**  
  Pruebas manuales, estructuración modular y mensajes de confirmación visual (`AlertDialog`).

---

### Principales etiquetas, componentes y estructuras usadas

- **HTML/CSS en Flutter Web:**  
  - Jerarquía con `<h1>`–`<h4>` para títulos  
  - `<section>`, `<div>` análogos en Flutter: `Container`, `Card`, `Padding`, etc.  
  - `<img>` → `Image.network` o `Image.asset`  
  - `<table>` → `DataTable`  
  - `<form>` → `Form`, `TextFormField`, validaciones y controladores  
  - `<nav>` y barra lateral → `Drawer` y `AppBar`  
  - `<footer>` → sección fija con datos de contacto o créditos  

- **Funcionalidades extras:**  
  - Teclado matemático personalizado para LaTeX  
  - Captura de pantalla para compartir en redes  
  - Botones estilizados y con animaciones  
  - Media queries para adaptación móvil  

---

## Flujo de trabajo con Git

El ciclo básico de control de versiones y despliegue incluyó:

### Inicializar el repositorio

```bash
git init

```
**Posteriormente**
### `git add`
Este comando lo utilice para agregar los cambios realizados en mis archivos. Esto incluye nuevos archivos, cambios realizados o archivos eliminados, para que puedan ser incluidos en el siguiente commit.

**Uso:**
Para agregar un solo archivo:
```bash
git add main.dart 
git add readme.md
```
Para agregar todos los archivos:
```bash
git add .
```
En mi caso se me hace más comodo utilizae `git add .` así que utilice ese.

**Despues**
### `git commit -m "descripción del commit"`
Este comando guarda los cambios y la opción `-m` nos permite añadir un mensaje descriptivo que explique los cambios realizados.

**En mi caso el primer commit le puse así:**
```bash
git commit -m "Creacion del archivo main.dart"
```
---
Continuando con el proceso, ahora lo que hice fue ir a mi github y crear un repositorio online le puse como nombre `studyconnect` una vez creado copie el enlace que me genero GitHub en mi caso `https://github.com/Raccoon0G/PreyectoFinal.git` una vez obtenido el link dle repositorio en github me dispuse a colocar el siguiente comando en la terminal de `Vs Code` :

### `git remote -v`
Este comando se utiliza para mostrar las URL de los repositorios remotos si es que existen para el repositorio local. Lo utilice más que nada para comprobar que no halla ningun repositorio en linea guardado.

**Uso :**
```bash
git remote -v
```
**Posteriormente :**

Una vez que comprobre que no habia nada en la variable `origin` me dispuse a guardar en esa variable el link del reposistorio online que obtuvimos hace un momento `https://github.com/Raccoon0G/PreyectoFinal.git` con el siguiente comando :

### `git remote add origin "link de repositorio"`
Este comando se utiliza para añadir un nuevo repositorio remoto y vincularlo al repositorio local. Es esencial para poder usar comandos como `git push` o `git pull` con ese repositorio remoto.

**En mi caso lo use así:**
```bash
git remote add origin "https://github.com/Raccoon0G/studyconnect.git"
```
 
 Y volvi a comprobar que se haya guardado correctamente con  `git remote -v` y me salio esto:

 ```
origin  https://github.com/Raccoon0G/studyconnect.git (fetch)
origin  https://github.com/Raccoon0G/studyconnect.git (push)
 ```
 Una vez que me salio lo anterior supe que mi directorio local ya estaba vinculado con el directorio remoto de GitHub.

 Ahora faltaba enviarle la informacion a mi repositorio de GitHub por lo que utilice el siguiente comando para comprobar el nombre de la rama principal ya sea `main` o `master` en mi caso fue `main` asi qe utilice el siguiente comando :

 ### `git push`
Este comando se utiliza para enviar los commits realizados en el repositorio local al repositorio remoto, permitiendo sincronizar los cambios con otros colaboradores.

**Uso:**
```bash
git push origen rama
```
En mi caso utilice el siguiente comando :
```bash
git push origin main
```
En donde la terminal me arrojo o me desplego la siguiente información comprobando que se realizo el push correctamente:

```
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 16 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 895 bytes | 895.00 KiB/s, done.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To https://github.com/Raccoon0G/studyconnect.git
   16e6c79..fb09e92  main -> main

```
Con esto fue la manera en que conecte correctamente mi repositorio local con el remoto, tambien comprobe que estuviera conectado y le envie la informacion para poder hacer el paso de `GitHub Pages`.

## Desplegar mi página en GitHub Pages

Una vez hecho lo anterior, desde inicializar `git` hasta hacer el `git push origin main`, me fui a mi repositorio de `GitHub` con el siguiente link `https://github.com/Raccoon0G/studyconnect.git` para desplegar mi proyecto en donde hice los siguiente pasos :

1. Le di click en `settings` o ajustes.
2. Una vez en settings le di clic en la sección `Pages`.
3. Una vez en GitHub `Pages` me diriji a `Branch` en donde seleccione mi rama en mi caso `main` y le di en `Save` o guardar.
4. Ahora solo espere un momento hasta que me dio el enlace de la página que acababa de desplegar en mi caso `https://github.com/Raccoon0G/studyconnect`.
5. Una vez que me dio el link solo quedaba comprobar que mi página estuviera en linea cosa que sucedio,por lo que aquí acaba la explicación para desplegar la página.

## Recursos o fuentes que utilice 

### Fuentes utilizadas para el contenido del index.html

- `[Heavy metal](https://es.wikipedia.org/wiki/Heavy_metal)`
- `[Babymetal](https://es.wikipedia.org/wiki/Babymetal)`
- `[Página oficial de Baby Metal](https://babymetal.com/mob/index.php?site=TO&ima=2050)`
- `[BABYMETAL: el fenómeno “kawaii metal” que divide al mundo del metal](https://heavymextal.com/babymetal-el-fenomeno-kawaii-metal-que-divide-al-mundo-del-metal/)`

### Fuentes de Referencia para las etiquetas HTML

- `[Documentación oficial de Flutter:](https://flutter.dev/)`
- `[Documentación Firebase:](https://firebase.google.com/docs)`
- `[FlutterFire:](https://firebase.flutter.dev/)`


### Recursos para desarrollo

- `[Para ver como funciona el lenguaje Markdown y poder realizar este README.md](https://dillinger.io/)`


---
### Enlace a mi Repositorio

El desarrollo de este proyecto implicó la integración de múltiples tecnologías modernas y el análisis de necesidades reales de estudiantes de Cálculo.
A través de la combinación de Flutter Web, Firebase y APIs externas, logré crear un entorno interactivo, colaborativo y adaptable para el aprendizaje, reforzando mis conocimientos en ingeniería de software, bases de datos y diseño responsivo.

Este sistema busca ser una referencia para el desarrollo de soluciones educativas accesibles, escalables y fáciles de compartir.
---
### Enlace a mi Repositorio
GitHub: [Raccon0G](https://github.com/Raccoon0G/)

Enlace al repositorio de este trabajo : https://github.com/Raccoon0G/studyconnect

Enlace a la página (GitHub Pages) de este trabajo : 