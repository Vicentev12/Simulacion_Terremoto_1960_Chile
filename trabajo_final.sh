#!/bin/bash

# TRABAJO FINAL DGE 
# Nombre: Vicente Valenzuela Carrasco


# Definimos variables con anterioridad para el desarrollo del script, con esto facilitamos un poco el trabajo:
region="282/289/-46.5/-36.5"
path="/home/vicente/Escritorio/DGE/Trabajo_Final/data"
proyeccion="C10c"
topo_bati="bahia.grd"
salida="grilla_salida.grd"

# Creamos una paleta de colores de tal manera que se puedan distinguir facilmente las bajas y altas alturas, por ello en esta definimos el rango de valores entre -10 a 10 para las alturas del tsunami (en metros) con su respectiva resolución de 0.02 como intervalo entre los valores de la paleta:

gmt makecpt -Cblack,darkblue,blue,0/128/255,white,yellow,orange,red,darkred -T-10/10/0.02 -D -Z > paleta.cpt


# El comando -Z en la línea anterior transforma una paleta discreta a una continua, respetando los parámetros de esta. Por lo tanto, para generar una paleta discreta, basta con remover el comando -Z de la línea del gmt makecpt, para que con ello (por defecto) obtengamos una paleta discreta, tal como sería en la siguiente línea:

# gmt makecpt -Cblack,darkblue,blue,0/128/255,white,yellow,orange,red,darkred -T-10/10/0.02 -D > paleta.cpt

# Nos dirigimos a una carpeta llamada "data", en la cual se encuentran los archivos correspondientes a las alturas del tsunami en formato .xyz:

cd data/

# Descargamos una grilla de topografía y batimetría que encierre la región en la que trabajamos, para luego obtener el gradiente de esta y con ello la iluminación que le daremos tanto a la batimetría como topografía, todo esto con una resolución de 0.5m (arco minutos).

# Con el comando grdcut recortamos una región en específico y creamos una grilla de salida (.grd)
gmt grdcut $topo_bati -G$salida -R$region -V
# Con el comando grdgradient se calcula el gradiente de la grilla (intensidad de la pendiente de la grilla) definida con respecto a un cierto ángulo de azimut (45°), para con ello lograr el efecto de sombreado e iluminado en el mapa. Todo esto generando un archivo de iluminación .int:
gmt grdgradient $salida -Ggradiente.int -A45 -Nt
# Con grdsample redefinimos la resolución para la iluminación (.int), la cual haremos coincidir con la de alturas de tsunami
gmt grdsample gradiente.int -Ggrad_interp.int -R$region -I0.5m -V



# Luego, a partir de los archivos .xyz almacenados en la carpeta "data" creamos archivos de grilla .grd con el comando gmt surface, especificando una resolución de 0.5m (arco minutos), lo cual se modifica con gmt grdsample para obtener la misma que para la iluminación, para así no tener problemas a la hora de generar los mapas. Todo esto dentro de un ciclo for para abarcar así la totalidad de los archivos de manera automatica:
for n in $(seq -w 000000 000060 003600)
do
gmt surface z_$n.xyz -R$region -I0.5m -Gdata_$n.grd
gmt grdsample data_$n.grd -Ggrilla_$n.grd -R$region -I0.5m -V 
done

# Una vez finalizado este proceso, salimos de la carpeta "data" y volvemos a la original utilizando el comando cd ..:

cd ..

# Ahora, automatizamos el resto de los procesos dentro de un ciclo for, par así generar todos los mapas necesarios y sus modificaciones (se utiliza -w en la secuencia para que el ciclo respete los 6 dígitos):

for n in $(seq -w 000000 000060 003600)
do
# Definimos la variable "min" para pasar de segundos a minutos, y con ello poder insertar un texto que nos indique la cantidad de miutos transcurridos
min=$(echo  $n/60 | bc) 
# Utilizamos el comando if para especificar que para el minuto 0, es decir la primera imagen que obtendremos, nos demarque los contornos para las alturas del tsunami.
if [ $n -eq 000000 ]

