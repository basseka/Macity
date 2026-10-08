#!/bin/bash
# render.sh in.svg out.png : rendu x2 transparent, sans rognage du viewport
f="$1"; out="$2"
read W H < <(grep -oE 'width="[0-9]+" height="[0-9]+"' "$f" | head -1 | grep -oE '[0-9]+' | tr '\n' ' ')
[ -z "$W" ] && { W=1024; H=1024; }
tmp=$(mktemp --suffix=.html)
echo "<html><body style='margin:0;background:transparent'><img src='file://$(realpath "$f")' width=$W height=$H style='display:block'></body></html>" > $tmp
google-chrome --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 --force-device-scale-factor=2 --window-size=$((W+50)),$((H+300)) --screenshot="$out" "file://$tmp" >/dev/null 2>&1
python3 -c "from PIL import Image; im=Image.open('$out'); im.crop((0,0,$W*2,$H*2)).save('$out')"
rm $tmp
