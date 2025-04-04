# Proyecto FInal

Este archivo README.md forma parte del proyecto inal de dev.f para el primer modulo, en el que elegi el tema relacionado a la banda de metal Baby metal en donde a mi página le puse "El mundo Baby Metal" porque me parecio buen titulo.


## Organización de mi página
Mi página la organice de la siguiente manera:

1. Heavy Metal | Metal (Introducción)
2. Subgéneros del metal y bandas representativas
3. ¿Quiénes son Babymetal? (Tema Principal)
4. Por qué algunos metaleros no consideran a Babymetal como metal
5. Integrantes de Babymetal
    - Banda de Apoyo (Kami Band)
    - Integrantes
6. Babymetal y su giro al género
7. Características únicas
8. Discografía destacada
9. Mis 10 canciones favoritas de Babymetal (Datos Extras mios |Video o Iframes)
10. Fotos sacadas por mí de Babymetal  (img)
11. Suscríbete para más información (Formulario)

## Caracteristicas de mi página 

En mi pagina hice uso de diferentes etiquetas como:

- `<h1>` a `<h4>` Para el correcto titulado segun su jerarquia.

- `<ul>` y `<ol>` con sus `<li>` para sus elemento.

- `<nav>` para crear una barra de navegación y dezplazarme por el contenido con un clic en donde para ser mas especifico se utilizo un `<ul>` con `style=""`para darle mejor apariencia visual con los siguientes atributos `list-style: none;` sirve para eliminar los marcadores predeterminados de la lista (•, 1., etc.) `margin: 0;` que sirve para eliminar cualquier margen externo que el navegador aplique por defecto al `<ul>`, `padding: 0;`este se asegura que los elementos `<li>` no tengan espacio adicional, `display: flex;` permite alinear y distribuir los `<li>` de manera más eficiente convirtiendo el contenedor `<ul>` en un contenedor flexible, `justify-content: center ;` Centra los `<li>` dentro de la lista `<ul>` centrando la barra de navegacion y `background-color: #444 ;` sirve para ponerle un color de fondo en la barra en este caso gris oscuro o #444.
Dentro de los `<li>` utilize `style=""`para darle mejor apariencia visual a la lista e hiciera mejor contraste visual mediante los siguiente atributos `margin: 0 15px` en este caso el 0: Define el margen superior e inferior del `<li>` como 0 píxeles (sin espacio) y el 15 px Añade un espacio horizontal (15 píxeles) entre los elementos de la lista `<li>` para separarlos visualmente, `color: white;` Cambia el color del texto del enlace a blanco y `text-decoration: none;` quita el subrayado a los enlaces dandole mejor apariencia visual.

- `<section>` para dividir el contenido y poder enlazarla con la barra de navegación`<nav>` mediante el atributo `id="identificador_seccion"`.

- `<p>` para agregar parrafos y utilice el atributo `<strong>` para poner algunas palabras en negritas y en ciertas partes del documentos como el `<footer>` le agregue como atributo `style=""` en donde utilice `text-align: center;` y `margin-top: 20px;` para ponerle un margen superior de 20 pixeles basicamente para darle un espaciado y centrar el texto.

- `<img>` para insertar imagenes mediante varios atributos `src="link"` para colocar el enlace o la fuente de donde sacara la imagen `width=""` para el ancho de la imagen `height=""` para el alto de la imagen y  `alt="descripcion de imagen"` para describir la imagen. 

- `<table>` para hacer tablas con los atributos `<thead>` para la parte superior de la tabla y `<tbody>` para definir que ira en el cuerpo de la tabla y dentro de los atributos anteriores `<tr>` para representar una fila en la tabla y `<td>` para las celdas dentro de las filas.

- `<a>` para agregar enlaces o links mediante el atributo `href="link"` y asi redirigirnos a otra página o si queremos que habra una nueva pestaña se hace  con `target="_blank"` y listo.

