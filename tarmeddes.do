// Author: Igor Francetic
// Date: 19/02/2026
// This do-file creates the TARMED service descriptions dataset

clear all
// Set globals
global datain T:\AMBIZIONE\Data
global dataout T:\AMBIZIONE\WP2\Igor\dataout
import excel "$datain\Tariffs\LEISTUNG_TEXT.xlsx", sheet("LEISTUNG_TEXT") firstrow
duplicates drop LNR, force
save $dataout/tarmeddes, replace

/*
00.0020
00.0025
00.0026
00.0030
00.0131
00.0132
00.0133
00.0134
00.0136
00.0141
00.0142
00.0143
00.0144
00.0161
00.0162
00.0163
00.0164


