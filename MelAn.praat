#########################################################################################

#  MelAn                                          			  							#

#  AUTHOR: Juan María Garrido Almiñana													#
#  VERSION: 3.0 (10/10/2017)															#

# Script to label the F0 contour of a wav file with tonal events labels					#

# The script needs as input:															#
#	- a directory containing the wav files of the input utterances						#
#	- a directory containing the TextGrid files 										#

# Wav and TextGrid files of the same utterance have to have the same name				#

# Input TextGrid flies must include five tiers containing:								#
#	- phonetic transcription (SAMPA or IPA) aligned with the signal						#

#	- syllable segmentation, with indication of stressed syllables						#

#	- stress group segmentation															#

#	- intonation group segmentation														#

#	- breath group segmentation															#

# The script adds to every input TextGrid file											#
# three tiers containing:																#
#	- the F0 values of the inflection points in the stylised F0 contour					#
#	  time-aligned with the speech wave													#
#	- the tonal labels, time-aligned with the speech wave								#
#	- the pattern labels																#

# Arguments: 																			#
# 1) Input wav file																		#
# 2) Directory of the wav file															#
# 3) Input TextGrid file, containing orthographic and phonetic transcription			#
# 4) Directory of the TextGrid file														#											
# 5) Output directory																	#
# 6) Number of tier containing phonetic transcription in the input TextGrid				#
# 7) Number of tier containing syllable segmentation in the input TextGrid				#
# 8) Number of tier containing stress group segmentation in the input TextGrid			#
# 9) Number of tier containing intonation group segmentation in the input TextGrid		#
# 10) Number of tier containing breath group segmentation in the input TextGrid			#
# 11) Phonetic alphabet of the input phonetic transcription								#
# 12) Pause label in the input TextGrid 												#


#  Copyright (C) 2017  Juan María Garrido Almiñana                       	 			#
#                                                                        				#
#    This program is free software: you can redistribute it and/or modify 				#
#    it under the terms of the GNU General Public License as published by 				#
#    the Free Software Foundation, either version 3 of the License, or    				#
#    (at your option) any later version.                                  				#
#                                                                         				#
#    This program is distributed in the hope that it will be useful,      				#
#    but WITHOUT ANY WARRANTY; without even the implied warranty of       				#
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       				#
#    GNU General Public License for more details.                         				#
#                                                                         				#
#    See http://www.gnu.org/licenses/ for more details.                   				#

#########################################################################################


form Argumentos
	sentence Fichero_wav iff_a1001_001.wav
	sentence Directorio_wav /Users/juanma/Dropbox/trabajo/MelAn_3.0/Ficheros_prueba/
	sentence Fichero_textgrid iff_a1001_001.TextGrid
	sentence Directorio_textgrid /Users/juanma/Dropbox/trabajo/MelAn_3.0/Ficheros_prueba/
	sentence Directorio_salida /Users/juanma/Dropbox/trabajo/MelAn_3.0/Pruebas/
	positive Tier_transcripcion_fonetica 2
	positive Tier_silabas 3
	positive Tier_grupos_acentuales 4
	positive Tier_grupos_entonativos 5
	positive Tier_grupos_fonicos 6
	sentence Alfabeto_fonetico SAMPA
	sentence Etiqueta_pausa P
endform
	
# Lee el Sonido

nombre_completo_fichero_entrada$ = directorio_wav$+"/"+fichero_wav$

if fileReadable (nombre_completo_fichero_entrada$)

	Read from file... 'nombre_completo_fichero_entrada$'
	nombre_sonido$ = selected$ ("Sound")
	sound = selected ("Sound")

	nombre_completo_fichero_textgrid$ = directorio_textgrid$+"/"+fichero_textgrid$

	printline Processing 'nombre_completo_fichero_textgrid$'...

	# Lee el TextGrid

	if fileReadable (nombre_completo_fichero_textgrid$)
		Read from file... 'nombre_completo_fichero_textgrid$'
	
		textgrid = selected ("TextGrid")


		#### Se estima la F0 del fichero de entrada

		#printline Calculamos la F0...
		#printline Estimamos la F0 global de 'fichero_wav$' ...

		call estima_f0_praat_comando sound 0.0 50.0 600.0 1

		#printline Estimamos la F0 por grupos fonicos de 'fichero_wav$' ...

		call estima_f0_praat_GF_comando sound textgrid 'tier_grupos_entonativos' 0.0 50.0 600.0 1


		#### Estilizamos los contornos de F0

		#printline Estilizamos los contornos de F0...

		call estiliza_f0_praat_por_GF_comando sound textgrid "Semitones" 1 1 10 'tier_grupos_entonativos' 


		#Calculamos ahora las pendientes globales de F0

		#printline Calculamos las pendientes globales de F0...

		select textgrid

		num_intervalos = Get number of intervals... 'tier_grupos_entonativos' 
		#printline Num intervalos: 'num_intervalos'

		for cont_intervalos from 1 to num_intervalos

			#printline Intervalo: 'cont_intervalos'

			tekst$ = Get label of interval...  'tier_grupos_entonativos'  cont_intervalos
			#printline Etiqueta intervalo: 'tekst$'
			if tekst$ <> etiqueta_pausa$
			
				texto_cont_intervalos$ = fixed$ (cont_intervalos, 0)
				nombre_objeto_pitch$ = nombre_sonido$+"_"+texto_cont_intervalos$

				#printline Nombre objeto pitch: 'nombre_objeto_pitch$'
			
				call crea_tabla_de_objeto_pitch_GF_comando 'nombre_objeto_pitch$' Semitones

				tabla_f0$=nombre_objeto_pitch$
				call calcula_regresion_lineal 'tabla_f0$'
				
				select textgrid

			endif

		endfor

		#Separamos los valores estilizados en P y V

		#printline Separamos los valores estilizados en P y V...

		call etiqueta_est_P_V_por_GF_con_pendiente_GF_juanma_comando textgrid 'tier_grupos_entonativos'  'tier_grupos_fonicos'+1 Semitones

		
		#Calculamos ahora las pendientes P y V

		#printline Calculamos las pendientes P y V...

		#printline Procesamos 'fichero_wav$'...

		call crea_tablas_P_V_de_pitch_GF_anotado_comando textgrid 'tier_grupos_fonicos'+1 'tier_grupos_fonicos'+2 'tier_grupos_entonativos'


		for cont_intervalos from 1 to num_intervalos

			#printline Intervalo: 'cont_intervalos'
			
			select textgrid

			tekst$ = Get label of interval... 'tier_grupos_entonativos' cont_intervalos
			#printline Etiqueta intervalo: 'tekst$'
			if tekst$ <> etiqueta_pausa$
			
				texto_cont_intervalos$ = fixed$ (cont_intervalos, 0)

				nombre_tabla_P$ =nombre_sonido$+"_"+texto_cont_intervalos$+"_tablaF0_P"
				call calcula_regresion_lineal 'nombre_tabla_P$'

				nombre_tabla_V$=nombre_sonido$+"_"+texto_cont_intervalos$+"_tablaF0_V"
				call calcula_regresion_lineal 'nombre_tabla_V$'

			endif
			
		endfor


		#Anyadimos ahora las etiquetas P+ y V-

		#printline Identificamos ahora los puntos P+ y V-...

		call anota_f0_P+_V- textgrid 'tier_grupos_entonativos'  'tier_grupos_fonicos'+1 'tier_grupos_fonicos'+2

		
		#Finalmente, simplificamos la anotacion

		#printline Simplificamos la anotacion...

		call simplifica_anotacion textgrid 'tier_grupos_entonativos' 'tier_grupos_fonicos'+3


		#Calculamos de nuevo las pendientes P y V

		#printline Calculamos las pendientes P y V...

		#printline Procesamos 'fichero_wav$'...

		call crea_tablas_P_V_de_pitch_GF_anotado_comando textgrid 'tier_grupos_fonicos'+1 'tier_grupos_fonicos'+4 'tier_grupos_entonativos'

		for cont_intervalos from 1 to num_intervalos

			#printline Intervalo: 'cont_intervalos'
			
			select textgrid

			tekst$ = Get label of interval... 'tier_grupos_entonativos' cont_intervalos
			#printline Etiqueta intervalo: 'tekst$'
			if tekst$ <> etiqueta_pausa$
			
				texto_cont_intervalos$ = fixed$ (cont_intervalos, 0)

				nombre_tabla_P$ =nombre_sonido$+"_"+texto_cont_intervalos$+"_tablaF0_P"
				call calcula_regresion_lineal 'nombre_tabla_P$'

				nombre_tabla_V$=nombre_sonido$+"_"+texto_cont_intervalos$+"_tablaF0_V"
				call calcula_regresion_lineal 'nombre_tabla_V$'

			endif
			
		endfor

		#Creamos el fichero de salida

		#printline Creamos la tabla con los valores de las rectas de F0...

		call crea_tabla_val_lineas_ref_GF textgrid 'tier_grupos_entonativos' 'etiqueta_pausa$'


	
		#Creamos un tier con los patrones

		call anota_patrones textgrid 'tier_grupos_fonicos'+1 'tier_grupos_fonicos'+4 'tier_grupos_acentuales' 'tier_transcripcion_fonetica' 'tier_silabas' 'tier_grupos_entonativos' 'alfabeto_fonetico$'

		#Quitamos los tiers que sobran

		select textgrid
		Remove tier... 'tier_grupos_fonicos'+3
		Remove tier... 'tier_grupos_fonicos'+2


		#Guardamos el textgrid de salida en un fichero

		nombre_completo_textgrid_salida$ = directorio_salida$+"/"+fichero_textgrid$
		Write to text file... 'nombre_completo_textgrid_salida$'

		printline MelAn completed

	else

		printline No es posible abrir el fichero 'nombre_completo_fichero_textgrid$'
		select sound
		Remove

	endif


else
	printline No es posible abrir el fichero 'nombre_completo_fichero_entrada$'

endif


procedure estima_f0_praat_comando mySound time_step pitch_floor pitch_ceiling f0_range

	select mySound
	sound$ = selected$ ("Sound")
	
	To Pitch... time_step pitch_floor pitch_ceiling

	first_pitch = selected ("Pitch")

	min = Get minimum... 0 0 Hertz None
	min = round(min)
	max = Get maximum... 0 0 Hertz None
	max = round(max)
	q1 = Get quantile... 0 0 0.25 Hertz
	q1 = floor(q1)
	q3 = Get quantile... 0 0 0.75 Hertz
	q3 = ceiling(q3)
	# Round floor and ceiling values to the nearest 10 Hz
	pitch_floor = round((0.7*q1)/10)*10
	if f0_range = 1
		pitch_ceiling = round((1.5*q3)/10)*10
	else
		pitch_ceiling = round((2.5*q3)/10)*10
	endif
				
	select first_pitch
	Remove

	select mySound

	To Pitch... time_step pitch_floor pitch_ceiling
	#nombre_objeto_pitch$ = "sound" + " pitch"
	#nombre_objeto_pitch$ = "soundpitch"
	nombre_objeto_pitch$ = sound$
	Rename... 'nombre_objeto_pitch$'

endproc

procedure estima_f0_praat_GF_comando mySound myTextGrid pauses_tier time_step pitch_floor pitch_ceiling F0_range