- `<iframe>` para agregar videos de youtube  mediante varios atributos `src="link"` para colocar el enlace o la fuente de donde sacara el video `width=""` para el ancho de la imagen `height=""` para el alto del video y  `title="descripcion de video"` para describir el video, `frameborder="0"` elimina el borde alrededor del iframe (en desuso, usa CSS). `allow="accelerometer;` `autoplay;` `clipboard-write;` `encrypted-media;` `gyroscope;` `picture-in-picture;` `web-share"` habilita permisos como accelerometer (permite usar el acelerómetro en el contenido), autoplay (reproduce video o audio automáticamente), clipboard-write (permite escribir datos en el portapapeles), encrypted-media (usa contenido protegido por DRM), gyroscope (permite el uso del giroscopio), picture-in-picture (habilita el modo de video flotante), y web-share (utiliza la API de Web Share para compartir contenido) y `referrerpolicy="strict-origin-when-cross-origin"` controla qué información de referencia se envía para proteger la privacidad. `allowfullscreen` permite que el video o contenido se vea en pantalla completa.

- `<form>` para indicar que crearemos un formulario.

- `<fieldset>` nos ayuda a  organizar visualmente los formularios y facilitar la comprensión del contenido para los usuarios y mediant sus atributo `<legend>` colocarle un nombre al formulario siempre van dentro del `<form>` tambien se pueden utilizar atributos `disabled` para desabilitarlos o `required` para hacer que los campos sean oblogatorios .

- `<select>`se utiliza para crear un menú desplegable que permite seleccionar una opción en donde `<option>` mediante su atributo `value=""` nos permite mostrar opciones predefinidas por nosotros, `<select>` tiene atrutos como `id=""` y `name=""` el primero para enlazarlo con los `<label>`y el segundo para que al momento de enviar datos mediante un boton `<button>` se nos guarde la información con ese nombre.

- `<label>`para las etiquetas de los `<input>` o `<select>` en donde el atributo`for=""` nos ayuda vincular la etiqueta para que al momento de que le demos clic a la misma se dirija directamente al `<input>` o `<select>` haciendo que el usuario siempre meta los datos en donde corresponda.

- `<input>` se utiliza para crear campos de entrada en un formulario cuenta con atributos como `type:""` en donde pueden ser del tipo text,password,email,number,checkbox,radio,date,file etc.  tambien cuenta con el atributo `id=""` para vincularlo con una etiqueta `<label>`, `placeholder:""` para poner un texto guía dentro del campo, que desaparece cuando el usuario empieza a escribir, `required` para hacer que los campos sean oblogatorios etc. entre los más destacados.

- `<footer>`para colocar un pie de página y le agregue como atributo `style=""` en donde utilice `text-align: center;` y `margin-top: 20px;` para ponerle un margen superior de 20 pixeles basicamente para darle un espaciado y centrar el texto.
---
### Estilo o Css

En esta parte debo ser sincero, me ayude de ChatGpt para el tema `CSS` o `<style>`
en donde le fui diciendo que queria en cada `<section>`, `<form>`,`<iframe>`, `<table>` etcetera,en cuanto a la página en HTML la hice toda yo, todos los fragmentos de código en que chatgpt me fue ayudando los fui comentando para saber que hacian obteniendo el siguiente código o estilo:

