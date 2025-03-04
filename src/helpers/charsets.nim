######################################################
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2022 Yanis Zafirópulos
#
# @file: helpers/charsets.nim
######################################################

#=======================================
# Libraries
#=======================================

import sequtils, sugar, tables, unicode

import vm/values/value

#=======================================
# Constants
#=======================================

# TODO(Strings\alphabet) add support for Afrikaans alphabet -> af
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Albanian alphabet -> sq
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Armenian alphabet -> hy
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Basque alphabet -> eu
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Bulgarian alphabet -> bg
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Byelorussian alphabet -> be
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Catalan alphabet -> ca
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Croatian alphabet -> hr
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Czech alphabet -> cs
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Danish alphabet -> da
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Dutch alphabet -> nl
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Esperanto alphabet -> eo
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Estonian alphabet -> et
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Faroese alphabet -> fo
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Finnish alphabet -> fi
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for French alphabet -> fr
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Georgian alphabet -> ka
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for German alphabet -> de
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Hungarian alphabet -> hu
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Icelandic alphabet -> is
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Igbo alphabet -> ig
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Indonesian alphabet -> id
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Irish Gaelic alphabet -> ga
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Italian alphabet -> it
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Latin alphabet -> la
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Latvian alphabet -> lv
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Lithuanian alphabet -> lt
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Luxemourgish alphabet -> lb
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Macedonian alphabet -> mk
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Malay alphabet -> ms
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Maltese alphabet -> mt
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Maori alphabet -> mi
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Norwegian alphabet -> no
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Polish alphabet -> pl
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Romanian alphabet -> ro
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Russian alphabet -> ru
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Serbian alphabet -> sr
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Scots Gaelic alphabet -> gd
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Slovak alphabet -> sk
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Slovenian alphabet -> sl
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Swahili alphabet -> sw
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Swedish alphabet -> se
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Turkish alphabet -> tr
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Ukrainian alphabet -> uk
#  label: library, enhancement, easy
# TODO(Strings\alphabet) add support for Vietnamese alphabet -> vi
#  label: library, enhancement, easy

const
    # the main alphabet, by ISO 639-1 code, 
    # containing only characters that can be found in a dictionary index
    # and in the exact same order as found in a dictionary
    charsets = {
        "el": "αβγδεζηθικλμνξοπρστυφχψω",
        "en": "abcdefghijklmnopqrstuvwxyz",
        "es": "abcdefghijklmnñopqrstuvwxyz",
        "pt": "abcdefghijklmnopqrstuvwxyz"
    }.toTable

    # extra characters that can be found in a given language, by ISO 639-1 code,
    # but would not form part of its dictionary index
    extras = {
        "el": "άέίόύϊϋΐΰ",
        "en": "",
        "es": "áéíóúü",
        "pt": "áàâãäçéêëíïóõöúü"
    }.toTable

#=======================================
# Methods
#=======================================

proc getCharset*(locale: string, withExtras = false, doUppercase = false): ValueArray =
    var ret: seq[Rune] = @[]

    if doUppercase:
        ret = toSeq(runes(charsets[locale])).map((x)=>toUpper(x))
    else:
        ret = toSeq(runes(charsets[locale]))

    if withExtras:
        var extra: seq[Rune] = @[]
        if doUppercase:
            extra = toSeq(runes(extras[locale])).map((x)=>toUpper(x))
        else:
            extra = toSeq(runes(extras[locale]))

        ret.add(extra)
        
    result = ret.map((x)=>newChar(x))