# Creado por Juanma el 10.07.2007
# Script para caModificolcular el F0 de un objeto Sound por el metodo Praat
# Esta preparado para ser ejecutado desde linea de comandos

# The 'Range' option provided lets the user select between the two constant values (1.5 or 2.5).

	select mySound
	nombre_sonido$ = selected$ ("Sound")
	sonido_prov = selected ("Sound")

	select myTextGrid

	textgrid = selected ("TextGrid")

	num_intervalos = Get number of intervals... pauses_tier


	for cont_intervalos from 1 to num_intervalos

		#printline Numero intervalo: 'cont_intervalos'

		tekst$ = Get label of interval... 'pauses_tier' cont_intervalos
		if tekst$ <> etiqueta_pausa$
			t1 = Get starting point... 'pauses_tier' cont_intervalos
			t2 = Get end point... 'pauses_tier' cont_intervalos
			select sonido_prov
			Extract part... t1 t2 Rectangular 1 yes
			extracto_sonido = selected ("Sound")


		# Ahora calculamos el contorno de F0

			To Pitch... time_step pitch_floor pitch_ceiling

		# Juanma. 4.4.2013. Introduzco una modificacion para recalcular los limites superior e inferior para la estimacion de F0

			first_pitch = selected ("Pitch")
			min = Get minimum... 0 0 Hertz None
			min = round(min)
			max = Get maximum... 0 0 Hertz None
			max = round(max)
			q1 = Get quantile... 0 0 0.25 Hertz
			q1 = floor(q1)
			q3 = Get quantile... 0 0 0.75 Hertz
			q3 = ceiling(q3)
			# Round floor and ceiling values to the nearest 10 Hz
			pitch_floor = round((0.7*q1)/10)*10
			
			if (pitch_floor = undefined) or (pitch_floor < 50)
				pitch_floor = 50
			endif

			if f0_range = 1
				pitch_ceiling = round((1.5*q3)/10)*10
			else
				pitch_ceiling = round((2.5*q3)/10)*10
			endif

			if (pitch_ceiling = undefined) or (pitch_ceiling > 800)
				pitch_ceiling = 800
			endif

			#printline Pitch foor 'pitch_floor'
			#printline Pitch ceiling 'pitch_ceiling'
			
			select first_pitch
			Remove

			select extracto_sonido

			To Pitch... time_step pitch_floor pitch_ceiling
			pitch_prov = selected ("Pitch")

			texto_intervalo$ = fixed$('cont_intervalos', 0)
			#printline 'texto_intervalo$'
			nombre_completo_objeto_pitch$ = nombre_sonido$+"_"+texto_intervalo$
			#nombre_completo_objeto_pitch$ = "sound_pitch_"+texto_intervalo$

			Rename... 'nombre_completo_objeto_pitch$'

		# Hacemos un poco de limpieza

			select extracto_sonido
			Remove

			select textgrid

		endif

	endfor
	

endproc



procedure estiliza_f0_praat_por_GF_comando sound textgrid units$ threshold_value smoothing smoothing_value pauses_tier

	#printline He entrado en estiliza_f0_por_comando

	select sound
	nombre_sonido$ = selected$ ("Sound")

	# Scale times

	#Creamos el TextGrid

	duracion = Get duration
	Create TextGrid... 0.0 duracion "InflectionPoints" InflectionPoints
	textgrid_estilizacion = selected ("TextGrid")


	Create PitchTier... "InflectionPoints" 0.0 duracion
	pitchtier_estilizacion = selected ("PitchTier")

	select textgrid

	num_intervalos = Get number of intervals... pauses_tier
	#printline Num intervalos: 'num_intervalos'

	tiempo_punto_anterior = 0

	for cont_intervalos from 1 to num_intervalos

		#printline Intervalo: 'cont_intervalos'

		tekst$ = Get label of interval... 'pauses_tier' cont_intervalos
		#printline Etiqueta intervalo: 'tekst$'
		if tekst$ <> etiqueta_pausa$
			t1 = Get starting point... 'pauses_tier' cont_intervalos
			t2 = Get end point... 'pauses_tier' cont_intervalos
			select sound
			#printline extraigo la parte del sonido del intervalo 'cont_intervalos'
			Extract part... t1 t2 Rectangular 1 yes
			extracto_sonido = selected ("Sound")

			# Ahora calculamos el contorno de F0 y lo alisamos, si se ha escogido esa opcion

			#printline Empiezo la estilizacion del intervalo 'cont_intervalos'

			texto_cont_intervalos$ = fixed$ (cont_intervalos, 0)

			#nombre_objeto_pitch$ = nombre_sonido$+" "+texto_cont_intervalos$+" pitch"
			nombre_objeto_pitch$ = "Pitch "+nombre_sonido$+"_"+texto_cont_intervalos$
			
			#printline Nombre objeto pitch: 'nombre_objeto_pitch$'

			select 'nombre_objeto_pitch$'

			if smoothing = 1
				Smooth... 'smoothing_value'
				pitch_alisado = selected ("Pitch")
			endif

#				Interpolate
#				pitch_interpolado = selected ("Pitch")

			# Creamos la estilizaciÛn

			Down to PitchTier
			pitchtier = selected ("PitchTier")

			Stylize... threshold_value 'units$'
	

			pitchtier_est_prov = selected ("PitchTier")

			num_puntos = Get number of points


			for cont_puntos from 1 to num_puntos

				valor_punto = Get value at index... cont_puntos
				tiempo_punto = Get time from index... cont_puntos

				if tiempo_punto > tiempo_punto_anterior
					select 'textgrid_estilizacion'
					Insert point... 1 'tiempo_punto' 'valor_punto:0'
					select 'pitchtier_estilizacion'
					Add point... 'tiempo_punto' 'valor_punto:0'
				endif

				select pitchtier_est_prov

				tiempo_punto_anterior = 'tiempo_punto'

			endfor

		# Hacemos un poco de limpieza

			select extracto_sonido
			plus pitch_alisado
#			plus pitch_interpolado
			plus pitchtier
			plus pitchtier_est_prov
			Remove

			select textgrid

		endif

	endfor

	# Unimos los textgrid en uno solo

	#printline Unimos los textgrid
	select textgrid
	name$ = selected$ ("TextGrid")
	textgrid_old = selected ("TextGrid")

	plus 'textgrid_estilizacion'
	Merge
	Rename... 'name$'
	textgrid = selected ("TextGrid")

	select 'textgrid_estilizacion'
	plus pitchtier_estilizacion
	plus textgrid_old
	Remove


	#printline Salgo del script de estilizacion

endproc

procedure etiqueta_est_P_V_por_GF_con_pendiente_GF_juanma_comando textgrid_entrada tier_intonation_groups tier_stylization unit$

	#printline Unidad: 'unit$'

	#printline 'nombre_completo_fichero_textgrid$'

	select textgrid_entrada


	#textgrid = selected ("TextGrid")


	# Añadimos el correspondiente Tier al TextGrid

	select textgrid_entrada

	duracion = Get duration

	Create TextGrid... 0.0 duracion "EtiquetadoPV" EtiquetadoPV

	textgrid_etiquetado = selected ("TextGrid")

	select textgrid_entrada

	# Empezamos con el etiquetado

	num_intervalos = Get number of intervals... tier_intonation_groups

	for cont_intervalos from 1 to num_intervalos

		select textgrid_entrada

		tekst$ = Get label of interval... 'tier_intonation_groups' cont_intervalos
			
		# printline valor tekst 'tekst$'

		if tekst$ <> etiqueta_pausa$

			numero_intervalo$ = fixed$ (cont_intervalos, 0)
			nombre_fichero_pitch$=nombre_sonido$+"_"+numero_intervalo$

			#printline 'nombre_fichero_pitch$'

			select Pitch 'nombre_fichero_pitch$'

			pitch = selected ("Pitch")

			nombre_tabla_regresion$ = nombre_fichero_pitch$ + "_regression"
			
			#printline 'nombre_completo_fichero_tabla$'

			#select LinearRegression 'nombre_tabla_regresion$'
			select Table 'nombre_tabla_regresion$'

			#Read Table from table file... 'nombre_completo_fichero_tabla$'
			#Read Strings from raw text file... 'nombre_completo_fichero_tabla$'
			#tabla = selected ("LinearRegression")
			#tabla = selected ("Strings")
			tabla = selected ("Table")

			
			#info$ = Info

			#printline He leido correctamente la tabla 'nombre_completo_fichero_tabla$'

			# Leemos de la tabla los valores del valor inicial y la pendiente

			valor_inicial = Get value... 1 Valor_inicial
			#valor_inicial = Get string... 2
			#valor_inicial = extractNumber (info$, "Intercept: ")

			valor_pendiente = Get value... 1 Pendiente
			#valor_pendiente = Get string... 3
			#valor_pendiente = extractNumber (info$, "Coefficient of factor Time: ")
		
			#printline valor pendiente 'valor_pendiente'
			#printline valor inicial 'valor_inicial'

			select textgrid_entrada

			t1 = Get starting point... 'tier_intonation_groups' cont_intervalos
			t2 = Get end point... 'tier_intonation_groups' cont_intervalos
		
			num_puntos = Get number of points... tier_stylization

			for cont_puntos from 1 to num_puntos

				tiempo_punto = Get time of point... 'tier_stylization' cont_puntos
				valor_punto = Get label of point... 'tier_stylization' cont_puntos
				# printline 'valor_punto'
				# printline 'valor_p'
				# printline 'valor_m'


				# Asignamos los valores para M. Metodo pendiente

				if unit$ = "Semitones"
					#printline La unidad es semitonos

					valor_punto_st = hertzToSemitones(valor_punto)

					valor_m_st = valor_inicial + (valor_pendiente*(tiempo_punto-t1))
					#printline 'valor_m_st'
					if valor_punto_st <> undefined and valor_m_st <> undefined

						if tiempo_punto > t1 and tiempo_punto < t2

							if valor_punto_st > valor_m_st
								etiqueta$ = "P"
							else
								etiqueta$ = "V"
							endif

							select textgrid_etiquetado
							Insert point... 1 'tiempo_punto' 'etiqueta$'
							select textgrid_entrada

						endif

					endif
				else
				
					#printline La unidad es Hz
			
					valor_m = valor_inicial + (valor_pendiente*(tiempo_punto-t1))
			
					# printline 'valor_m'

					if valor_punto <> undefined and valor_m <> undefined

						if tiempo_punto > t1 and tiempo_punto < t2

							if valor_punto > valor_m
								etiqueta$ = "P"
							else
								etiqueta$ = "V"
							endif

							select textgrid_etiquetado
							Insert point... 1 'tiempo_punto' 'etiqueta$'
							select textgrid_entrada

						endif

					endif

				endif


			endfor

			#select pitch
			#plus tabla
			#Remove

		endif

	endfor


	# Unimos los textgrid en uno solo

	select textgrid_entrada
	name$ = selected$ ("TextGrid")
	old_textgrid = selected ("TextGrid")

	plus textgrid_etiquetado
	Merge
	Rename... 'name$'
	textgrid = selected ("TextGrid")

	select 'textgrid_etiquetado'
	plus old_textgrid
	Remove
		
endproc


