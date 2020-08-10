#!/bin/bash
[ -z $(command -v jq) ] && echo "please install jq" && exit 1

[ -z "$1" ] && echo "usage: namemkv file.mkv" && exit 1
json=$(mediainfo --Output=JSON "$1")

declare -A lang
lang["is"]="isl"
lang["ice"]="isl"
lang["nb"]="nob"
lang["nob"]="nob"
lang["no"]="nor"
lang["nor"]="nor"
lang["sv"]="swe"
lang["swe"]="swe"
lang["fi"]="fin"
lang["fin"]="fin"
lang["en"]="eng"
lang["eng"]="eng"
lang["fr"]="fra"
lang["fra"]="fra"
lang["fre"]="fra"
lang["nl"]="nld"
lang["nld"]="nld"
lang["dut"]="nld"
lang["da"]="dan"
lang["dan"]="dan"
lang["de"]="deu"
lang["deu"]="deu"
lang["ger"]="deu"
lang["pl"]="pol"
lang["pol"]="pol"
lang["cs"]="ces"
lang["ces"]="ces"
lang["cze"]="ces"
lang["sk"]="slk"
lang["slk"]="slk"
lang["slo"]="slk"
lang["sl"]="slv"
lang["slv"]="slv"
lang["it"]="ita"
lang["ita"]="ita"
lang["es"]="spa"
lang["spa"]="spa"
lang["ca"]="cat"
lang["cat"]="cat"
lang["pt"]="por"
lang["por"]="por"
lang["et"]="est"
lang["est"]="est"
lang["lt"]="lit"
lang["lit"]="lit"
lang["lv"]="lav"
lang["lav"]="lav"
lang["hu"]="hun"
lang["hun"]="hun"
lang["el"]="ell"
lang["ell"]="ell"
lang["gre"]="ell"
lang["he"]="heb"
lang["heb"]="heb"
lang["ro"]="ron"
lang["rum"]="ron"
lang["ron"]="ron"
lang["hr"]="hrv"
lang["hrv"]="hrv"
lang["sr"]="srp"
lang["srp"]="srp"
lang["tr"]="tur"
lang["tur"]="tur"
lang["ru"]="rus"
lang["rus"]="rus"
lang["uk"]="ukr"
lang["ukr"]="ukr"
lang["bg"]="bul"
lang["bul"]="bul"
lang["ar"]="ara"
lang["ara"]="ara"
lang["hi"]="hin"
lang["hin"]="hin"
lang["zh"]="zho"
lang["chi"]="zho"
lang["zho"]="zho"
lang["ko"]="kor"
lang["kor"]="kor"
lang["th"]="tha"
lang["tha"]="tha"
lang["ja"]="jpn"
lang["jpn"]="jpn"
lang["id"]="ind"
lang["ind"]="ind"
lang["ms"]="msa"
lang["may"]="msa"
lang["msa"]="msa"
lang["ta"]="tam"
lang["tam"]="tam"
lang["te"]="tel"
lang["tel"]="tel"


i=-1
while (true)
do
	echo $i
	out=$(echo $json | jq ".media.track[$i].ID" | tr -d '"')
	echo $out
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
		if [ -z "${lang["$alang"]}" ]
		then
			echo unmapped $alang
		else
			alang="${lang["$alang"]}"
		fi
		echo Language: "$alang"
		DUB[$idub]="$alang"
		idub=$((idub + 1))
	fi

	if [ "$type" == "Text" ]
	then
		tlang=$(echo $json | jq ".media.track[$i].Language" | tr -d '"')
		if [ -z "${lang["$tlang"]}" ]
		then
			echo unmapped $tlang
			exit 2
		else
			tlang="${lang["$tlang"]}"
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
echo $name".DUB.$DUB""SUB.$SUB$VID$format"
