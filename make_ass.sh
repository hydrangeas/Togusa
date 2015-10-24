#!/bin/sh

#動画の既定フレーム数(fps)
MOVIE_FRAME=24
#出力パス
OUTPUT_PATH=./ass
#出力ファイル
ASS_FILE=${OUTPUT_PATH}/super_${MOVIE_FRAME}.ass

#ASSヘッダ
ASS_HEADER=`cat <<EO_ASS_HEADER
[Script Info]
Title: test ass
Synch Point: 2
ScriptType: v4.00+
Collisions: Normal
ScaledBorderAndShadow: No
PlayResX: 1920
PlayResY: 1080
Timer: 3.000
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,MS Gothic,50,&H00ffffff,&H0000ffff,&H00000000,&H80000000,-1,-1,0,0,200,200,0,0.00,1,2,3,2,20,20,40,128

[Events]
Format: Layer, Start, End, Style, Actor, MarginL, MarginR, MarginV, Effect, Text
EO_ASS_HEADER
`

#動画のフレーム数によって開始と終了時間を変更する
#(切り出しの際にそのフレーム数目が入っている)
# ex) 24fps=46.1ms毎に切り替わるので、0〜30ms:frame-0 40〜70ms:frame-1 ..
case $MOVIE_FRAME in
  23)
    ;;
  24)
    start_time=(0 4  8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 77 81 85 89 93)
    end_time=(  3 7 11 15 19 23 27 31 35 39 43 47 51 55 59 63 67 71 76 80 84 88 92 99)
    ;;
  25)
    ;;
  *)
    start_time=(0 4  8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 77 81 85 89 93)
    end_time=(  3 7 11 15 19 23 27 31 35 39 43 47 51 55 59 63 67 71 76 80 84 88 92 99)
    ;;
esac

#出力先作成
mkdir -p $OUTPUT_PATH
#ヘッダ出力
echo $ASS_HEADER > $ASS_FILE

#0〜9時間まで
for h in {0..9}
do
  #0〜59分まで
  for m in {0..59}
  do
    #0〜59秒まで
    for s in {0..59}
    do
      #フレーム数分
      for ((f=0; f < $MOVIE_FRAME; f++));
      do
        #字幕の出力形式
        printf "Dialogue: 0,%d:%03d:%02d.%02d,%d:%02d:%02d.%02d, Voice01,,0000,0000,0000,,%02d:%02d:%02d:%02d\n" $h $m $s ${start_time[$f]} $h $m $s ${end_time[$f]} $h $m $s $f >> $ASS_FILE
      done #for/フレーム
    done #for/秒
  done #for/分
done #for/時

exit 0