procedure crea_tabla_de_objeto_pitch_GF_comando objeto_pitch$ pitch_unit$

	#printline Objeto pitch: 'objeto_pitch$'
	select Pitch 'objeto_pitch$'
	
	nombre_objeto$ = selected$ ("Pitch")

	pitch = selected ("Pitch")

	# Ahora creamos la tabla a partir del objeto Pitch

	Down to PitchTier
	pitchtier_prov = selected ("PitchTier")
	
	numero_puntos_pitch_tier = Get number of points

	if numero_puntos_pitch_tier > 0

		Down to TableOfReal... 'pitch_unit$'
		tableofreal_prov = selected ("TableOfReal")

		# Normalizamos los valores de tiempo con respecto al inicio

		tiempo_inicial = Get value... 1 1
		num_filas = Get number of rows
		for cont_filas from 1 to num_filas

			valor_tiempo = Get value... 'cont_filas' 1 
			Set value... 'cont_filas' 1 (valor_tiempo - tiempo_inicial)

		endfor
	
		select tableofreal_prov
		table_of_real_prov = selected ("TableOfReal")
		To ContingencyTable
		tabla_contingencia_prov = selected ("ContingencyTable")
		To Table: "rowLabel"	
		tabla_prov = selected ("Table")

		select pitchtier_prov
		plus tabla_contingencia_prov
		plus table_of_real_prov

		Remove
	else
		Create Table with column names... "table" 1 rowLabel Time F0
		Set string value... 1 rowLabel "undefined"
		Set string value... 1 Time "undefined"
		Set string value... 1 F0 "undefined"
		tabla_prov = selected ("Table")
	endif
	
	select tabla_prov
	Rename... 'nombre_objeto$'

		
endproc


procedure calcula_regresion_lineal tabla$

	#printline Nombre tabla: 'tabla$'
	
	select Table 'tabla$'

	nombre_tabla$ = selected$ ("Table")
	
	numero_lineas = Get number of rows

	if numero_lineas > 1

		Remove column: "rowLabel"

		To linear regression

		info$ = Info

		valor_inicial = extractNumber (info$, "Intercept: ")
		#valor_inicial$ = fixed$ (valor_inicial, 5)
	
		pendiente = extractNumber (info$, "Coefficient of factor Time: ")
		#pendiente$ = fixed$ (pendiente, 5)

	else

		#intercept$ = Get value... 1 F0
		valor_inicial = undefined
		pendiente = undefined

	endif

		
	Create Table with column names... "table" 1 rowLabel Valor_inicial Pendiente
	#Set string value... 1 Valor_inicial 'valor_inicial$'
	#Set string value... 1 Pendiente 'pendiente$'
	if valor_inicial = undefined
		Set string value... 1 Valor_inicial NA
	else
		Set numeric value... 1 Valor_inicial 'valor_inicial'
	endif

	if pendiente = undefined
		Set string value... 1 Pendiente NA
	else
		Set numeric value... 1 Pendiente 'pendiente'
	endif

	nombre_completo_regresion_salida$ = nombre_tabla$ + "_regression"

	Rename... 'nombre_completo_regresion_salida$'

endproc


procedure crea_tablas_P_V_de_pitch_GF_anotado_comando textgrid tier_stylization tier_annotation tier_pauses

	select textgrid
	#textgrid = selected ("TextGrid")

	# Ahora creamos las tablas a partir del objeto TextGrid

	num_intervalos = Get number of intervals... 'tier_pauses'

	for cont_intervalos from 1 to num_intervalos

		select textgrid

		tekst$ = Get label of interval... 'tier_pauses' cont_intervalos

		duracion = Get duration
			
		# printline valor tekst 'tekst$'

		if tekst$ <> etiqueta_pausa$

			t1 = Get starting point... 'tier_pauses' cont_intervalos
			t2 = Get end point... 'tier_pauses' cont_intervalos

			Extract part... t1 t2 yes

			textgrid_prov = selected ("TextGrid")
	
			num_puntos = Get number of points... tier_annotation

			Extract tier... tier_stylization
			tier_estilizacion = selected ("TextTier")
	
			Create PitchTier... "Puntos_V" t1 t2
			pitchtier_v = selected ("PitchTier")

			Create PitchTier... "Puntos_P" t1 t2
			pitchtier_p = selected ("PitchTier")

			select textgrid_prov

			for cont_puntos from 1 to num_puntos

				tiempo_punto = Get time of point... tier_annotation cont_puntos
				etiqueta_punto$ = Get label of point... tier_annotation cont_puntos

				# Juanma. 4.01.2008. Normalizamos los valores de tiempo en funcion del punto de inicio del GF

				tiempo_punto_normalizado = 'tiempo_punto' - t1

				select tier_estilizacion

				indice = Get nearest index from time... tiempo_punto
				# printline 'indice'

	
				select textgrid_prov

				valor_punto = Get label of point... tier_stylization indice
				# printline 'valor_punto'

				if etiqueta_punto$ = "P"
					select pitchtier_p
					Add point... 'tiempo_punto_normalizado' 'valor_punto'
				endif

				if etiqueta_punto$ = "V"
					select pitchtier_v
					Add point... 'tiempo_punto_normalizado' 'valor_punto'
				endif
		
				
				select textgrid_prov

			endfor

			select pitchtier_p

			texto_intervalo$ = fixed$('cont_intervalos', 0)
			nombre_completo_objeto_tabla_P$ = nombre_sonido$+"_"+texto_intervalo$+"_tablaF0_P"

			numero_puntos_pitch_tier = Get number of points


			if numero_puntos_pitch_tier > 0
				#Down to TableOfReal... Semitones
				Down to TableOfReal... Hertz
				tableofreal_p = selected ("TableOfReal")
				To ContingencyTable
				tabla_contingencia_prov = selected ("ContingencyTable")
				To Table: "rowLabel"
				tabla_prov = selected ("Table")

				select tableofreal_p
				plus tabla_contingencia_prov
				Remove

			else

				Create Table with column names... "table" 1 rowLabel Time F0
				Set string value... 1 rowLabel "undefined"
				Set string value... 1 Time "undefined"
				Set string value... 1 F0 "undefined"
				tabla_prov = selected ("Table")				

			endif

			select tabla_prov
			Rename... 'nombre_completo_objeto_tabla_P$'

			select pitchtier_v

			numero_puntos_pitch_tier = Get number of points
			
			nombre_completo_objeto_tabla_V$ = nombre_sonido$+"_"+texto_intervalo$+"_tablaF0_V"

			if numero_puntos_pitch_tier > 0
				#Down to TableOfReal... Semitones
				Down to TableOfReal... Hertz
				tableofreal_v = selected ("TableOfReal")
				To ContingencyTable
				tabla_contingencia_prov = selected ("ContingencyTable")
				To Table: "rowLabel"
				tabla_prov = selected ("Table")

				select tableofreal_v
				plus tabla_contingencia_prov				
				Remove

			else

				Create Table with column names... "table" 1 rowLabel Time F0
				Set string value... 1 rowLabel "undefined"
				Set string value... 1 Time "undefined"
				Set string value... 1 F0 "undefined"
				tabla_prov = selected ("Table")


			endif
			
			select tabla_prov
			Rename... 'nombre_completo_objeto_tabla_V$'

			select textgrid_prov
			plus tier_estilizacion
			plus pitchtier_p
			plus pitchtier_v
			Remove

		endif

	endfor


endproc

procedure anota_f0_P+_V- textgrid tier_intonation_groups tier_stylization tier_annotation

	# Creado por Juanma el 11.02.2008
	# Procedimiento para anotar contornos estilizados con P+ o V- utilizando las pendientes de cada GF


		# Añadimos el correspondiente Tier al TextGrid

		select textgrid

		nombre_textgrid$ = selected$ ("TextGrid")

		duracion = Get duration

		Create TextGrid... 0.0 duracion "EtiquetadoPV" EtiquetadoPV

		textgrid_etiquetado = selected ("TextGrid")

		select textgrid

		# Empezamos con el etiquetado

		num_intervalos = Get number of intervals... tier_intonation_groups

		for cont_intervalos from 1 to num_intervalos

			select textgrid

			tekst$ = Get label of interval... 'tier_intonation_groups' cont_intervalos
				
			# printline valor tekst 'tekst$'

			if tekst$ <> etiqueta_pausa$

				numero_intervalo$ = fixed$ (cont_intervalos, 0)
				nombre_fichero_tablas$=nombre_sonido$+"_"+numero_intervalo$

				#nombre_completo_fichero_tabla_p$ = nombre_fichero_tablas$+".regression_P"
				#nombre_completo_fichero_tabla_v$ = nombre_fichero_tablas$+".regression_V"

				nombre_completo_regresion_P$ = nombre_fichero_tablas$ + "_tablaF0_P_regression"
				nombre_completo_regresion_V$ = nombre_fichero_tablas$ + "_tablaF0_V_regression"


				select textgrid

				t1 = Get starting point... 'tier_intonation_groups' cont_intervalos
				t2 = Get end point... 'tier_intonation_groups' cont_intervalos

				Extract part... t1 t2 yes

				textgrid_prov = selected ("TextGrid")	
						
				num_puntos = Get number of points... tier_annotation

					select Table 'nombre_completo_regresion_V$'

					valor_inicial_v = Get value... 1 Valor_inicial
					valor_pendiente_v = Get value... 1 Pendiente

					#printline Valor inicial V: 'valor_inicial_v'
					#printline Valor pendiente V: 'valor_pendiente_v'

					select Table 'nombre_completo_regresion_P$'

					valor_inicial_p = Get value... 1 Valor_inicial
					valor_pendiente_p = Get value... 1 Pendiente

					#printline Valor inicial P: 'valor_inicial_p'
					#printline Valor pendiente P: 'valor_pendiente_p'

					select textgrid_prov
					
					for cont_puntos from 1 to num_puntos
	
						tiempo_punto = Get time of point... 'tier_annotation' cont_puntos
						etiqueta_punto$ = Get label of point... 'tier_annotation' cont_puntos
						# printline 'valor_punto'
						# printline 'valor_p'
						# printline 'valor_m'

						nivel_diferencia$ = ""

						# Determinamos ahora el nivel de la diferencia del valor de F0 del punto con la pendiente predicha

						select textgrid_prov

						Extract tier... 'tier_stylization' 				
						punto_f0 = Get nearest index from time... tiempo_punto
						Remove

						select textgrid_prov
						valor_punto = Get label of point... 'tier_stylization' punto_f0

						if etiqueta_punto$ = "P"
							valor_punto_predicho = valor_inicial_p + (valor_pendiente_p*(tiempo_punto-t1))
						else
							if etiqueta_punto$ = "V"
								valor_punto_predicho = valor_inicial_v + (valor_pendiente_v*(tiempo_punto-t1))
							endif
						endif

						diferencia = valor_punto - valor_punto_predicho
						porcentaje_diferencia = (diferencia*100)/valor_punto_predicho

						if porcentaje_diferencia <> undefined
							if etiqueta_punto$ = "P" and valor_punto > valor_punto_predicho and porcentaje_diferencia > 20
								nivel_diferencia$ = "+"
							else
								if etiqueta_punto$ = "V" and valor_punto < valor_punto_predicho and porcentaje_diferencia < -20
									nivel_diferencia$ = "-"
								else
									nivel_diferencia$ = ""					
								endif				
							endif

						endif

						etiqueta_punto$ = etiqueta_punto$+nivel_diferencia$

						porcentaje_diferencia = 0

						select textgrid_etiquetado
						Insert point... 1 'tiempo_punto' 'etiqueta_punto$'
						select textgrid_prov
					endfor



				select textgrid_prov
				Remove

			endif

		endfor


		# Unimos los textgrid en uno solo

		select textgrid
		name$ = selected$ ("TextGrid")

		plus textgrid_etiquetado
		Merge
		Rename... 'name$'
		textgrid_salida = selected ("TextGrid")


	select textgrid
	name$ = selected$ ("TextGrid")
	old_textgrid = selected ("TextGrid")

	plus textgrid_etiquetado
	Merge
	Rename... 'name$'
	textgrid = selected ("TextGrid")

	select 'textgrid_etiquetado'
	plus old_textgrid
	Remove

