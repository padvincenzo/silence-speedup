# Silence Speedup
Velocizza i tuoi video velocizzando (o rimuovendo) i silenzi, tramite FFmpeg.

Speed-up your videos speeding-up (or removing) silences, using FFmpeg.

<img src="screenshots/Screen%2300%20Homescreen.png" alt="Homescreen" width="410"/>

## Come funziona / How it works

For each video, this program:

1.  Run ffmpeg with silencedetect filter, in order to get the list of silences' start/end timestamps.

2.  Using that list, split the original video in a tmp folder, applying a speed filter, if any.

3.  Concatenate all the fragments generated before.

Per ogni video, questo programma:

1. Eseguirà ffmpeg con il filtro silencedetect, per ottenere l'elenco dei timestamp di inizio/fine dei silenzi.

2. Usando quell'elenco, dividerà il video originale dentro una cartella tmp, applicando un filtro di velocità, se presente.

3. Concatena tutti i frammenti generati precedentemente.

### Note

Al termine dell'esecuzione, il programma non pulisce automaticamente la cartella tmp.

At the end of execution, the program does not automatically clean the tmp folder.

## Requisiti / Requirements
Per le versioni ``win32`` e ``darwin`` l'eseguibile di ``ffmpeg`` è incluso nel pacchetto; su ``linux`` è necessario che sia installato manualmente.

In ``win32`` and ``darwin`` versions ``ffmpeg`` executable is included in the package; on ``linux`` you need to install it manually.

## Crediti / Credits
Questo software usa delle librerie del progetto FFmpeg, che io non possiedo, sotto la licenza LGPLv2.1.

This software uses libraries from the FFmpeg project, which I do not own, under the LGPLv2.1.

## Screenshots

1.  Inseriti alcuni video
<img src="screenshots/Screen%2301%20Video%20added.png" alt="Video added" width="410"/>

2.  Zona elenco dei video
<img src="screenshots/Screen%2302%20Video%20list.png" alt="Video list" width="410"/>

3.  Aggiungere altri video (singolarmente, per cartella o trascinandoli nella zona elenco video)
<img src="screenshots/Screen%2303%20Add%20videos.png" alt="Add videos" width="410"/>

4.  Zona configurazione
<img src="screenshots/Screen%2304%20Video%20options.png" alt="Video options" width="410"/>

5.  Start
<img src="screenshots/Screen%2305%20Start%20the%20program.png" alt="Start" width="410"/>

6.  "Shell"
<img src="screenshots/Screen%2306%20Shell.png" alt="Shell" width="410"/>

7.  Progress bar
<img src="screenshots/Screen%2307%20Progress%20bar.png" alt="Progress bar" width="410"/>

8.  Visualizza una interfaccia minimale
<img src="screenshots/Screen%2308%20Show%20minimal%20interface.png" alt="Show minimal interface" width="410"/>

9.  Interfaccia minimale
<img src="screenshots/Screen%2309%20Minimal%20interface.png" alt="Minimal interface" width="410"/>

10. Video completati
<img src="screenshots/Screen%2310%20Completed%20videos.png" alt="Completed videos" width="410"/>

11. Video in corso
<img src="screenshots/Screen%2311%20Current%20video.png" alt="Current video" width="410"/>

12. Visualizza interfaccia di default
<img src="screenshots/Screen%2312%20Show%20default%20interface.png" alt="Show default interface" width="410"/>

