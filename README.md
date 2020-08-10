# namemkv

Creates automated names for mkv files in the form of `<name>.<year>.DUB.<dub1>.<dub2>.SUB.<sub1>.<sub2>.<source>.<codec>.<height>p<framerate>f<bitdepth>b.mkv`
Example: `Big.Buck.Bunny.2008.DUB.eng.deu.ita.fra.spa.jpn.rus.ces.SUB.eng.deu.ita.dan.fin.nor.swe.fra.spa.jpn.rus.hrv.bul.ces.ron.tur.slv.BD.h265.2160p24f10b.mkv`

## Setup
Go to [sil.org](www.iso639-3.sil.org) and download the latest complete UTF-8 code table. Example:
```
curl -O https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3_Code_Tables_20200130.zip
unzip iso-639-3_Code_Tables_20200130.zip
```

## Run
```
./namemkv.sh /path/to/mkv/video.mkv
````
