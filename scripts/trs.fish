#!/usr/bin/env fish

if test (count $argv) -lt 1
    echo "Usage: $(status basename) raw|test|ll_CC"
    exit 1
end

cd (status dirname)/.. || exit 1
set -l tr_dir plugin/src/Caelestia/I18n/trs
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

function gen_trs
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

if test $argv[1] = raw
    gen_trs
    exit
end

test -f $pot_file || gen_trs

if test $argv[1] = test
    if test (count $argv) -lt 2
        echo "Usage: $(status basename) test <out_file>"
        exit 1
    end

    msginit --locale=en_US \
        --input=$pot_file \
        --output=$argv[2] \
        --no-translator
    sed -Ei 's/^msgstr "(.*)"$/msgstr "[[ \1 ]]"/' $argv[2]

    exit
end

msginit --locale=$argv[1] \
    --input=$pot_file \
    --output=$tr_dir/$argv[1].po