endproc

procedure simplifica_anotacion textgrid_entrada tier_intonation_groups tier_annotation

# Creado por Juanma el 23.07.2007
# Script para simplificar una anotacion eliminando etiquetas redundantes
# Esta preparado para ser ejecutado desde linea de comandos

		textgrid = textgrid_entrada

		select textgrid

		nombre_textgrid$ = selected$ ("TextGrid")


		#Creamos el TextGrid de salida

		duracion = Get duration
		Create TextGrid... 0.0 duracion "Labels" Labels
		textgrid_etiquetas = selected ("TextGrid")

		# Solo dejamos ahora los puntos no redundantes. Hacemos la limpieza GF a GF.

		select textgrid

		num_intervalos = Get number of intervals... tier_intonation_groups

		for cont_intervalos from 1 to num_intervalos

			select textgrid

			tekst$ = Get label of interval... 'tier_intonation_groups' cont_intervalos
				
			# printline valor tekst 'tekst$'

			if tekst$ <> etiqueta_pausa$

				select textgrid

				t1 = Get starting point... 'tier_intonation_groups' cont_intervalos
				t2 = Get end point... 'tier_intonation_groups' cont_intervalos

				Extract part... t1 t2 yes

				textgrid_prov = selected ("TextGrid")	

				num_puntos = Get number of points... tier_annotation

				if num_puntos > 0


					tiempo_punto = Get time of point... 'tier_annotation' 1
					valor_punto$ = Get label of point... 'tier_annotation' 1

					select textgrid_etiquetas
					Insert point... 1 'tiempo_punto' 'valor_punto$'
					select textgrid_prov

					if num_puntos > 1


						tiempo_punto = Get time of point... 'tier_annotation' num_puntos
						valor_punto$ = Get label of point... 'tier_annotation' num_puntos

						select textgrid_etiquetas
						Insert point... 1 'tiempo_punto' 'valor_punto$'
						select textgrid_prov

					endif

					if num_puntos > 2

						for cont_puntos from 2 to (num_puntos-1)

							tiempo_punto = Get time of point... 'tier_annotation' cont_puntos
							valor_punto$ = Get label of point... 'tier_annotation' cont_puntos

							valor_punto_anterior$ = Get label of point... 'tier_annotation' (cont_puntos-1)
							valor_punto_posterior$ = Get label of point... 'tier_annotation' (cont_puntos+1)

							if (valor_punto_anterior$ <> valor_punto$) or (valor_punto_posterior$ <> valor_punto$)

								select textgrid_etiquetas
								Insert point... 1 'tiempo_punto' 'valor_punto$'
								select textgrid_prov

							endif

						endfor

					endif


				else

					printline No hay etiquetas en el Tier de anotacion. No hacemos nada.

				endif

				select textgrid_prov
				Remove
				select textgrid

			endif

		endfor

		# Unimos los textgrid en uno solo


	select textgrid
	name$ = selected$ ("TextGrid")
	old_textgrid = selected ("TextGrid")

	plus textgrid_etiquetas
	Merge
	Rename... 'name$'
	textgrid = selected ("TextGrid")


	select 'textgrid_etiquetas'
	plus old_textgrid
	Remove


endproc

procedure anota_patrones textgrid_file stylization_tier annotation_tier stress_groups_tier phonetic_transcription_tier syllables_tier intonation_group_tier phonetic_alphabet$

