######################################################
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2021 Yanis Zafirópulos
#
# @file: vm/globals.nim
######################################################

#=======================================
# Libraries
#=======================================

import strutils, sequtils, sets, tables

export strutils, tables

import vm/[bytecode, errors, stack, value]

#=======================================
# Super-Globals
#=======================================

var
    syms*{.threadvar.}      : ValueDict
    aliases*{.threadvar.}   : SymbolDict
    Funcs*{.threadvar.}     : Table[string,int]
    Evaled*{.threadvar.}    : Table[Value,Translation]

#=======================================
# Constants
#=======================================

const
    NoArgs*      = static {"" : {Nothing}}
    NoAttrs*     = static {"" : ({Nothing},"")}

template builtin*(n: string, alias: SymbolKind, rule: PrecedenceKind, description: string, args: untyped, attrs: untyped, returns: ValueSpec, example: string, act: untyped):untyped =
    when args.len==1 and args==NoArgs:  
        const argsLen = 0
    else:                               
        const argsLen = static args.len

    const cleanExample = replace(strutils.strip(example),"\n        ","\n")
    let b = newBuiltin(n, alias, rule, static (instantiationInfo().filename).replace(".nim"), description, static argsLen, args.toOrderedTable, attrs.toOrderedTable, returns, cleanExample, proc () =
        requireArgs(n, args)
        act
    )

    Funcs[n] = static argsLen
    syms[n] = b

    #echo "SYSTEM: create builtin function: " & n & " with arity: " & $(argsLen)

    when alias != unaliased:
        aliases[alias] = AliasBinding(
            precedence: rule,
            name: newWord(n)
        )

template constant*(n: string, alias: SymbolKind, description: string, v: Value):untyped =
    #echo "setting constant " & $(n) & " with description = " & description
    syms[n] = (v)
    syms[n].info = description
    when alias != unaliased:
        aliases[alias] = AliasBinding(
            precedence: PrefixPrecedence,
            name: newWord(n)
        )

template requireArgs*(name: string, spec: untyped, nopop: bool = false): untyped =
    if SP<(static spec.len) and spec!=NoArgs:
        panic "cannot perform '" & (static name) & "'; not enough parameters: " & $(static spec.len) & " required"

    when (static spec.len)>=1 and spec!=NoArgs:
        when not (ANY in static spec[0][1]):
            if not (Stack[SP-1].kind in (static spec[0][1])):
                let acceptStr = toSeq((spec[0][1]).items).map(proc(x:ValueKind):string = ":" & ($(x)).toLowerAscii()).join(" ")
                panic "cannot perform '" & (static name) & "' -> :" & ($(Stack[SP-1].kind)).toLowerAscii() & " ...; incorrect argument type for 1st parameter; accepts " & acceptStr

        when (static spec.len)>=2:
            when not (ANY in static spec[1][1]):
                if not (Stack[SP-2].kind in (static spec[1][1])):
                    let acceptStr = toSeq((spec[1][1]).items).map(proc(x:ValueKind):string = ":" & ($(x)).toLowerAscii()).join(" ")
                    panic "cannot perform '" & (static name) & "' -> :" & ($(Stack[SP-1].kind)).toLowerAscii() & " :" & ($(Stack[SP-2].kind)).toLowerAscii() & " ...; incorrect argument type for 2nd parameter; accepts " & acceptStr

            when (static spec.len)>=3:
                when not (ANY in static spec[2][1]):
                    if not (Stack[SP-3].kind in (static spec[2][1])):
                        let acceptStr = toSeq((spec[2][1]).items).map(proc(x:ValueKind):string = ":" & ($(x)).toLowerAscii()).join(" ")
                        panic "cannot perform '" & (static name) & "' -> :" & ($(Stack[SP-1].kind)).toLowerAscii() & " :" & ($(Stack[SP-2].kind)).toLowerAscii() & " :" & ($(Stack[SP-3].kind)).toLowerAscii() & " ...; incorrect argument type for third parameter; accepts " & acceptStr

    when not nopop:
        when (static spec.len)>=1 and spec!=NoArgs:
            var x {.inject.} = stack.pop()
            when (static spec.len)>=2:
                var y {.inject.} = stack.pop()
                when (static spec.len)>=3:
                    var z {.inject.} = stack.pop()