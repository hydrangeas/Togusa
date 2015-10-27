#!/bin/sh

# 設定の注意
# INPUTパスは直下のファイル内のファイルしか確認しない
#  -> もしも複数のパスを対象とする場合は、INPUTパスを配列化する（対応済）

#-------------------------------------------------------------------------
# Windows用の設定
#-------------------------------------------------------------------------
###
###
WIN_FFMPEG="D:/89_bash/bin/ffmpeg.exe"
WIN_FFPROBE="D:/89_bash/bin/ffprobe.exe"
WIN_OUTPUT="D:/10_SBKL/002_版権共有情報/00_画像切抜き/02_全フレーム_360x200"
WIN_INPUT="./sample"
WIN_MKDIR="mkdir -p"
WIN_SCALE="360:200"
WIN_SUPER="./ass/super_24.ass"
###
###
#-------------------------------------------------------------------------
# Mac用の設定
#-------------------------------------------------------------------------
###
###
MAC_FFMPEG="/usr/local/bin/ffmpeg"
MAC_FFPROBE="/usr/local/bin/ffprobe"
MAC_OUTPUT="./output"
MAC_INPUT="./sample"
MAC_MKDIR="mkdir -p"
MAC_SCALE="360:200"
MAC_SUPER="./ass/super_24.ass"
###
###
#=========================================================================



#-------------------------------------------------------------------------
# GLOBAL FUNCTION
#-------------------------------------------------------------------------
function stdout() {
  if [ $EXPECT_OUTPUT ]; then
    echo $1
  fi
}
function stderr() {
  echo $1 >&2
  exit $2
}
#=END OF GLOBAL_FUNCTION==================================================


#
# OSの判別
#
if [ "$(uname)" == 'Darwin' ]; then
  OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  OS='Linux'
  stderr "I am so sorry. This platform is not supported.." 1
elif [ "$(expr substr $(uname -s) 1 10)" == 'MINGW32_NT' ]; then
  OS='Cygwin'
else
  stderr "Your platform ($(uname -a)) is not supported." 1
fi

#
# オプションの処理
#
while getopts ":ab:hi:m:o:stvw-:" opt; do
  case "$opt" in
    -)
      case "${OPTARG}" in
        help|version)
          IS_HELP=1
          ;;
        verbose)
          EXPECT_OUTPUT=1
          ;;
      esac
      ;;
    a)
      #全フレームを出力する
      #指定されない場合は1秒毎
      IS_ALL=1
      ;;
    b)
      #FFPROBEの実行パスを指定する
      USER_FFPROBE="${OPTARG}"
      ;;
    h)
      #ヘルプを表示する
      IS_HELP=1
      ;;
    i)
      #入力ディレクトリパスを指定する
      USER_INPUT="${OPTARG}"
      ;;
    m)
      #FFMPEGの実行パスを指定する
      USER_FFMPEG="${OPTARG}"
      ;;
    o)
      #出力ディレクトリパスを指定する
      USER_OUTPUT="${OPTARG}"
      ;;
    s)
      #字幕の付与を指定する
      IS_SUPER=1
      ;;
    t)
      #試験用に1動画のみを出力する
      IS_TEST=1
      EXPECT_OUTPUT=1
      ;;
    v)
      #ログ出力を指定する
      EXPECT_OUTPUT=1
      ;;
    w)
      WAIT=1
      ;;
  esac
done

#
# HELPを表示して終了
#
if [ $IS_HELP ]; then
  stdout "usage make_thumbnail.sh [:ab:hi:m:o:stvw-:]" 0
fi

#
# 初期設定を反映
#
if [ $OS == 'Mac' ]; then
  #
  FFMPEG=$MAC_FFMPEG
  FFPROBE=$MAC_FFPROBE
  OUTPUT=$MAC_OUTPUT
  INPUT=$MAC_INPUT
  MKDIR=$MAC_MKDIR
  SCALE=$MAC_SCALE
  SUPER=$MAC_SUPER
elif [ $OS == 'Linux' ]; then
  # TODO: いつか。
  FFMPEG=
  FFPROBE=
  OUTPUT=
  INPUT=
  MKDIR=
  SCALE=
  SUPER=
else
  # Windows
  FFMPEG=$WIN_FFMPEG
  FFPROBE=$WIN_FFPROBE
  OUTPUT=$WIN_OUTPUT
  INPUT=$WIN_INPUT
  MKDIR=$WIN_MKDIR
  SCALE=$WIN_SCALE
  SUPER=$WIN_SUPER
