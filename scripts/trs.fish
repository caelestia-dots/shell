#!/usr/bin/env fish

if test (count $argv) -lt 1
    echo "Usage: $(status basename) raw|ll_CC"
    exit 1
end

cd (status dirname)/.. || exit 1
set -l tr_dir plugin/src/Caelestia/Translations/trs
set -g pot_file $tr_dir/raw.pot
mkdir -p $tr_dir

function gen -a lang
    xgettext -L $lang \
        -o $pot_file \
        --join-existing \
        --from-code=UTF-8 \
        --no-wrap \
        --no-location \
        --add-comments=TRANSLATORS: \
        --package-name=caelestia-shell \
        -k \
        -ktr:1 -ktrCtx:1c,2 \
        -kmark:1 -kmarkCtx:1c,2 \
        (string match -v 'build/*' $argv[2..])
end

if test $argv[1] = raw || ! test -f $pot_file
    echo > $pot_file
    gen JavaScript **.qml
    gen C++ **.cpp **.hpp

    # Strip js format then tag qt-format
    perl -00 -i -pe '
        s/^#, javascript-format\n//m;
        s/, javascript-format//;

        if (/%L?[1-9]/ && !/^#,.*qt-format/m) {
            s/^#,/#, qt-format,/m or s/^(?=msgctxt |msgid )/#, qt-format\n/m
        }
    ' $pot_file
end

if test $argv[1] != raw
    msginit --locale=$argv[1] \
        --input=$pot_file \
        --output=$tr_dir/$argv[1].po
end
