#!/bin/bash
isoorig=iso-639-3_20200130.tab # sourced from www.iso639-3.sil.org ; tested with https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3_Code_Tables_20200130.zip
isotab=iso-639-3_20200130_namemkv.tab
online=1
[ -z $(command -v jq) ] && echo "please install jq" && exit 1
[ -z $(command -v hq) ] && echo "please install hq to read online titles" && online=0
[ -z $(command -v curl) ] && echo "please install curl to read online titles" && online=0
[ ! -f "$isoorig" ] && [ ! -f "$isotab" ] && echo "iso language table not present, please download from " && exit 1
[ ! -f "$isotab" ] && cat iso-639-3_*.tab|awk -F "\t" '{print " " $1 " " $2 " " $3 " " $4 " "}' > "$isotab"
[ -z "$1" ] && echo "usage: namemkv file.mkv" && exit 1
json=$(mediainfo --Output=JSON "$1")

i=-1
while (true)
do
	#echo $i
	out=$(echo $json | jq ".media.track[$i].ID" | tr -d '"')
	#echo $out
	[ "$out" != "null" ] && break
	i=$((i - 1))
done
lastindex=$out
echo lastindex: $out

vids=$(echo $json | jq '.media.track[0].VideoCount')
dubs=$(echo $json | jq '.media.track[0].AudioCount')
subs=$(echo $json | jq '.media.track[0].TextCount')

format=$(echo $json | jq '.media.track[0].Format'|tr -d '"')
echo Format: $format
if [ "$format" == "Matroska" ]
then
	format='mkv'
else
		echo format not matroska
		exit 1
fi

name=$(echo $json | jq '.media.track[0].Title' | tr -d '"' | tr ' ' '.' | sed 's/:/.-/g')
echo "Name: $name"

year=""
if [ "$online" == "1" ]
then
	yeardata=$(echo $json | jq '.media.track[0].Title' | tr -d '"' | tr ' ' '+')
	yeardata=$(curl https://www.imdb.com/find\?q\="$yeardata"\&ref_\=nv_sr_sm)
	yeardata=$(cat test)
	yeardata=$(echo $yeardata | hq td data | sed -n 2p | grep -o '(.*)' | grep -o '[0-9]*')
	[ ! -z "$yeardata"	] && [ -z "$(echo $yeardata | grep -E '[0-9]{5}')" ] && [ ! -z "$(echo $yeardata | grep -E '[0-9]{4}')" ] && echo releaseyear: $yeardata && year='.'$yeardata
fi

VID=""
DUB=()
idub=0
SUB=()
isub=0
i=1
while [ $i -le $lastindex ]
do
	type=$(echo $json | jq ".media.track[$i].\"@type\"" | tr -d '"')
	if [ "$type" == "Video" ]
	then
		vformat=$(echo $json | jq ".media.track[$i].Format" | tr -d '"')
		case $vformat in
			AVC)
				vformat="h264"
      	;;
			HEVC)
				vformat="h265"
     		;;
		esac
		echo Videoformat: "$vformat"
		vheight=$(echo $json | jq ".media.track[$i].Height" | tr -d '"')
		vdepth=$(echo $json | jq ".media.track[$i].BitDepth" | tr -d '"')
		vframe=$(echo $json | jq ".media.track[$i].FrameRate" | tr -d '"')
		[ "$vframe" == "23.976" ] && vframe="24"
		vsrc=$(echo $json | jq ".media.track[$i].extra.OriginalSourceMedium" | tr -d '"')
		[ "$vsrc" == "Blu-ray" ] && vsrc="BD"
		VID="$VID""$vsrc"".""$vformat"".""$vheight""p""$vframe""f""$vdepth""b""."
	fi

	if [ "$type" == "Audio" ]
	then
		alang=$(echo $json | jq ".media.track[$i].Language" | tr -d '"')
		count=$(grep -E " $alang " "$isotab" | wc -l)
		[ $count -gt 1 ] && echo "more than one occurence of a language code: $alang" && exit 1
		rlang=$(grep -E " $alang " "$isotab"| awk -F " " '{print $1}')
		if [ -z "$rlang" ]
		then
			echo unmapped $alang
		else
			alang=$rlang
		fi
		echo Language: "$alang"
		DUB[$idub]="$alang"
		idub=$((idub + 1))
	fi

	if [ "$type" == "Text" ]
	then
		tlang=$(echo $json | jq ".media.track[$i].Language" | tr -d '"')
		count=$(grep -E " $tlang " "$isotab" | wc -l)
		[ $count -gt 1 ] && echo "more than one occurence of a language code: $tlang" && exit 1
		rlang=$(grep -E " $tlang " "$isotab"| awk -F " " '{print $1}')
		if [ -z "$rlang" ]
		then
			echo unmapped $tlang
			exit 2
		else
			tlang="$rlang"
		fi
		echo Language: "$tlang"
		SUB[$isub]="$tlang"
		isub=$((isub + 1))
	fi

	i=$((i + 1))
done

DUBu=($(echo ${DUB[@]} | tr ' ' '\n' | awk '!x[$0]++' | tr '\n' ' '))
echo DUB: "${DUBu[@]}"
SUBu=($(echo ${SUB[@]} | tr ' ' '\n' | awk '!x[$0]++' | tr '\n' ' '))
echo SUB: "${SUBu[@]}"

DUB=""
for i in ${DUBu[@]}
do
	DUB=$DUB"$i""."
done

SUB=""
for i in ${SUBu[@]}
do
	SUB=$SUB"$i""."
done
echo $name$year".DUB.$DUB""SUB.$SUB$VID$format"