```
<style>
        /* Estilos generales para el cuerpo de la página */
        body {
            font-family: Arial, sans-serif; /* Define la fuente principal como Arial, con una alternativa sans-serif */
            line-height: 1.6; /* Espaciado entre líneas */
            margin: 0; /* Elimina el margen predeterminado del navegador */
            padding: 0; /* Elimina el relleno predeterminado del navegador */
            background-color: #333; /* Fondo de color gris oscuro */
            color: #333; /* Color del texto (gris oscuro, posiblemente un error) */
            text-align: justify; /* Justifica el texto */
        }

/* Estilos para el encabezado */
        header {
            background-color: #333; /* Fondo gris oscuro */
            color: white; /* Texto blanco */
            padding: 10px 20px; /* Espaciado interno en todas las direcciones */
            text-align: center; /* Centra el contenido */
        }

/* Estilos para las secciones principales */
        section {
            padding: 20px; /* Espaciado interno */
            margin: 10px auto; /* Espaciado externo y centrado */
            max-width: 800px; /* Ancho máximo del contenedor */
            background: white; /* Fondo blanco */
            border-radius: 8px; /* Bordes redondeados */
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); /* Sombra sutil */
        }

/* Estilos para las imágenes */
        img {
            display: block; /* Evita espacios debajo de las imágenes */
            margin: 10px auto; /* Centra horizontalmente y agrega margen */
            max-width: 100%; /* Ajusta el ancho máximo al contenedor */
            height: auto; /* Ajusta la altura proporcionalmente */
        }

/* Estilos para la barra de navegación */
        nav ul {
            list-style: none; /* Elimina viñetas de la lista */
            margin: 0; /* Elimina margen */
            padding: 0; /* Elimina relleno */
            display: flex; /* Flexbox para alinear los elementos horizontalmente */
            justify-content: center; /* Centra los elementos dentro del contenedor */
            background-color: #444; /* Fondo gris oscuro */
            flex-wrap: wrap; /* Permite que los elementos se envuelvan en líneas */
        }

/* Estilos para los elementos de la lista dentro de la navegación */
        nav ul li {
            margin: 5px 15px; /* Espaciado interno entre los elementos */
        }

/* Estilos para los enlaces dentro de la navegación */
        nav ul li a {
            color: white; /* Texto blanco */
            text-decoration: none; /* Elimina subrayado */
        }

/* Contenedor para tablas responsivas */
        .table-responsive {
            overflow-x: auto; /* Agrega desplazamiento horizontal si es necesario */
            -webkit-overflow-scrolling: touch; /* Mejora el desplazamiento en dispositivos táctiles */
        }

/* Estilos generales para tablas */
        table {
            width: 100%; /* Ocupa todo el ancho del contenedor */
            border-collapse: collapse; /* Combina bordes adyacentes */
            margin: 20px 0; /* Espaciado externo vertical */
            border: 1px solid #ddd; /* Borde sutil */
        }

/* Estilos para las celdas de tabla */
        th, td {
            padding: 10px; /* Espaciado interno */
            text-align: left; /* Alineación del texto a la izquierda */
            border: 1px solid #ddd; /* Bordes entre celdas */
            word-wrap: break-word; /* Permite dividir texto largo en varias líneas */
        }

/* Estilos para botones */
        button {
            background-color: #f9a825; /* Fondo amarillo */
            color: white; /* Texto blanco */
            border: none; /* Sin borde */
            padding: 10px 15px; /* Espaciado interno */
            border-radius: 5px; /* Bordes redondeados */
            cursor: pointer; /* Cambia el cursor al estilo de puntero */
        }

/* Estilos para botones al pasar el mouse */
        button:hover {
            background-color: #d6a019; /* Cambia el color de fondo en hover */
        }

/* Estilos para el pie de página */
        footer {
            text-align: center; /* Centra el texto */
            padding: 10px 20px; /* Espaciado interno */
            background: #333; /* Fondo gris oscuro */
            color: white; /* Texto blanco */
            margin-top: 20px; /* Espaciado externo superior */
        }

/* Media Queries para pantallas más pequeñas (máximo 768px de ancho) */
        @media (max-width: 768px) {
        section {
            padding: 15px; /* Reduce el espaciado interno */
            margin: 5px auto; /* Ajusta el margen externo */
        }   

        header {
            padding: 10px; /* Reduce el espaciado del encabezado */
        }

         nav ul {
            flex-direction: column; /* Cambia la navegación a orientación vertical */
            align-items: center; /* Centra los elementos verticalmente */
            }

        nav ul li {
            margin: 10px 0; /* Más espacio entre los elementos */
            }

        table, th, td {
            font-size: 14px; /* Reduce el tamaño de fuente en las tablas */
            }
        }

/* Media Queries para pantallas más pequeñas (máximo 480px de ancho) */
        @media (max-width: 480px) {
        body {
            font-size: 14px; /* Reduce el tamaño de fuente global */
        }

        header h1 {
            font-size: 20px; /* Reduce el tamaño de fuente del título */
        }

        nav ul li a {
            font-size: 14px; /* Reduce el tamaño de fuente de los enlaces */
        }

        button {
            width: 100%; /* Botones ocupan todo el ancho */
            padding: 10px; /* Ajusta el espaciado interno */
        }

        img {
            max-width: 90%; /* Reduce el ancho máximo de las imágenes */
        }

            iframe {
            max-width: 100%; /* Ajusta el ancho máximo de iframes */
            height: auto; /* Ajusta la altura proporcionalmente */
            display: block; /* Evita espacios extra */
            margin: 0 auto; /* Centra el iframe */
        }

            .responsive-iframe {
            position: relative; /* Establece un contenedor relativo */
            width: 100%; /* Ocupa todo el ancho disponible */
            padding-bottom: 56.25%; /* Mantiene la proporción 16:9 */
            height: 0; /* Altura inicial en 0 */
            overflow: hidden; /* Oculta el contenido desbordado */
        }

            .responsive-iframe iframe {
            position: absolute; /* Posiciona el iframe dentro del contenedor */
            top: 0; /* Alineación superior */
            left: 0; /* Alineación izquierda */
            width: 100%; /* Ajusta el ancho al contenedor */
            height: 100%; /* Ajusta la altura al contenedor */
        }
    }
    </style>    
```