# Creado por Juanma el 14.08.2007
# Modificado por Juanma el 22.08.07
# Modificado otra vez por Juanma el 12.09.07
# Modificado otra vez por Juanma el 4.06.08. Modifico el metodo de alineamiento de los puntos con las silabas para hacerlo con respecto a la silaba tonica.
# Script para extraer los patrones de grupo acentual a partir del TextGrid asociado a un sonido
# Esta preparado para ser ejecutado desde linea de comandos


		textgrid = textgrid_file

		select textgrid

		nombre_textgrid$ = selected$ ("TextGrid")

		nombre_completo_fichero_contorno$ = directorio_salida$+"/"+nombre_textgrid$+".local"
		filedelete 'nombre_completo_fichero_contorno$'


		#Creamos el TextGrid de salida

		Extract one tier... 'stress_groups_tier'
		Set tier name... 1 Patterns
		textgrid_patrones = selected ("TextGrid")


		#Creamos un Tier provisional para los nucleos silabicos

		select textgrid

		num_tiers = Get number of tiers

		tier_nucleos = (num_tiers+1)

		Insert interval tier... tier_nucleos Nucleos

		cont_intervalos_nucleos = 0

		# Recorremos ahora el tier de los grupos acentuales para detectar los patrones y extraerlos

		num_intervalos = Get number of intervals... stress_groups_tier

		contador_puntos = 0
		contador_patrones = 0
		tiempo_nucleo_anterior = 0

		for cont_intervalos from 1 to (num_intervalos-1)

			select textgrid
			
			tekst$ = Get label of interval... 'stress_groups_tier' cont_intervalos
			etiqueta_siguiente$ = Get label of interval... 'stress_groups_tier' cont_intervalos+1

			if tekst$ <> etiqueta_pausa$

				# printline Intervalo: 'cont_intervalos'
				
				etiqueta_anterior$ = Get label of interval... 'stress_groups_tier' (cont_intervalos-1)

				tiempo_final_intervalo = Get end point... 'stress_groups_tier' cont_intervalos
				tiempo_inicio_intervalo = Get starting point... 'stress_groups_tier' cont_intervalos

				# Intentamos ajustar correctamente los limites del grupo acentual

				select textgrid

				primera_silaba = Get interval at time... 'syllables_tier' tiempo_inicio_intervalo
				tiempo_inicio_primera_silaba = Get starting point... 'syllables_tier' primera_silaba

				distancia_a_inicio_silaba = 0
				distancia_a_final_silaba = 0

				if tiempo_inicio_primera_silaba <> tiempo_inicio_intervalo

					tiempo_final_primera_silaba = Get end point... 'syllables_tier' primera_silaba
					distancia_a_inicio_silaba = abs(tiempo_inicio_intervalo - tiempo_inicio_primera_silaba)
					distancia_a_final_silaba = abs(tiempo_inicio_intervalo - tiempo_final_primera_silaba)

					if distancia_a_inicio_silaba < distancia_a_final_silaba

							tiempo_inicio_intervalo = 'tiempo_inicio_primera_silaba'
						
						else

							tiempo_inicio_intervalo = 'tiempo_final_primera_silaba'

						endif

					endif


					ultima_silaba = Get interval at time... 'syllables_tier' tiempo_final_intervalo
					tiempo_final_ultima_silaba = Get end point... 'syllables_tier' 'ultima_silaba'
					
					distancia_a_inicio_silaba = 0
					distancia_a_final_silaba = 0

					if tiempo_final_ultima_silaba <> tiempo_final_intervalo

						tiempo_inicio_ultima_silaba = Get starting point... 'syllables_tier' 'ultima_silaba'

						distancia_a_inicio_silaba = abs(tiempo_final_intervalo - tiempo_inicio_ultima_silaba)
						distancia_a_final_silaba = abs(tiempo_final_intervalo - tiempo_final_ultima_silaba)

						if distancia_a_inicio_silaba < distancia_a_final_silaba

							tiempo_final_intervalo = 'tiempo_inicio_ultima_silaba'
						
						else

							tiempo_final_intervalo = 'tiempo_final_ultima_silaba'

						endif

						#printline tiempo inicio intervalo: 'tiempo_inicio_intervalo'
						#printline tiempo final intervalo: 'tiempo_final_intervalo'

					endif

				intervalo_grupo = Get interval at time... 'intonation_group_tier' tiempo_inicio_intervalo
				tiempo_final_grupo = Get end point... 'intonation_group_tier' intervalo_grupo
								
				Extract part... 'tiempo_inicio_intervalo' 'tiempo_final_intervalo' yes
				tier_prov = selected ("TextGrid")

				num_puntos = Get number of points... annotation_tier
				num_silabas = Get number of intervals... syllables_tier
				num_silabas$ = Get number of intervals... syllables_tier
				num_silaba_acentuada = 0
				cont_silabas_acentuadas = 0

				while num_silaba_acentuada = 0 and cont_silabas_acentuadas < num_silabas
					cont_silabas_acentuadas  = cont_silabas_acentuadas+1
					etiqueta_silaba$ = Get label of interval... syllables_tier cont_silabas_acentuadas
					if etiqueta_silaba$ = "T"
						num_silaba_acentuada = cont_silabas_acentuadas
					endif
				endwhile

				#printline Num silabas: 'num_silabas'

				Create Table without column names... Patron 4 4
				Set column label (index)... 1 1
				Set column label (index)... 2 2
				Set column label (index)... 3 3
				Set column label (index)... 4 4

				tabla_salida = selected ("Table")

				Set string value... 1 1 "Posicion:"
				Set string value... 2 1 "Num_puntos:"
				#Set numeric value... 2 2 num_puntos
				Set string value... 3 1 "Num_silabas:"
				Set numeric value... 3 2 num_silabas
				Set string value... 4 1 "Silaba_acentuada:"
				Set numeric value... 4 2 num_silaba_acentuada

				# Escribimos la informacion de la posicion del patron

				select tabla_salida
				Set string value... 1 2 'posicion$'

				# Detectamos ahora los nucleos silabicos

				# printline Num silabas: 'num_silabas'

				for cont_silabas from 1 to num_silabas

					# printline Cont silabas: 'cont_silabas'

					select tier_prov

					tiempo_final_silaba = Get end point... 'syllables_tier' cont_silabas
					tiempo_inicio_silaba = Get starting point... 'syllables_tier' cont_silabas

					# printline Tiempo inicio silaba: 'tiempo_inicio_silaba'
					# printline Tiempo final silaba: 'tiempo_final_silaba'

					# Intentamos ajustar correctamente los limites de la silaba

					select textgrid

					primer_alofono = Get interval at time... 'phonetic_transcription_tier' tiempo_inicio_silaba
					tiempo_inicio_primer_alofono = Get starting point... 'phonetic_transcription_tier' primer_alofono

					distancia_a_inicio_alofono = 0
					distancia_a_final_alofono = 0

					if tiempo_inicio_primer_alofono <> tiempo_inicio_silaba

						tiempo_final_primer_alofono = Get end point... 'phonetic_transcription_tier' primer_alofono
						distancia_a_inicio_alofono = abs(tiempo_inicio_silaba - tiempo_inicio_primer_alofono)
						distancia_a_final_alofono = abs(tiempo_inicio_silaba - tiempo_final_primer_alofono)

						if distancia_a_inicio_alofono < distancia_a_final_alofono

							tiempo_inicio_silaba = 'tiempo_inicio_primer_alofono'
						
						else

							tiempo_inicio_silaba = 'tiempo_final_primer_alofono'

						endif

					endif


					ultimo_alofono = Get interval at time... 'phonetic_transcription_tier' tiempo_final_silaba
					tiempo_final_ultimo_alofono = Get end point... 'phonetic_transcription_tier' 'ultimo_alofono'
					
					# printline Ultimo alofono: 'ultimo_alofono'
					# printline Final ultimo alofono: 'tiempo_final_ultimo_alofono'

					distancia_a_inicio_alofono = 0
					distancia_a_final_alofono = 0

					if tiempo_final_ultimo_alofono <> tiempo_final_silaba

						tiempo_inicio_ultimo_alofono = Get starting point... 'phonetic_transcription_tier' 'ultimo_alofono'

						# printline Inicio ultimo alofono: 'tiempo_inicio_ultimo_alofono'

						distancia_a_inicio_alofono = abs(tiempo_final_silaba - tiempo_inicio_ultimo_alofono)
						distancia_a_final_alofono = abs(tiempo_final_silaba - tiempo_final_ultimo_alofono)

						if distancia_a_inicio_alofono < distancia_a_final_alofono

							tiempo_final_silaba = 'tiempo_inicio_ultimo_alofono'
						
						else

							tiempo_final_silaba = 'tiempo_final_ultimo_alofono'

						endif

					endif

					# printline Tiempo inicio silaba tras ajuste: 'tiempo_inicio_silaba'
					# printline Tiempo final silaba tras ajuste: 'tiempo_final_silaba'

					Extract part... 'tiempo_inicio_silaba' 'tiempo_final_silaba' yes
					tier_silaba = selected ("TextGrid")

					num_alofonos = Get number of intervals... phonetic_transcription_tier

					# printline Numero de alofonos silaba 'cont_silabas': 'num_alofonos'

					cont_alofonos = 0

					encontrado_inicio = 0
					encontrado_final = 0

					tiempo_inicio_nucleo = tiempo_inicio_silaba
					tiempo_final_nucleo = tiempo_final_silaba

					while (encontrado_final = 0) and (cont_alofonos < num_alofonos)

						cont_alofonos = cont_alofonos+1
						etiqueta_alofono$ = Get label of interval... phonetic_transcription_tier cont_alofonos
						call TipoSonido 'etiqueta_alofono$' 'phonetic_alphabet$'
						tipo_sonido_actual$ = tipo_sonido$

							
						# printline etiqueta alofono: 'etiqueta_alofono$'

						if encontrado_inicio = 0
			
							#if etiqueta_alofono$ = "a_&quot" or etiqueta_alofono$ = "e_&quot" or etiqueta_alofono$ = "E_&quot" or etiqueta_alofono$ = "i_&quot" or etiqueta_alofono$ = "o_&quot" or etiqueta_alofono$ = "O_&quot" or etiqueta_alofono$ = "u_&quot" or etiqueta_alofono$ = "@_&quot" or etiqueta_alofono$ = "a_%" or etiqueta_alofono$ = "e_%" or etiqueta_alofono$ = "E_%" or etiqueta_alofono$ = "i_%" or etiqueta_alofono$ = "o_%" or etiqueta_alofono$ = "O_%" or etiqueta_alofono$ = "u_%" or etiqueta_alofono$ = "@_%" or etiqueta_alofono$ = "a" or etiqueta_alofono$ = "e" or etiqueta_alofono$ = "E" or etiqueta_alofono$ = "i" or etiqueta_alofono$ = "o" or etiqueta_alofono$ = "O" or etiqueta_alofono$ = "u" or etiqueta_alofono$ = "@" or etiqueta_alofono$ = "w" or etiqueta_alofono$ = "j"
							if tipo_sonido_actual$ = "VocalTonica" or tipo_sonido_actual$ = "VocalAtona" or tipo_sonido_actual$ = "VocalTonica2" or tipo_sonido_actual$ = "Semivocal"

								encontrado_inicio = 1

							endif

							tiempo_inicio_nucleo = Get starting point... 'phonetic_transcription_tier' cont_alofonos


						endif

						if encontrado_inicio = 1 

							if cont_alofonos < num_alofonos

								etiqueta_alofono_siguiente$ = Get label of interval... phonetic_transcription_tier (cont_alofonos+1)
								call TipoSonido 'etiqueta_alofono_siguiente$' 'phonetic_alphabet$'
								tipo_sonido_siguiente$ = tipo_sonido$

								#if etiqueta_alofono$ = "a_&quot" or etiqueta_alofono$ = "e_&quot" or etiqueta_alofono$ = "E_&quot" or etiqueta_alofono$ = "i_&quot" or etiqueta_alofono$ = "o_&quot" or etiqueta_alofono$ = "O_&quot" or etiqueta_alofono$ = "u_&quot" or etiqueta_alofono$ = "@_&quot" or etiqueta_alofono$ = "a_%" or etiqueta_alofono$ = "e_%" or etiqueta_alofono$ = "E_%" or etiqueta_alofono$ = "i_%" or etiqueta_alofono$ = "o_%" or etiqueta_alofono$ = "O_%" or etiqueta_alofono$ = "u_%" or etiqueta_alofono$ = "@_%" or etiqueta_alofono$ = "a" or etiqueta_alofono$ = "e" or etiqueta_alofono$ = "E" or etiqueta_alofono$ = "i" or etiqueta_alofono$ = "o" or etiqueta_alofono$ = "O" or etiqueta_alofono$ = "u" or etiqueta_alofono$ = "@" or etiqueta_alofono$ = "w" or etiqueta_alofono$ = "j" or etiqueta_alofono$ = "m" or etiqueta_alofono$ = "n" or etiqueta_alofono$ = "l"
								if tipo_sonido_actual$ = "VocalTonica" or tipo_sonido_actual$ = "VocalAtona" or tipo_sonido_actual$ = "VocalTonica2" or tipo_sonido_actual$ = "Semivocal"

									#if (etiqueta_alofono$ = "a_&quot" or etiqueta_alofono$ = "e_&quot" or etiqueta_alofono$ = "E_&quot" or etiqueta_alofono$ = "i_&quot" or etiqueta_alofono$ = "o_&quot" or etiqueta_alofono$ = "O_&quot" or etiqueta_alofono$ = "u_&quot" or etiqueta_alofono$ = "@_&quot" or etiqueta_alofono$ = "a_%" or etiqueta_alofono$ = "e_%" or etiqueta_alofono$ = "E_%" or etiqueta_alofono$ = "i_%" or etiqueta_alofono$ = "o_%" or etiqueta_alofono$ = "O_%" or etiqueta_alofono$ = "u_%" or etiqueta_alofono$ = "@_%" or etiqueta_alofono$ = "a" or etiqueta_alofono$ = "e" or etiqueta_alofono$ = "E" or etiqueta_alofono$ = "i" or etiqueta_alofono$ = "o" or etiqueta_alofono$ = "O" or etiqueta_alofono$ = "u" or etiqueta_alofono$ = "@" or etiqueta_alofono$ = "w" or etiqueta_alofono$ = "j") and etiqueta_alofono_siguiente$ <> "a_&quot" and etiqueta_alofono_siguiente$ <> "e_&quot" and etiqueta_alofono_siguiente$ <> "E_&quot" and etiqueta_alofono_siguiente$ <> "i_&quot" and etiqueta_alofono_siguiente$ <> "o_&quot" and etiqueta_alofono_siguiente$ <> "O_&quot" and etiqueta_alofono_siguiente$ <> "u_&quot" and etiqueta_alofono_siguiente$ <> "@_&quot" and etiqueta_alofono_siguiente$ <> "a_%" and etiqueta_alofono_siguiente$ <> "e_%" and etiqueta_alofono_siguiente$ <> "E_%" and etiqueta_alofono_siguiente$ <> "i_%" and etiqueta_alofono_siguiente$ <> "o_%" and etiqueta_alofono_siguiente$ <> "O_%" and etiqueta_alofono_siguiente$ <> "u_%" and etiqueta_alofono_siguiente$ <> "@_%" and etiqueta_alofono_siguiente$ <> "a" and etiqueta_alofono_siguiente$ <> "e" and etiqueta_alofono_siguiente$ <> "E" and etiqueta_alofono_siguiente$ <> "i" and etiqueta_alofono_siguiente$ <> "o" and etiqueta_alofono_siguiente$ <> "O" and etiqueta_alofono_siguiente$ <> "u" and etiqueta_alofono_siguiente$ <> "@" and etiqueta_alofono_siguiente$ <> "w" and etiqueta_alofono_siguiente$ <> "j" and etiqueta_alofono_siguiente$ <> "m" and etiqueta_alofono_siguiente$ <> "n" and etiqueta_alofono_siguiente$ <> "N" and etiqueta_alofono_siguiente$ <> "l" and etiqueta_alofono_siguiente$ <> "L"
								if (tipo_sonido_actual$ = "VocalTonica" or tipo_sonido_actual$ = "VocalAtona" or tipo_sonido_actual$ = "VocalTonica2" or tipo_sonido_actual$ = "Semivocal") and tipo_sonido_siguiente$ <> "VocalTonica" and tipo_sonido_siguiente$ <> "VocalAtona" and tipo_sonido_siguiente$ <> "VocalTonica2" and tipo_sonido_siguiente$ <> "Semivocal" and etiqueta_alofono_siguiente$ <> "m" and etiqueta_alofono_siguiente$ <> "n" and etiqueta_alofono_siguiente$ <> "N" and etiqueta_alofono_siguiente$ <> "\nj" and etiqueta_alofono_siguiente$ <> "l" and etiqueta_alofono_siguiente$ <> "L" and etiqueta_alofono_siguiente$ <> "\yt"

										encontrado_final = 1

									else

										if etiqueta_alofono$ = "m" or etiqueta_alofono$ = "n" or etiqueta_alofono$ = "N" or etiqueta_alofono$ = "\nj" or etiqueta_alofono$ = "l" or etiqueta_alofono$ = "L" or etiqueta_alofono$ = "\yt"

											encontrado_final = 1

										endif

									endif

								endif


							endif

							tiempo_final_nucleo = Get end point... 'phonetic_transcription_tier' cont_alofonos

						endif


						if cont_alofonos = num_alofonos
							encontrado_final = 1
						endif

					endwhile



					#printline Tiempo inicio nucleo: 'tiempo_inicio_nucleo'
					#printline Tiempo final nucleo: 'tiempo_final_nucleo'
					#printline Tiempo nucleo anterior: 'tiempo_nucleo_anterior'

					select textgrid

					if tiempo_nucleo_anterior < tiempo_inicio_nucleo
						Insert boundary... tier_nucleos tiempo_inicio_nucleo
						cont_intervalos_nucleos = cont_intervalos_nucleos+1

					endif
					Insert boundary... tier_nucleos tiempo_final_nucleo
					cont_intervalos_nucleos = cont_intervalos_nucleos+1
					Set interval text... tier_nucleos cont_intervalos_nucleos 'cont_silabas'

					tiempo_nucleo_anterior = tiempo_final_nucleo

					select tier_silaba

					Remove

				endfor

				posicion_punto$ = ""
				posicion_punto_anterior$ = ""
				posicion_punto_anterior2$ = ""
				silaba_punto_prov = 0
				silaba_punto = 0
				silaba_punto_anterior = 0
				silaba_punto_anterior2 = 0
				porcentaje_diferencia = 0
				num_puntos_validos = 0

				for cont_puntos from 1 to num_puntos

					select tier_prov

					etiqueta_punto$ = Get label of point... annotation_tier cont_puntos

					tiempo_punto = Get time of point... annotation_tier cont_puntos

					# printline Tiempo punto: 'tiempo_punto'

					select textgrid

					intervalo_silaba_actual = Get interval at time... syllables_tier tiempo_punto
					inicio_silaba_actual = Get starting point... syllables_tier intervalo_silaba_actual
					final_silaba_actual = Get end point... syllables_tier intervalo_silaba_actual

					intervalo_nucleos = Get interval at time... tier_nucleos tiempo_punto

					# printline Intervalo nucleos 'intervalo_nucleos'
					# printline Tier nucleos: 'tier_nucleos'

					inicio_intervalo = Get starting point... tier_nucleos intervalo_nucleos
					final_intervalo = Get end point... tier_nucleos intervalo_nucleos
					etiqueta_intervalo$ = Get label of interval... tier_nucleos intervalo_nucleos

					# printline Inicio intervalo: 'inicio_intervalo'
					# printline Final intervalo: 'final_intervalo'

					mitad_intervalo = ((final_intervalo - inicio_intervalo)/2) + inicio_intervalo
					
					# printline Etiqueta intervalo: 'etiqueta_intervalo$'

					if etiqueta_intervalo$ <> ""

