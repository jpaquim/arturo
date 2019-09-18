/************************************************
 * Arturo
 * 
 * The Minimal Declarative-Like Language
 * (c) 2019 Ioannis Zafeiropoulos
 *
 * @file: art/file.d
 ************************************************/

module art.file;

// Imports

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.stdio;
import std.string;
import std.typetuple;

import parser.expression;
import parser.expressions;
import parser.statements;

import value;

import func;
import globals;

class File__Exists_ : Func {
	this() { super("file.exists","check if file exists at given path",[[sV]],[bV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias filePath = S!(v,0);

		string path = Glob.env.fileFolder ~ "/" ~ filePath;

		return new Value(path.exists);
	}
}

class File__Read_ : Func {
	this() { super("file.read","read string from file at given path",[[sV]],[sV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias filePath = S!(v,0);
		
		string path = Glob.env.fileFolder ~ "/" ~ filePath;

		return new Value(readText(path));
	}
}

class File__Write_ : Func {
	this() { super("file.write","write string to file at given path",[[sV,sV]],[noV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias filePath = S!(v,0);
		alias fileContent = S!(v,1);

		string path = Glob.env.fileFolder ~ "/" ~ filePath;

		std.file.write(path, fileContent);

		return new Value();
	}
}