Siendo sinceros en donde si no entendi mucho fue en la parte de los `<iframe>` y `<table>` en donde le dije que me ayudara a ajustar mi `CSS` a un diseño responsivo y que se adaptara a cualquier dispositivo, investigue vi videos pero no me funcionaban, hasta que me ayudo el gpt y me funciono, debo recalcar e insisto el documento en`hmtl` es completamente mio yo lo hice desde cero en donde me tarde aproximadamente 10 horas recabando información, repasando las etiquetas HTML y programando, en el css fue relativamente rápido en comparacion a lo que hice ya que tiene años que no hago un `css o hoja de estilo` en este caso ChatGpt me ayudo a darle un aspecto bueno aunque me llevo 3 horas aproximadamente ajustar el css a un estilo que me agradara y sobretodo entender que hacia cada una de las lineas de la seccion `<style>`.

--- 
## Comandos de Git que utilice para el Proyecto Final
Primero que nada antes de pasar con los comandos que utlice, cree una carpeta con el nombre `ProyectoFinal` usando la estructura de texto Kamelcase, posteriormente esa carpeta la abri desde `VS code`, una vez abierta la carpeta cree mi archivo `index.html` y guarde los cambios, abri la terminal desde `VS code` para inicializar git y asi poder llevar un control de versiones adecuado en donde utilice el siguiente comando :

### `git init`
Este comando lo utilice para inicializar un nuevo repositorio de Git en mi proyecto. Git crea un subdirectorio oculto `.git` en tu proyecto que contiene toda la información necesaria para el control de versiones.

**Uso:**
```bash
git init
```
**Posteriormente**
### `git add`
Este comando lo utilice para agregar los cambios realizados en mis archivos. Esto incluye nuevos archivos, cambios realizados o archivos eliminados, para que puedan ser incluidos en el siguiente commit.

**Uso:**
Para agregar un solo archivo:
```bash
git add index.html 
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
git commit -m "Creacion del archivo index.html"
```
---
Continuando con el proceso, ahora lo que hice fue ir a mi github y crear un repositorio online le puse como nombre `ProyectoFinal` una vez creado copie el enlace que me genero GitHub en mi caso `https://github.com/Raccoon0G/PreyectoFinal.git` una vez obtenido el link dle repositorio en github me dispuse a colocar el siguiente comando en la terminal de `Vs Code` :

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
git remote add origin "https://github.com/Raccoon0G/PreyectoFinal.git"
```
 
 Y volvi a comprobar que se haya guardado correctamente con  `git remote -v` y me salio esto:

 ```