# Juanma. 04.06.2008. Cambio la manera de indicar la posicion del punto para hacerlo relativo a la silaba acentuada. 0 significa que el punto esta en la silaba tonica.

						silaba_punto_prov = Get label of interval... tier_nucleos intervalo_nucleos

						distancia_a_mitad = abs(mitad_intervalo - tiempo_punto)
						distancia_a_inicio = abs(inicio_intervalo - tiempo_punto)

						if distancia_a_inicio < distancia_a_mitad

							posicion_punto$ = "INICIO_NUCLEO"

						else

							distancia_a_final = abs(final_intervalo - tiempo_punto)

							if distancia_a_final < distancia_a_mitad

								posicion_punto$ = "FINAL_NUCLEO"

							else

								posicion_punto$ = "MITAD_NUCLEO"

							endif


						endif

					else

						# printline El punto no cae en el nucleo
						# printline Final intervalo: 'final_intervalo'
						# printline Final silaba actual: 'final_silaba_actual'
						
						if final_intervalo >= final_silaba_actual

							posicion_punto$ = "FINAL_NUCLEO"
							silaba_punto_prov = Get label of interval... tier_nucleos (intervalo_nucleos-1)

						else

							# printline El punto esta antes del nucleo
							# printline Inicio intervalo: 'inicio_intervalo'
							# printline Inicio silaba actual: 'inicio_silaba_actual'

							#if inicio_intervalo <= inicio_silaba_actual

								posicion_punto$ = "INICIO_NUCLEO"
								silaba_punto_prov = Get label of interval... tier_nucleos (intervalo_nucleos+1)

							#endif

						endif

						# printline Etiqueta punto: 'etiqueta_punto$'
						# printline Silaba punto: 'silaba_punto'


					endif
					

					silaba_punto = silaba_punto_prov - num_silaba_acentuada

					# printline Numero puntos: 'num_puntos'
					# printline Contador puntos: 'cont_puntos'
					# printline Posicion punto: 'posicion_punto$'
					# printline Etiqueta punto: 'etiqueta_punto$'
					# printline Silaba punto provisional: 'silaba_punto_prov'
					# printline Silaba punto: 'silaba_punto'

				# Comprobamos ahora que el punto no coincide con el anterior, y si lo hace, modificamos el punto

						es_punto_valido = 1
						num_puntos_validos = num_puntos_validos+1

						# printline Posicion punto: 'posicion_punto$'
						# printline Posicion punto anterior: 'posicion_punto_anterior$'
						# printline Silaba punto: 'silaba_punto'
						# printline Silaba punto anterior: 'silaba_punto_anterior'

						if (posicion_punto$ = "INICIO_NUCLEO") and (posicion_punto_anterior$ = "INICIO_NUCLEO") and (silaba_punto = silaba_punto_anterior)

							if etiqueta_punto$ = etiqueta_punto_anterior$
								es_punto_valido = 0
							else
								posicion_punto$ = "MITAD_NUCLEO"
								#printline Modifico la posicion de punto a 'posicion_punto$'
							endif

						endif


						if (posicion_punto$ = "MITAD_NUCLEO") and (posicion_punto_anterior$ = "MITAD_NUCLEO") and (silaba_punto = silaba_punto_anterior)

							if etiqueta_punto$ = etiqueta_punto_anterior$
								es_punto_valido = 0
							else
								posicion_punto$ = "FINAL_NUCLEO"
								#printline Modifico la posicion de punto a 'posicion_punto$'
							endif

						endif

						if (posicion_punto$ = "FINAL_NUCLEO") and (posicion_punto_anterior$ = "FINAL_NUCLEO") and (silaba_punto = silaba_punto_anterior)


							if etiqueta_punto$ = etiqueta_punto_anterior$
								es_punto_valido = 0
							else

								if (posicion_punto_anterior2$ = "MITAD_NUCLEO") and (silaba_punto_anterior = silaba_punto_anterior2)

									posicion_punto_anterior2$ = "INICIO_NUCLEO"
									num_celda = (num_puntos_validos+2)

									select tabla_salida

									Set string value... num_celda 2 'posicion_punto_anterior2$'
									printline Modifico la posicion de punto anterior 2 a 'posicion_punto_anterior2$'

								endif

								posicion_punto_anterior$ = "MITAD_NUCLEO"
								num_celda = (num_puntos_validos+3)

								select tabla_salida

								Set string value... num_celda 2 'posicion_punto_anterior$'
								printline Modifico la posicion de punto anterior  a 'posicion_punto_anterior$'

							endif

						endif

						if es_punto_valido = 0
							num_puntos_validos = num_puntos_validos-1
						endif


				# Ponemos ahora la informacion sobre los puntos del patron en la tabla

					if es_punto_valido = 1
						
						num_celda = (num_puntos_validos+4)

						select tabla_salida
						Append row

						Set string value... num_celda 1 'etiqueta_punto$'
						Set string value... num_celda 2 'posicion_punto$'
						Set numeric value... num_celda 3 'silaba_punto'
						Set string value... num_celda 4 'nivel_diferencia$'

						posicion_punto_anterior2$ = posicion_punto_anterior$
						posicion_punto_anterior$ = posicion_punto$
						silaba_punto_anterior = 'silaba_punto'
						silaba_punto_anterior2 = 'silaba_punto_anterior'	
						etiqueta_punto_anterior$ = etiqueta_punto$	
					endif	

				endfor

			# Escribimos el numero de puntos totales del patron

			select tabla_salida

			Set numeric value... 2 2 num_puntos_validos

			# Guardamos el patron en un fichero

			if num_puntos_validos = 0
				nombre_fichero_salida$ = "0"
			else
				nombre_fichero_salida$ = ""
			endif

			posicion_punto_reducida$ = ""

			select tabla_salida

			for cont_tabla from 1 to num_puntos_validos

				etiqueta_prov$ = Get value... (cont_tabla+4) 1
				posicion_punto_prov$ = Get value... (cont_tabla+4) 2

				if posicion_punto_prov$ = "INICIO_NUCLEO"
					posicion_punto_reducida$ = "I"
				else
					if posicion_punto_prov$ = "MITAD_NUCLEO"
						posicion_punto_reducida$ = "M"
					else
						if posicion_punto_prov$ = "FINAL_NUCLEO"
							posicion_punto_reducida$ = "F"
						endif
					endif
				endif

				silaba_prov$ = Get value... (cont_tabla+4) 3

				nivel_diferencia_prov$ = Get value... (cont_tabla+4) 4
				if nivel_diferencia_prov$ = "0"
					nivel_diferencia_prov$ = ""
				endif

				nombre_prov$ = etiqueta_prov$+posicion_punto_reducida$+silaba_prov$

				if cont_tabla = 1
					nombre_fichero_salida$ = nombre_fichero_salida$+nombre_prov$
				else
					nombre_fichero_salida$ = nombre_fichero_salida$+"_"+nombre_prov$
				endif

			endfor

			num_silaba_acentuada$ = fixed$(num_silaba_acentuada, 0)


			select tier_prov
			Remove

			select textgrid_patrones
			Set interval text... 1 cont_intervalos 'nombre_fichero_salida$'

			salida_fichero_contorno$ = nombre_fichero_salida$+newline$
 			if fileReadable (nombre_completo_fichero_contorno$)
				fileappend 'nombre_completo_fichero_contorno$' 'salida_fichero_contorno$'
			else
				salida_fichero_contorno$ > 'nombre_completo_fichero_contorno$'
				
			endif


			endif

		endfor

	select textgrid
	Remove tier... 'tier_grupos_fonicos'+5

	name$ = selected$ ("TextGrid")
	old_textgrid = selected ("TextGrid")

	plus textgrid_patrones
	Merge
	Rename... 'name$'
	textgrid = selected ("TextGrid")

	select 'textgrid_patrones'
	plus old_textgrid
	Remove


endproc

procedure calcula_regresion_lineal tabla$

	#printline Nombre tabla: 'tabla$'
	
	select Table 'tabla$'

	nombre_tabla$ = selected$ ("Table")
	
	numero_lineas = Get number of rows

	if numero_lineas > 1

		Remove column: "rowLabel"

		To linear regression

		#regresion = selected ("Linear_regression")

		info$ = Info

		valor_inicial = extractNumber (info$, "Intercept: ")
		#valor_inicial$ = fixed$ (valor_inicial, 5)
	
		pendiente = extractNumber (info$, "Coefficient of factor Time: ")
		#pendiente$ = fixed$ (pendiente, 5)

		#select regresion
		Remove

	else

		#intercept$ = Get value... 1 F0
		valor_inicial = undefined
		pendiente = undefined

	endif

		
	Create Table with column names... "table" 1 rowLabel Valor_inicial Pendiente
	#Set string value... 1 Valor_inicial 'valor_inicial$'
	#Set string value... 1 Pendiente 'pendiente$'
	if valor_inicial = undefined
		Set string value... 1 Valor_inicial NA
	else
		Set numeric value... 1 Valor_inicial 'valor_inicial'
	endif

	if pendiente = undefined
		Set string value... 1 Pendiente NA
	else
		Set numeric value... 1 Pendiente 'pendiente'
	endif

	nombre_completo_regresion_salida$ = nombre_tabla$ + "_regression"

	Rename... 'nombre_completo_regresion_salida$'


endproc


