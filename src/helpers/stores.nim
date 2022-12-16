#=======================================================
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2022 Yanis Zafirópulos
#
# @file: helpers/stores.nim
#=======================================================

#=======================================
# Libraries
#=======================================

import os, strutils, tables

import db_sqlite as sqlite

import helpers/database
import helpers/io
import helpers/jsonobject

import vm/values/[printable, value]
import vm/[exec, errors, globals, parse]

#=======================================
# Helpers
#=======================================

proc checkStorePath*(
    path: string, 
    forceExtension: bool = false,
    global: bool = false, 
    kind: StoreKind = UndefinedStore
): (bool, string, StoreKind) =
    var actualPath: string = path
    var actualKind: StoreKind = kind

    if global:
        actualPath = getHomeDir().joinPath(".arturo").joinPath("stores").joinPath(actualPath)

    var (_, _, ext) = splitFile(actualPath)

    if actualKind == UndefinedStore:
        case ext:
            of ".art", ".store":
                actualKind = NativeStore
            of ".json":
                actualKind = JsonStore
            of ".db", ".sqlite", ".sqlite3":
                actualKind = SqliteStore
            else:
                actualKind = NativeStore
    else:
        if forceExtension:
            case actualKind:
                of NativeStore:
                    if ext notin [".art", ".store"]:
                        actualPath = actualPath.changeFileExt(".art")
                of JsonStore:
                    if ext != ".json":
                        actualPath = actualPath.changeFileExt(".json")
                of SqliteStore:
                    if ext notin [".db", ".sqlite", ".sqlite3"]:
                        actualPath = actualPath.changeFileExt(".db")
                else:
                    discard

    let existing = actualPath.fileExists()

    return (existing, actualPath, actualKind)

#=======================================
# Methods
#=======================================

proc saveStore*(store: VStore, one = false, key: string) =
    case store.kind:
        of NativeStore:
            var nativeData = codify(newDictionary(store.data),pretty = true, unwrapped = true)
            #nativeData = #strip(nativeData)[2..^2]
            writeToFile(store.path, nativeData)
        of JsonStore:
            writeToFile(store.path, jsonFromValueDict(store.data, pretty=true))
        of SqliteStore:
            if one:
                let value = store.data[key]
                let kind = $(value.kind)
                let json = jsonFromValue(value)
                let sql = "INSERT OR REPLACE INTO store (key, kind, value) VALUES (?, ?, ?);"
                discard store.db.execSqliteDb(sql, @[key, kind, json])
            else:
                # TODO(Helpers/stores) should add support for auto-saving entire SQLite stores
                #  labels: bug, values
                discard
            discard
        else:
            discard

proc loadStore*(store: var VStore) = 
    case store.kind:
        of NativeStore:
            store.data = execDictionary(doParse(store.path, isFile=true))
        of JsonStore:
            store.data = valueFromJson(readFile(store.path)).d
        of SqliteStore:
            store.data = newOrderedTable[string, Value]()
            for row in store.db.rows(sql("SELECT * FROM store;"), @[]):
                store.data[row[0]] = valueFromJson(row[2])
        else:
            discard

proc createEmptyStoreOnDisk*(store: VStore) =
    case store.kind:
        of NativeStore:
            writeToFile(store.path, "")
        of JsonStore:
            writeToFile(store.path, "{}")
        of SqliteStore:
            discard store.db.execManySqliteDb(@[
                "DROP TABLE IF EXISTS store;",
                "CREATE TABLE store (key TEXT, kind TEXT, value JSON NOT NULL);",
                "CREATE UNIQUE INDEX IF NOT EXISTS store_index ON store(key);",
                "CREATE INDEX IF NOT EXISTS store_kind_index ON store(kind);"
            ])
        else:
            discard

proc getStoreKey*(store: VStore, key: string): Value =
    GetKey(store.data, key)

func canStoreKey*(storeKind: StoreKind, valueKind: ValueKind): bool {.inline,enforceNoRaises.} =
    if storeKind == NativeStore: return true

    return valueKind in {Integer, Floating, String, Logical, Block, Dictionary, Null}

proc setStoreKey*(store: VStore, key: string, value: Value) =
    if unlikely(not canStoreKey(store.kind, value.kind)):
        RuntimeError_CannotStoreKey(key, ":" & ($(value.kind)).toLowerAscii(), ($(store.kind)).replace("Store",""))
    
    store.data[key] = value
    
    if store.autosave:
        saveStore(store, one=true, key=key)

proc initStore*(
    path: string, 
    doLoad: bool,
    forceExtension: bool = false,
    createIfNotExists: bool = true,
    forceCreate: bool = false,
    global: bool = false, 
    autosave: bool = false, 
    kind: StoreKind = UndefinedStore
): VStore =
    let (storeExists, storePath, storeKind) = checkStorePath(path, forceExtension, global, kind)

    result = VStore(
        path        : storePath,
        global      : global,
        loaded      : doLoad,
        autosave    : autosave,
        kind        : storeKind
    )

    if storeKind == SqliteStore:
        result.db = openSqliteDb(storePath)

    if forceCreate or (createIfNotExists and (not storeExists)):
        result.createEmptyStoreOnDisk()
    
    if doLoad:
        result.loadStore()