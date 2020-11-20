# Silence Speedup
Velocizza i tuoi video velocizzando (o rimuovendo) i silenzi, tramite FFmpeg.

![Schermata principale](screenshots/Homescreen.png)

*Leggi in altre lingue: [Inglese](README.md), [Italiano](README.it.md).*

## Indice dei contenuti
  - [Installazione](#installazione)
    - [Requisiti](#requisiti)
  - [Come funziona](#come-funziona)
    - [Note](#note)
  - [Crediti](#crediti)

## Installazione
Questo programma è stato impacchettato con [``electron-packager``](https://electron.github.io/electron-packager/master/), e dovrebbe funzionare così com'è. Se vuoi invece eseguire il programma dal codice sorgente:

```
$ git clone https://github.com/padvincenzo/silence-speedup
$ cd silence-speedup
$ npm install
$ npm start
```

### Requisiti
Questo programma richiede [ffmpeg](https://ffmpeg.org/download.html) per processare i tuoi video. Se è già installato, devi solo aprire il programma e modificare la configurazione dal pulsante di configurazione.

Se desideri invece eseguire questo programma dal codice sorgente allora hai bisogno di installare [NodeJS](https://nodejs.org/en/).

## Come funziona
Per ogni video, questo programma:

1. Eseguirà ffmpeg con il filtro ``silencedetect``, per ottenere l'elenco dei timestamp di inizio/fine dei silenzi.

    ```
    <ffmpeg bin> -hide_banner -vn \
      -ss 0.00 -i <Input file> \
      -af silencedetect=n=<threshold>:d=<duration> \
      -f null -
    ```

2. Usando quell'elenco, dividerà il video originale dentro una cartella tmp, applicando un filtro di velocità, se presente.

    ```
    <ffmpeg bin> -hide_banner -loglevel warning -stats \
      -ss <Start time> -to <End time> -i <Input file> \
      -filter_complex "[0:v]<setpts filter>[v];[0:a]<atempo filter>[a]" \
      -map [v] -map [a] <Output fragment>
    ```

3. Concatena tutti i frammenti generati precedentemente.

    ```
    <ffmpeg bin> -hide_banner -loglevel warning -stats \
      -f concat -safe 0 \
      -i <Fragment list file> \
      -c copy \
      -map v -map a <Output file> -y
    ```

### Note
Al termine dell'esecuzione, il programma non pulisce automaticamente la cartella tmp.

## Crediti
Questo software usa delle librerie del progetto FFmpeg, che io non possiedo, sotto la licenza LGPLv2.1.