procedure crea_tablas_P_V_de_pitch_GF_anotado_comando textgrid tier_stylization tier_annotation tier_pauses

	select textgrid
	#textgrid = selected ("TextGrid")

	# Ahora creamos las tablas a partir del objeto TextGrid

	num_intervalos = Get number of intervals... 'tier_pauses'

	for cont_intervalos from 1 to num_intervalos

		select textgrid

		tekst$ = Get label of interval... 'tier_pauses' cont_intervalos

		duracion = Get duration
			
		# printline valor tekst 'tekst$'

		if tekst$ <> "P"

			t1 = Get starting point... 'tier_pauses' cont_intervalos
			t2 = Get end point... 'tier_pauses' cont_intervalos

			Extract part... t1 t2 yes

			textgrid_prov = selected ("TextGrid")
	
			num_puntos = Get number of points... tier_annotation

			Extract tier... tier_stylization
			tier_estilizacion = selected ("TextTier")
	
			Create PitchTier... "Puntos_V" t1 t2
			pitchtier_v = selected ("PitchTier")

			Create PitchTier... "Puntos_P" t1 t2
			pitchtier_p = selected ("PitchTier")

			select textgrid_prov

			for cont_puntos from 1 to num_puntos

				tiempo_punto = Get time of point... tier_annotation cont_puntos
				etiqueta_punto$ = Get label of point... tier_annotation cont_puntos

				# Juanma. 4.01.2008. Normalizamos los valores de tiempo en funcion del punto de inicio del GF

				tiempo_punto_normalizado = 'tiempo_punto' - t1

				select tier_estilizacion

				indice = Get nearest index from time... tiempo_punto
				# printline 'indice'

	
				select textgrid_prov

				valor_punto = Get label of point... tier_stylization indice
				# printline 'valor_punto'

				if etiqueta_punto$ = "P"
					select pitchtier_p
					Add point... 'tiempo_punto_normalizado' 'valor_punto'
				endif

				if etiqueta_punto$ = "V"
					select pitchtier_v
					Add point... 'tiempo_punto_normalizado' 'valor_punto'
				endif
		
				
				select textgrid_prov

			endfor

			select pitchtier_p

			texto_intervalo$ = fixed$('cont_intervalos', 0)
			nombre_completo_objeto_tabla_P$ = nombre_sonido$+"_"+texto_intervalo$+"_tablaF0_P"

			numero_puntos_pitch_tier = Get number of points


			if numero_puntos_pitch_tier > 0
				Down to TableOfReal... Semitones
				tableofreal_p = selected ("TableOfReal")
				To ContingencyTable
				tabla_contingencia_prov = selected ("ContingencyTable")
				To Table: "rowLabel"
				tabla_prov = selected ("Table")

				select tableofreal_p
				plus tabla_contingencia_prov
				Remove

			else

				Create Table with column names... "table" 1 rowLabel Time F0
				Set string value... 1 rowLabel "undefined"
				Set string value... 1 Time "undefined"
				Set string value... 1 F0 "undefined"
				tabla_prov = selected ("Table")				

			endif

			select tabla_prov
			Rename... 'nombre_completo_objeto_tabla_P$'

			select pitchtier_v

			numero_puntos_pitch_tier = Get number of points
			
			nombre_completo_objeto_tabla_V$ = nombre_sonido$+"_"+texto_intervalo$+"_tablaF0_V"

			if numero_puntos_pitch_tier > 0
				Down to TableOfReal... Semitones
				tableofreal_v = selected ("TableOfReal")
				To ContingencyTable
				tabla_contingencia_prov = selected ("ContingencyTable")
				To Table: "rowLabel"
				tabla_prov = selected ("Table")

				select tableofreal_v
				plus tabla_contingencia_prov				
				Remove

			else

				Create Table with column names... "table" 1 rowLabel Time F0
				Set string value... 1 rowLabel "undefined"
				Set string value... 1 Time "undefined"
				Set string value... 1 F0 "undefined"
				tabla_prov = selected ("Table")


			endif
			
			select tabla_prov
			Rename... 'nombre_completo_objeto_tabla_V$'

			select textgrid_prov
			plus tier_estilizacion
			plus pitchtier_p
			plus pitchtier_v
			Remove

		endif

	endfor


endproc


procedure crea_tabla_val_lineas_ref_GF textgrid tier_gf etiqueta_pausa$

	valor_final_p_anterior = 0
	valor_final_v_anterior = 0
	valor_inicial_p_anterior = 0
	valor_inicial_v_anterior = 0

	num_filas = 0
	Create Table with column names... Valores_rectas_F0 num_filas File IG Duration P_Initial_F0 P_Final_F0 P_Slope V_Initial_F0 V_Final_F0 V_Slope Initial_F0_Range Final_F0_Range Total_F0_reset_P Total_F0_reset_V Partial_F0_reset_P Partial_F0_reset_V
	tabla_salida = selected ("Table")

	name$ = replace$(fichero_wav$, ".wav", "", 0)

	#printline Agregamos los valores de 'name$'

	select textgrid

	num_intervalos = Get number of intervals... tier_gf
	gf = 0
	posicion_gf$ = "interior"
				
	for j to num_intervalos
		select textgrid
		etiq$ = Get label of interval... tier_gf j

		if etiq$ <> etiqueta_pausa$
			gf = gf + 1
			inicio = Get starting point... tier_gf j
			final = Get end point... tier_gf j
	
	
					
			Extract part... inicio final yes
			textgrid_provisional = selected ("TextGrid")
			select textgrid_provisional		

	
			numero_intervalo$ = fixed$ (j, 0)

			nombre_completo_objeto_tabla_global$ = name$+ "_" + numero_intervalo$
			nombre_completo_regresion_global$ = nombre_completo_objeto_tabla_global$ + "_regression"

			nombre_completo_objeto_tabla_P$ = nombre_completo_objeto_tabla_global$+"_tablaF0_P"
			nombre_completo_regresion_P$ = nombre_completo_objeto_tabla_P$ + "_regression"

			#select LinearRegression 'nombre_completo_objeto_tabla_P$'
			select Table 'nombre_completo_regresion_P$'

			#tabla_p = selected ("LinearRegression")
			tabla_p = selected ("Table")
			
			#info_p$ = Info
			#printline 'info_p$'


			#printline He leido correctamente la tabla 'nombre_completo_fichero_tabla$'

			# Leemos de la tabla los valores del valor inicial y la pendiente

			#valor_inicial_p = extractNumber (info_p$, "Intercept: ")
			#pendiente_p = extractNumber (info_p$, "Coefficient of factor Time: ")
			
			#printline valor inicial p: 'valor_inicial_p'
			#printline pendiente p: 'pendiente_p'


			#valor_inicial_p$ = fixed$ (valor_inicial_p, 0)
			#pendiente_p$ = fixed$ (pendiente_p, 0)

			valor_inicial_p = Get value... 1 Valor_inicial
			pendiente_p = Get value... 1 Pendiente

			valor_inicial_p$ = Get value... 1 Valor_inicial
			pendiente_p$ = Get value... 1 Pendiente

			
			nombre_completo_objeto_tabla_V$ = nombre_completo_objeto_tabla_global$+"_tablaF0_V"
			nombre_completo_regresion_V$ = nombre_completo_objeto_tabla_V$ + "_regression"

			#select LinearRegression 'nombre_completo_objeto_tabla_V$'
			select Table 'nombre_completo_regresion_V$'

			#tabla_v = selected ("LinearRegression")
			tabla_v = selected ("Table")
			
			#info_v$ = Info
			#printline 'info_v$'

			#printline He leido correctamente la tabla 'nombre_completo_fichero_tabla$'

			# Leemos de la tabla los valores del valor inicial y la pendiente

			#valor_inicial_v = extractNumber (info_v$, "Intercept: ")
			#pendiente_v = extractNumber (info_v$, "Coefficient of factor Time: ")
			
			#printline valor inicial v: 'valor_inicial_v'
			#printline pendiente v: 'pendiente_v'


			#valor_inicial_v$ = fixed$ (valor_inicial_v, 0)
			#pendiente_v$ = fixed$ (pendiente_v, 0)

			valor_inicial_v = Get value... 1 Valor_inicial
			pendiente_v = Get value... 1 Pendiente

			valor_inicial_v$ = Get value... 1 Valor_inicial
			pendiente_v$ = Get value... 1 Pendiente

			duracion_gf = final - inicio
			duracion_gf$ = fixed$(duracion_gf, 5)

			gf$ = fixed$(gf, 0)

			valor_final_p = valor_inicial_p + (pendiente_p * duracion_gf)
			valor_final_v = valor_inicial_v + (pendiente_v * duracion_gf)
			
			#printline valor final p 'valor_final_p'
			#printline valor final V 'valor_final_v'


			valor_final_p$ = fixed$(valor_final_p, 5)
			valor_final_v$ = fixed$(valor_final_v, 5)

			rango_inicial_p_v = valor_inicial_p - valor_inicial_v
			rango_final_p_v = valor_final_p - valor_final_v
			
			#printline rango inicial: 'rango_inicial_p_v'
			#printline rango final: 'rango_final_p_v'


			rango_inicial_p_v$ = fixed$(rango_inicial_p_v, 5)
			rango_final_p_v$ = fixed$(rango_final_p_v, 5)

			if valor_final_p_anterior <> 0
				valor_reajuste_parcial_p = valor_inicial_p - valor_final_p_anterior
			else
				valor_reajuste_parcial_p = undefined
			endif

			if valor_final_v_anterior <> 0
				valor_reajuste_parcial_v = valor_inicial_v - valor_final_v_anterior
			else
				valor_reajuste_parcial_v = undefined
			endif

			if valor_inicial_p_anterior <> 0
				valor_reajuste_total_p = valor_inicial_p - valor_inicial_p_anterior
			else
				valor_reajuste_total_p = undefined
			endif

			if valor_inicial_v_anterior <> 0
				valor_reajuste_total_v = valor_inicial_v - valor_inicial_v_anterior
			else
				valor_reajuste_total_v = undefined
			endif

			valor_reajuste_parcial_v$ = fixed$(valor_reajuste_parcial_v, 5)
			valor_reajuste_parcial_p$ = fixed$(valor_reajuste_parcial_p, 5)
			valor_reajuste_total_v$ = fixed$(valor_reajuste_total_v, 5)
			valor_reajuste_total_p$ = fixed$(valor_reajuste_total_p, 5)


			select tabla_salida
			Append row
			num_filas = num_filas + 1

			Set string value... num_filas File 'name$'
			Set string value... num_filas IG 'gf$'

			if duracion_gf = undefined
				#printline duracion_gf es undefined
				Set string value... num_filas Duration NA
			else
				Set numeric value... num_filas Duration 'duracion_gf'
			endif

			if valor_inicial_p = undefined
				#printline valor_inicial_p es undefined
				Set string value... num_filas P_Initial_F0 NA
			else
				Set numeric value... num_filas P_Initial_F0 'valor_inicial_p'
			endif

			if valor_final_p = undefined
				#printline valor_final_p es undefined
				Set string value... num_filas P_Final_F0 NA
				#Set string value... num_filas P_Final_F0 'valor_final_p$'
			else
				Set numeric value... num_filas P_Final_F0 'valor_final_p'
			endif

			if pendiente_p = undefined
				#printline pendiente_p es undefined
				Set string value... num_filas P_Slope NA
			else
				Set numeric value... num_filas P_Slope 'pendiente_p'
			endif

			if valor_inicial_v = undefined
				#printline valor_inicial_v es undefined
				Set string value... num_filas V_Initial_F0 NA
			else
				Set numeric value... num_filas V_Initial_F0 'valor_inicial_v'
			endif

			if valor_final_v = undefined
				#printline valor_final_v es undefined
				Set string value... num_filas V_Final_F0 NA
			else
				Set numeric value... num_filas V_Final_F0 'valor_final_v'
			endif

			if pendiente_v = undefined
				#printline pendiente_v es undefined
				Set string value... num_filas V_Slope NA
			else
				Set numeric value... num_filas V_Slope 'pendiente_v'
			endif

			if rango_inicial_p_v = undefined
				#printline rango_inicial_p_v es undefined
				Set string value... num_filas Initial_F0_Range NA
			else
				Set numeric value... num_filas Initial_F0_Range 'rango_inicial_p_v'
			endif

			if rango_final_p_v = undefined
				#printline rango_final_p_v es undefined
				Set string value... num_filas Final_F0_Range NA
			else
				Set numeric value... num_filas Final_F0_Range 'rango_final_p_v'
			endif

			if valor_reajuste_parcial_v = undefined
				#printline valor_reajuste_parcial_v es undefined
				Set string value... num_filas Partial_F0_reset_V NA
			else
				Set numeric value... num_filas Partial_F0_reset_V 'valor_reajuste_parcial_v'
			endif

			if valor_reajuste_parcial_p = undefined
				#printline valor_reajuste_parcial_p es undefined
				Set string value... num_filas Partial_F0_reset_P NA
			else
				Set numeric value... num_filas Partial_F0_reset_P 'valor_reajuste_parcial_p'
			endif

			if valor_reajuste_total_v = undefined
				#printline valor_reajuste_total_v es undefined
				Set string value... num_filas Total_F0_reset_V NA
			else
				Set numeric value... num_filas Total_F0_reset_V 'valor_reajuste_total_v'
			endif

			if valor_reajuste_parcial_p = undefined
				#printline valor_reajuste_total_p es undefined
				Set string value... num_filas Total_F0_reset_P NA
			else
				Set numeric value... num_filas Total_F0_reset_P 'valor_reajuste_total_p'
			endif

			valor_final_p_anterior = valor_final_p
			valor_final_v_anterior = valor_final_v
			valor_inicial_p_anterior = valor_inicial_p
			valor_inicial_v_anterior = valor_inicial_v

			select textgrid_provisional
			plus tabla_p
			plus tabla_v
			Remove
			
		endif
						
		
	endfor
					
	select tabla_salida

	nombre_tabla_salida$ = "tabla_valores_F0_globales"
	
	nombre_completo_fichero_salida$ = directorio_salida$+"/"+name$+".global"

	Write to table file... 'nombre_completo_fichero_salida$'
	Rename... 'nombre_tabla_salida$'