fi

#
# オプションを反映
#
if [ $USER_FFMPEG ]; then
  FFMPEG=$USER_FFMPEG
fi
if [ $USER_FFPROBE ]; then
  FFPROBE=$USER_FFPROBE
fi
if [ $USER_OUTPUT ]; then
  OUTPUT=$USER_OUTPUT
fi
if [ $USER_INPUT ]; then
  INPUT=$USER_INPUT
fi

#
# コマンドの存在確認
#   厳密にやる場合は [ -x /usr/local/bin/ffmpeg ] などとすること
#   http://www.atmarkit.co.jp/flinux/rensai/smart_shell/03/01.html
#
if type $FFMPEG 2>/dev/null 1>/dev/null; then
  stdout "[OK]      ${FFMPEG} is exists."
else
  stderr "[NG]      ${FFMPEG} is not exists. aborted.." 2
fi
if type $FFPROBE 2>/dev/null 1>/dev/null; then
  stdout "[OK]      ${FFPROBE} is exists."
else
  stderr "[NG]      ${FFPROBE} is not exists. aborted.." 2
fi

# 字幕ファイル用を作成する
if [ $IS_SUPER ]; then
  if [ -e $SUPER ]; then
    #字幕ファイルが存在するので何もしない
    SUCCESSED=1
  elif [ -e ./make_ass.sh ]; then
    stdout "[`date`] ASSファイル作成処理を開始.. （時間がかかります）"
    sh ./make_ass.sh
    stdout "[`date`] ASSファイル作成完了"
  else
    stderr "ASSファイル作成スクリプトがありません" 8
  fi
fi

#
#
# 変換処理本体
#
#

# INPUTパス分、ループする
for input_path in ${INPUT[@]}; do

  #
  # 入力ディレクトリの存在確認
  #
  if [ -e $input_path ]; then
    if [ -d $input_path ]; then
      # 問題なかった
      SUCCESSED=1
    else
      stdout "[NG]      ${input_path} is not a directory. next.."
    fi
  else
    stdout "[NG]      ${input_path} is not exists. next.."
    continue
  fi

  files=$(ls $input_path)
  for file in $files; do

    #フルパス
    file_path="${input_path}/$file"

    #ファイルが動画でない場合は次のファイルを確認する
    if $FFPROBE $file_path -v quiet; then
      SUCCESSED=1
    else
      stdout "[NG]      ${file_path} is not a movie file. next.."
      continue
    fi

    #出力先ディレクトリを作成する
    output_path="$OUTPUT/$file"
    if $MKDIR $output_path; then
      SUCCESSED=1
      #字幕を入れる場合はここで作成する
      if [ $IS_SUPER ]; then
        $FFMPEG -i $file_path -vf ass=$SUPER $output_path/$file -v quiet -y
        file_path=$output_path/$file
        #
        # 以下のように怒られた場合、バイナリがlibassオプションでコンパイルされていない可能性がある
        # No such filter: 'ass'
        #
        # 解決方法
        # $ brew reinstall ffmpeg --with-libass
        #
      fi
    else
      stderr "[NG]      ${output_path} is not created. aborted.." 3
    fi

    #動画再生時間（秒）を取得する
    duration=$($FFPROBE -show_entries format=duration -v quiet -of csv="p=0" -i ${file_path} | sed -e 's/\.[0-9]*$//g')

    #--- 処理開始 ---
    stdout "[`date`] ${file_path}の処理を開始.. （動画の再生時間：${duration}秒）"
    if [ $IS_ALL ]; then
      #全フレーム、PNGで出力
      $FFMPEG -i $file_path -vf scale=$SCALE $output_path/${file}_%05d.png -loglevel quiet -y
    else
      #1秒毎、JPEGで出力
      $FFMPEG -i $file_path -vf fps=1 -f image2 $output_path/${file}_%05d.png -loglevel quiet -y
    fi
    #--- 処理終了 ---

    if [ $IS_TEST ]; then
      stderr "テストオプションが存在するため終了します" 9
    fi
  done
done
stdout "[`date`] 全ての処理を終了"

# Exits this process
on_die() {
  exit 0
}
trap 'on_die' SIGQUIT SIGTERM

# If the wait flag is set, don't exit this process until Atom tells it to.
# -> ?
if [ $WAIT ]; then
  while true; do
    sleep 1
  done
fi