origin  https://github.com/Raccoon0G/PreyectoFinal.git (fetch)
origin  https://github.com/Raccoon0G/PreyectoFinal.git (push)
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
To https://github.com/Raccoon0G/PreyectoFinal.git
   16e6c79..fb09e92  main -> main

```
Con esto fue la manera en que conecte correctamente mi repositorio local con el remoto, tambien comprobe que estuviera conectado y le envie la informacion para poder hacer el paso de `GitHub Pages`.

## Desplegar mi página en GitHub Pages

Una vez hecho lo anterior, desde inicializar `git` hasta hacer el `git push origin main`, me fui a mi repositorio de `GitHub` con el siguiente link `https://github.com/Raccoon0G/PreyectoFinal` para desplegar mi proyecto en donde hice los siguiente pasos :

1. Le di click en `settings` o ajustes.
2. Una vez en settings le di clic en la sección `Pages`.
3. Una vez en GitHub `Pages` me diriji a `Branch` en donde seleccione mi rama en mi caso `main` y le di en `Save` o guardar.
4. Ahora solo espere un momento hasta que me dio el enlace de la página que acababa de desplegar en mi caso `https://raccoon0g.github.io/PreyectoFinal/`.
5. Una vez que me dio el link solo quedaba comprobar que mi página estuviera en linea cosa que sucedio,por lo que aquí acaba la explicación para desplegar la página.

## Recursos o fuentes que utilice 

### Fuentes utilizadas para el contenido del index.html

- `[Heavy metal](https://es.wikipedia.org/wiki/Heavy_metal)`
- `[Babymetal](https://es.wikipedia.org/wiki/Babymetal)`
- `[Página oficial de Baby Metal](https://babymetal.com/mob/index.php?site=TO&ima=2050)`
- `[BABYMETAL: el fenómeno “kawaii metal” que divide al mundo del metal](https://heavymextal.com/babymetal-el-fenomeno-kawaii-metal-que-divide-al-mundo-del-metal/)`

### Fuentes de Referencia para las etiquetas HTML

- `[mdm web docs | CSS](https://developer.mozilla.org/es/docs/Web/CSS/margin)`
- `[mdm web docs | HTML](https://developer.mozilla.org/es/docs/Web/HTML/Element/input)`
- `[manz.dev | lenguajehtml.com](https://lenguajehtml.com/html/formularios/etiqueta-html-form/)`
- `[Lista de tags HTML: hoja de trucos HTML. ¿Qué son y para qué sirven?](https://es.semrush.com/blog/lista-de-html-tags/)`
- `[Etiquetas de HTML: qué son, para qué sirven y tipos principales](https://blog.hubspot.es/website/etiquetas-html)`
- `[enlace en línea](https://htmlmasters.tech/100-etiquetas-html-pdf-y-su-funcion/)`
- `[100 etiquetas de HTML y su función](http://www.limni.net)`

### Páginas que me ayudaron 

- `[Para probar el formulario](https://formsubmit.co/)`
- `[Para alojar imagenes propias en un servidor](https://es.imgbb.com/)`
- `[Para ver como se visualizaba mi página y hacer pruebas](https://html.onlineviewer.net/)`
- `[Para ver como funciona el lenguaje Markdown y poder realizar este README.md](https://dillinger.io/)`
---
### Enlace a mi Repositorio
GitHub: [Raccon0G](https://github.com/Raccoon0G/)

Enlace al repositorio de este trabajo : https://github.com/Raccoon0G/PreyectoFinal

Enlace a la página (GitHub Pages) de este trabajo : https://raccoon0g.github.io/PreyectoFinal/