endproc


procedure TipoSonido etiqueta_sonido$ alphabet$

# printline Etiqueta sonido: 'etiqueta_sonido$'

if alphabet$ = "SAMPA"

	if etiqueta_sonido$ = "..." or etiqueta_sonido$ = "_" or etiqueta_sonido$ = "#" or etiqueta_sonido$ = ""

		tipo_sonido$ = "Silencio"

	else

		#if etiqueta_sonido$ = "a_&quot" or etiqueta_sonido$ = "e_&quot" or etiqueta_sonido$ = "E_&quot" or etiqueta_sonido$ = "i_&quot" or etiqueta_sonido$ = "o_&quot" or etiqueta_sonido$ = "O_&quot" or etiqueta_sonido$ = "u_&quot" or etiqueta_sonido$ = "@_&quot" or etiqueta_sonido$ = "6_&quot" or etiqueta_sonido$ = "U_&quot" or etiqueta_sonido$ = "i~_&quot" or etiqueta_sonido$ = "e~_&quot" or etiqueta_sonido$ = "6~_&quot" or etiqueta_sonido$ = "o~_&quot" or etiqueta_sonido$ = "u~_&quot" or etiqueta_sonido$ = "I_&quot"

		if etiqueta_sonido$ = "a_&quot" or etiqueta_sonido$ = "A_&quot" or etiqueta_sonido$ = "2_&quot" or etiqueta_sonido$ = "9_&quot" or etiqueta_sonido$ = "e_&quot" or etiqueta_sonido$ = "E_&quot" or etiqueta_sonido$ = "i_&quot" or etiqueta_sonido$ = "y_&quot" or etiqueta_sonido$ = "o_&quot" or etiqueta_sonido$ = "O_&quot" or etiqueta_sonido$ = "u_&quot" or etiqueta_sonido$ = "a~_&quot" or etiqueta_sonido$ = "9~_&quot" or etiqueta_sonido$ = "e~_&quot" or etiqueta_sonido$ = "o~_&quot" or etiqueta_sonido$ = "@_&quot"

			tipo_sonido$ = "VocalTonica"

		else

			#if etiqueta_sonido$ = "a_%" or etiqueta_sonido$ = "e_%" or etiqueta_sonido$ = "E_%" or etiqueta_sonido$ = "i_%" or etiqueta_sonido$ = "o_%" or etiqueta_sonido$ = "O_%" or etiqueta_sonido$ = "u_%" or etiqueta_sonido$ = "@_%" or etiqueta_sonido$ = "a_&#37" or etiqueta_sonido$ = "e_&#37" or etiqueta_sonido$ = "E_&#37" or etiqueta_sonido$ = "i_&#37" or etiqueta_sonido$ = "o_&#37" or etiqueta_sonido$ = "O_&#37" or etiqueta_sonido$ = "u_&#37" or etiqueta_sonido$ = "@_&#37" or etiqueta_sonido$ = "6_&#37" or etiqueta_sonido$ = "U_&#37" or etiqueta_sonido$ = "i~_&#37" or etiqueta_sonido$ = "e~_&#37" or etiqueta_sonido$ = "6~_&#37" or etiqueta_sonido$ = "o~_&#37" or etiqueta_sonido$ = "u~_&#37" or etiqueta_sonido$ = "I_&#37"

			if etiqueta_sonido$ = "a_%" or etiqueta_sonido$ = "A_%" or etiqueta_sonido$ = "2_%" or etiqueta_sonido$ = "9_%" or etiqueta_sonido$ = "e_%" or etiqueta_sonido$ = "E_%" or etiqueta_sonido$ = "i_%" or etiqueta_sonido$ = "y_%" or etiqueta_sonido$ = "o_%" or etiqueta_sonido$ = "O_%" or etiqueta_sonido$ = "u_%" or etiqueta_sonido$ = "a~_%" or etiqueta_sonido$ = "9~_%" or etiqueta_sonido$ = "e~_%" or etiqueta_sonido$ = "o~_%" or etiqueta_sonido$ = "@_%"

				tipo_sonido$ = "VocalTonica2"

			else

				#if etiqueta_sonido$ = "a" or etiqueta_sonido$ = "e" or etiqueta_sonido$ = "E" or etiqueta_sonido$ = "i" or etiqueta_sonido$ = "o" or etiqueta_sonido$ = "O" or etiqueta_sonido$ = "u" or etiqueta_sonido$ = "@" or etiqueta_sonido$ = "6" or etiqueta_sonido$ = "U" or etiqueta_sonido$ = "i~" or etiqueta_sonido$ = "e~" or etiqueta_sonido$ = "6~" or etiqueta_sonido$ = "o~" or etiqueta_sonido$ = "u~" or etiqueta_sonido$ = "I"

				if etiqueta_sonido$ = "a" or etiqueta_sonido$ = "A" or etiqueta_sonido$ = "2" or etiqueta_sonido$ = "9" or etiqueta_sonido$ = "e" or etiqueta_sonido$ = "E" or etiqueta_sonido$ = "i" or etiqueta_sonido$ = "y" or etiqueta_sonido$ = "o" or etiqueta_sonido$ = "O" or etiqueta_sonido$ = "u" or etiqueta_sonido$ = "a~" or etiqueta_sonido$ = "9~" or etiqueta_sonido$ = "e~" or etiqueta_sonido$ = "o~" or etiqueta_sonido$ = "@"

					tipo_sonido$ = "VocalAtona"

				else
			
					if etiqueta_sonido$ = "w" or etiqueta_sonido$ = "j" or etiqueta_sonido$ = "H" or etiqueta_sonido$ = "j~" or etiqueta_sonido$ = "w~"

						tipo_sonido$ = "Semivocal"

					else

						tipo_sonido$ = "Consonante"

					endif

				endif

			endif

		endif

	endif
	
else

	if alphabet$ = "IPA"

		if etiqueta_sonido$ = "||" or etiqueta_sonido$ = "|" or etiqueta_sonido$ = ""
		
			tipo_sonido$ = "Silencio"

		else


			if etiqueta_sonido$ = "\'1a" or etiqueta_sonido$ = "\'1\as" or etiqueta_sonido$ = "\'1\o/" or etiqueta_sonido$ = "\'1\oe" or etiqueta_sonido$ = "\'1e" or etiqueta_sonido$ = "\'1\ef" or etiqueta_sonido$ = "\'1i" or etiqueta_sonido$ = "\'1y" or etiqueta_sonido$ = "\'1o" or etiqueta_sonido$ = "\'1\ot" or etiqueta_sonido$ = "\'1u" or etiqueta_sonido$ = "\'1a\~^" or etiqueta_sonido$ = "\'1\oe\~^" or etiqueta_sonido$ = "\'1e\~^" or etiqueta_sonido$ = "\'1o\~^" or etiqueta_sonido$ = "\'1\sw"

				tipo_sonido$ = "VocalTonica"

			else


				if etiqueta_sonido$ = "\'2a" or etiqueta_sonido$ = "\'2\as" or etiqueta_sonido$ = "\'2\o/" or etiqueta_sonido$ = "\'2\oe" or etiqueta_sonido$ = "\'2e" or etiqueta_sonido$ = "\'2\ef" or etiqueta_sonido$ = "\'2i" or etiqueta_sonido$ = "\'2y" or etiqueta_sonido$ = "\'2o" or etiqueta_sonido$ = "\'2\ot" or etiqueta_sonido$ = "\'2u" or etiqueta_sonido$ = "\'2a\~^" or etiqueta_sonido$ = "\'2\oe\~^" or etiqueta_sonido$ = "\'2e\~^" or etiqueta_sonido$ = "\'2o\~^" or etiqueta_sonido$ = "\'2\sw"

					tipo_sonido$ = "VocalTonica2"

				else

					if etiqueta_sonido$ = "a" or etiqueta_sonido$ = "\as" or etiqueta_sonido$ = "\o/" or etiqueta_sonido$ = "\oe" or etiqueta_sonido$ = "e" or etiqueta_sonido$ = "\ef" or etiqueta_sonido$ = "i" or etiqueta_sonido$ = "y" or etiqueta_sonido$ = "o" or etiqueta_sonido$ = "\ot" or etiqueta_sonido$ = "u" or etiqueta_sonido$ = "a\~^" or etiqueta_sonido$ = "\oe\~^" or etiqueta_sonido$ = "e\~^" or etiqueta_sonido$ = "o\~^" or etiqueta_sonido$ = "\sw"

						tipo_sonido$ = "VocalAtona"

					else
				
						if etiqueta_sonido$ = "w" or etiqueta_sonido$ = "j" or etiqueta_sonido$ = "\ht" or etiqueta_sonido$ = "j\~^" or etiqueta_sonido$ = "w\~^"

							tipo_sonido$ = "Semivocal"

						else

							tipo_sonido$ = "Consonante"

						endif

					endif

				endif

			endif

		endif
		
	else
	
		printline Alfabeto no reconocido
	
	endif

endif

# printline Tipo sonido: 'tipo_sonido$'

endproc
