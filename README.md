#  MelAn                              						              			  							  

#  AUTHOR: Juan María Garrido Almiñana															  
#  VERSION: 3.0 (10/10/2017)															

# Script to label the F0 contour of a wav file with tonal events labels					
# and to extract its melodic patterns											

# The script needs as input:													
#	- a wav file with the speech wave of the input utterance							
#	- a TextGrid file with the necessary annotation of the input utterance				

# Input TextGrid files must include five tiers containing:								
#	- phonetic transcription (SAMPA or IPA) aligned with the signal						
#	- syllable segmentation, with indication of stressed syllables						
#	- stress group segmentation															
#	- intonation group segmentation														
#	- breath group segmentation															

# The script adds to every input TextGrid file  three tiers containing:																
#	- the F0 values of the inflection points in the stylised F0 contour					
#	  time-aligned with the speech wave													
#	- the tonal labels, time-aligned with the speech wave								
#	- the pattern labels																

# It creates also two new files in the output directory 
# containing the output of the pattern extraction process:
#	-  a 'local' file containing the ordered list of local patterns making up its contour
#	- a 'global' file containing a set of values describing the individual P and V regression lines, 
#	  the F0 range and the F0 reset for each IG of the utterance

# Arguments: 																			
# 	1) Input wav file																		
# 	2) Directory of the wav file															
# 	3) Input TextGrid file			
# 	4) Directory of the TextGrid file																								
# 	5) Output directory																	
# 	6) Number of tier containing phonetic transcription in the input TextGrid				
# 	7) Number of tier containing syllable segmentation in the input TextGrid				
# 	8) Number of tier containing stress group segmentation in the input TextGrid			
# 	9) Number of tier containing intonation group segmentation in the input TextGrid		
# 	10) Number of tier containing breath group segmentation in the input TextGrid			
# 	11) Phonetic alphabet of the input phonetic transcription ('IPA' or 'SAMPA')							
# 	12) Pause label in the input TextGrid 												


#  Copyright (C) 2017  Juan María Garrido Almiñana                       	 			
#                                                                        				
#    This program is free software: you can redistribute it and/or modify 				
#    it under the terms of the GNU General Public License as published by 				
#    the Free Software Foundation, either version 3 of the License, or    				
#    (at your option) any later version.                                  				
#                                                                         				
#    This program is distributed in the hope that it will be useful,      			
#    but WITHOUT ANY WARRANTY; without even the implied warranty of       				
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       				
#    GNU General Public License for more details.                         				
#                                                                         				
#    See http://www.gnu.org/licenses/ for more details.                   				