then
# Generamos el primer mapa utilizando el comando grdimage, especificando tanto la grilla como la proyección, región, paleta e iluminación:
gmt grdimage $path/grilla_$n.grd -J$proyeccion -R$region -I$path/grad_interp.int -Cpaleta.cpt -Ba1f1/a1f1 -P -K -Y5 -X6 > data_$n.ps
# Utilizamos el comando pscoast para demarcar las líneas de costa en el mapa, especificando la misma región y proyección anterior:
gmt pscoast -J$proyeccion -R$region -W0.5p -A5 -Df -O -K >> data_$n.ps
# Uitlizamos el comando psscale para mostrar la paleta de colores creada anteriormente, la que incluiremos especificando tanto la posición como las unidades, esto con -D y -B:
gmt psscale -Cpaleta.cpt -Dx0c/-2.0c+w10c/1.0c+h+e -Bx2 -By+l"[m]" -O -K>> data_$n.ps
# Utilizamos el comando grdcountour para mostrar los contornos de las alturas para el minuto 0, con ello también especificamos la grilla, proyección y los límites con los cuales se mostrarán en el mapa (-L). Se utiliza el comando 2 veces para definir límites inferiores y superiores para valores negativos y positivos:
gmt grdcontour $path/grilla_$n.grd -J$proyeccion -C1 -L-4/-0.5 -V -P -B1 -O -K>>data_$n.ps
gmt grdcontour $path/grilla_$n.grd -J$proyeccion -C1 -L0.5/5 -V -P -B1 -O -K>>data_$n.ps

# A continuación agregamos todo el texto necesario para incluir un título a los mapas y especificar los minutos transcurridos desde el momento de inicio del tsunami (minuto 0), esto utilizando los comandos pstext y psxy:
# título:
echo -78.2 -35 "Alturas Tsunami 1960 (Valdivia, Chile)"| gmt pstext -J -R -P -V -F+f18p,Helvetica,black+jLM -O -K -N >> data_$n.ps
# Minutos transcurridos utilizando la variable "min" calculada anteriormente:
echo -75.5 -35.6 "$min minutos"| gmt pstext -J -R -P -V -F+f18p,Helvetica,black+jLM -O -K -N >> data_$n.ps

# Luego, incluimos una serie de ciudades cercanas a la costa utilizando los comandos pstext y psxy, además de especificar la posición y el nombre de cada ciudad con una marca en el mapa, marcando a la ciudad de Valdivia con una estrella:  
echo -73.2458 -39.8139 | gmt psxy -J$proyeccion -R -Sa0.5 -W0.5,0/0/0 -Gred -V -K -O >> data_$n.ps
echo -73 -39.8139 "Valdivia" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.3956 -38.2975 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.1 -38.2975 "Tirúa" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K>> data_$n.ps

echo -73.6667 -37.6 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.5 -37.6 "Lebu" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.1667 -39.4333 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -72.95 -39.4333 "Mehuín" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.7667 -40.55 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.6 -40.55 "Bahía Mansa" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.8333 -41.8667 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.85 -42.1 "Ancud" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K>> data_$n.ps

echo -74.0667 -42.6333 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.9 -42.6333 "Cucao" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.5961 -43.0992 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.4 -43.0992 "Quellón" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K>> data_$n.ps

echo -75.0833 -44.85  | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -74.9 -44.85 "Isla Guamblin" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.13049 -41.77338 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -72.9 -41.77338 "Calbuco" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.7522 -43.8975 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.6 -43.8975 "Melinka" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps


# Ahora, generamos un indent map especificando la región de estudio con respecto a sudamerica, demarcando a Chile con un color diferente al resto del continente y encerrando en un cuadro rojo la zona específica del estudio:

# Para ello graficamos un mapa pequeño delimitado por la proyección -JM1.2i con el comando pscoast y pintamos el continente de un golor negro sólido (-Gblack), además dejamos el océano transparente para no interferir con lo que queremos visualizar en el mapa principal (no incluimos -S). Por otro lado, posicionamos el inserto de tal manera que no interfiera con la visualización del mapa principal, es decir, posicionándolo en la esquina superior izquierda.
gmt pscoast -R-82/-34/-58/14.5 -JM1.2i -ECL+ggreen -X0.4 -Y12 -Df -A10000 -W1,0 -Gblack -O -P -K >> data_$n.ps
# Utilizaos el comando psxy para trazar las líneas que encerrarán la región de estudio que estamos graficando en el mapa principal con respecto al continente sudamericano, esto siempre y cuando se respete tanto la región como proyección en el comando anterior de pscoast, sino el cuadro que crearemos se acoplará al mapa principal:
gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O -K << END >> data_$n.ps #Linea horizontal
-78 -36.5
-71 -36.5
END

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O -K << END >> data_$n.ps #Linea horizontal
-78 -46.5
-71 -46.5
END

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O -K << END >> data_$n.ps #linea vertical
-78 -36.5
-78 -46.5
END

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O << END >> data_$n.ps #Linea vertical
-71 -36.5
-71 -46.5
END

else

# Ahora, tal como se realizó para el mapa del minuto 0, se siguen los mismos pasos para generar el resto de los mapas, con la única diferencia que ahora se incluirán el resto de los mapas hasta el minuto 60 y  sin considerar los contornos para las alturas del tsunami, tal como se desarrolla a continuación

gmt grdimage $path/grilla_$n.grd -J$proyeccion -R$region -I$path/grad_interp.int -Cpaleta.cpt -Ba1f1/a1f1 -P -K -Y5 -X6 > data_$n.ps

gmt pscoast -J$proyeccion -R$region -W0.5p -Df -A5 -O -K >> data_$n.ps

gmt psscale -Cpaleta.cpt -Dx0c/-2.0c+w10c/1.0c+h+e -Bx2 -By+l"[m]" -O -K >> data_$n.ps


echo -78.2 -35 "Alturas Tsunami 1960 (Valdivia, Chile)"| gmt pstext -J -R -P -V -F+f18p,Helvetica,black+jLM -O -K -N >> data_$n.ps

echo -75.5 -35.6 "$min minutos"| gmt pstext -J -R -P -V -F+f18p,Helvetica,black+jLM -O -K -N >> data_$n.ps

echo -73.2458 -39.8139 | gmt psxy -J$proyeccion -R -Sa0.5 -W0.5,0/0/0 -Gred -V -K -O >> data_$n.ps
echo -73 -39.8139 "Valdivia" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.3956 -38.2975 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.1 -38.2975 "Tirúa" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K>> data_$n.ps

echo -73.6667 -37.6 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.5 -37.6 "Lebu" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.1667 -39.4333 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -72.95 -39.4333 "Mehuín" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.7667 -40.55 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.6 -40.55 "Bahía Mansa" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.8333 -41.8667 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.85 -42.1 "Ancud" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K>> data_$n.ps

echo -74.0667 -42.6333 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.9 -42.6333 "Cucao" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.5961 -43.0992 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.4 -43.0992 "Quellón" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K>> data_$n.ps

echo -75.0833 -44.85  | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -74.9 -44.85 "Isla Guamblin" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.13049 -41.77338 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -72.9 -41.77338 "Calbuco" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

echo -73.7522 -43.8975 | gmt psxy -J$proyeccion -R -Sc0.3 -W0.3,0/0/0 -G0/255/255 -V -K -O >> data_$n.ps
echo -73.6 -43.8975 "Melinka" | gmt pstext -J -R -P -V -F+f12p,Helvetica,black+jLM -Gwhite -O -K >> data_$n.ps

gmt pscoast -R-82/-34/-58/14.5 -JM1.2i -ECL+ggreen -X0.4 -Y12 -Df -A10000 -W1,0 -Gblack -O -P -K >> data_$n.ps

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O -K << END >> data_$n.ps #Linea horizontal
-78 -36.5
-71 -36.5
END

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O -K << END >> data_$n.ps #Linea horizontal
-78 -46.5
-71 -46.5
END

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O -K << END >> data_$n.ps #linea vertical
-78 -36.5
-78 -46.5
END

gmt psxy -R-82/-34/-58/15 -JM1.2i -V -W1.0p,red -A -O << END >> data_$n.ps #Linea vertical
-71 -36.5
-71 -46.5
END

fi

# Una vez finalizado el condicional if, utilizamos el comando psconvert para transformar las imágenes .ps en un formato .png, para luego mover todas estas a una carpeta llamada "imagenes", la cual será la carpeta en la que almacenaremos todos los mapas para luego generar la animación:
gmt psconvert -Tg data_$n.ps

mv data_$n.png imagenes

done

# Una vez cerrado el ciclo for, nos dirigimos a la carpeta imagenes, para así utilizar ffmpeg y crear un video en formato mp4 que nos muestre la evolución del tsunami de 1960 en los primeros 60 minutos una vez iniciado:
cd imagenes/


ffmpeg -framerate 5 -pattern_type glob -i "*.png" continua.mp4

# Se generan 2 animaciones:

# Una con la utilización de una paleta de colores continua:
# ffmpeg -framerate 5 -pattern_type glob -i "*.png" continua.mp4

# Y otra con la utilización de una paleta de colores discreta (al no usar el comando -Z en el makecpt):
# ffmpeg -framerate 5 -pattern_type glob -i "*.png" discreta.mp4




