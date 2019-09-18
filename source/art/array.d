/*******************************************************
 * Arturo
 * 
 * The Minimal Declarative-Like Language
 * (c) 2019 Yanis Zafirópulos (aka Dr.Kameleon)
 *
 * @file: art/array.d
 *******************************************************/

module art.array;

// Imports

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.random;
import std.range;
import std.stdio;
import std.string;

import parser.expression;
import parser.expressions;
import parser.statements;

import compiler;

import value;

import func;
import globals;

import panic;

class All_ : Func {
	this() { super("all","check if all elements of array are true or pass the condition of given function",[[aV],[aV,fV]],[bV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);

		alias arr = A!(v,0);

		if (v.length==2) {
			alias func = F!(v,1);

			bool ok = true;
			foreach (Value item; arr) {
				Value val = func.execute(item);
				if (val.type!=bV) throw new ERR_ExpectedValueTypeError("all", "boolean", to!string(item.type));
				if (!B!(val)) ok = false;
			}
			
			return new Value(ok);
		}
		else {
			bool ok = true;
			foreach (Value item; arr) {
				if (item.type!=bV) throw new ERR_ExpectedValueTypeError("all", "boolean", to!string(item.type));
				if (!B!(item)) ok = false;
			}
			return new Value(ok);
		}
	}
}

class Any_ : Func {
	this() { super("any","check if any of the array's elements is true or passes the condition of given function",[[aV],[aV,fV]],[bV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);

		alias arr = A!(v,0);

		if (v.length==2) {
			alias func = F!(v,1);

			bool ok = false;
			foreach (Value item; arr) {
				Value val = func.execute(item);
				if (val.type!=bV) throw new ERR_ExpectedValueTypeError("any", "boolean", to!string(item.type));
				if (B!(val)) ok = true;
			}
			
			return new Value(ok);
		}
		else {
			bool ok = false;
			foreach (Value item; arr) {
				if (item.type!=bV) throw new ERR_ExpectedValueTypeError("any", "boolean", to!string(item.type));
				if (B!(item)) ok = true;
			}
			return new Value(ok);
		}
	}
}

class Difference_ : Func {
	this() { super("difference","get difference of two given arrays",[[aV,aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr1 = A!(v,0);
		alias arr2 = A!(v,1);

		Value[] ret = setDifference(arr1, arr2).array;

		return new Value(ret);
	}
}

class Filter_ : Func {
	this() { super("filter","get array after filtering each element using given function",[[aV,fV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);
		alias func = F!(v,1);

		Value[] ret;
		foreach (Value item; arr) {
			Value condition = func.execute(item);
			if (condition.type!=bV) 
				throw new ERR_ExpectedValueTypeError("filter", "boolean", condition.type);

			if (condition.content.b)
				ret ~= item;
		}

		return new Value(ret);
	}
}

class First_ : Func {
	this() { super("first","get first element from array",[[aV]],[xV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		if (arr.length>0) return arr[0];
		else throw new ERR_IndexNotFound(0, to!string(v[0]));
	}
}

class Intersection_ : Func {
	this() { super("intersection","get intersection of two given arrays",[[aV,aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr1 = A!(v,0);
		alias arr2 = A!(v,1);

		Value[] ret = setIntersection(arr1, arr2).array;

		return new Value(ret);
	}
}

class Join_ : Func {
	this() { super("join","get string by joining array elements with given delimiter",[[aV,sV]],[sV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);
		alias delim = S!(v,1);

		auto ret = arr.map!(a=> (a.type==sV) ? a.content.s : a.stringify()).array.join(delim);

		return new Value(ret);
	}
}

class Last_ : Func {
	this() { super("last","get last element from array",[[aV]],[xV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		if (arr.length>0) return arr[arr.length-1];
		else throw new ERR_IndexNotFound(0, to!string(v[0]));
	}
}

class Min_ : Func {
	this() { super("min","get minimum value from array",[[aV]],[nV,rV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);

		alias arr = A!(v,0);
		Value minValue = new Value();

		foreach (Value item; arr) {
			if (item.type!=nV && item.type!=rV) throw new ERR_ExpectedValueTypeError("min","number",item.type);

			if (minValue is null) minValue = item;
			else {
				if (item<minValue) minValue = item;
			}
		}

		return minValue;
	}
}

class Map_ : Func {
	this() { super("map","get array after executing given function for each element",[[aV,fV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);
		alias func = F!(v,1);

		Value[] ret;
		foreach (Value item; arr) 
			ret ~= func.execute(item);

		return new Value(ret);
	}
}

class Max_ : Func {
	this() { super("max","get maximum value from array",[[aV]],[nV,rV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);

		alias arr = A!(v,0);
		Value maxValue = new Value();

		foreach (Value item; arr) {
			if (item.type!=nV && item.type!=rV) throw new ERR_ExpectedValueTypeError("max","number",item.type);
			
			if (maxValue is null) maxValue = item;
			else {
				if (item>maxValue) maxValue = item;
			}
		}

		return maxValue;
	}
}

class Permutations_ : Func {
	this() { super("permutations","get all permutations for given array",[[aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		Value cp = new Value(v[0]);

		Value[] ret;

		while (nextPermutation(cp.content.a)) {
			ret ~= new Value(cp.content.a);
		}

		return new Value(ret);
	}
}

class Product_ : Func {
	this() { super("product","return product of elements of given array",[[aV]],[nV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		Value ret = new Value(1);

		foreach (val; arr) {
			if (val.type!=nV) throw new ERR_FunctionCallValueError("sum", 0, "number", val.type);
			ret = ret * val;
		}

		return ret;
	}
}

class Range_ : Func {
	this() { super("range","get array from given range (from..to) with optional step",[[nV,nV],[nV,nV,nV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias from = I!(v,0);
		alias to = I!(v,1);

		long step = 1;

		Value[] ret;
		if (ex.lst.length==3) 
			step = I!(v,2);

		for (long i=from; i<=to; i+=step)
			ret ~= new Value(i);

		return new Value(ret);
	}
}

class Reverse_ : Func {
	this() { super("reverse","reverse given array",[[aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		Value[] vs = arr;
		Value[] ret = vs.reverse;

		return new Value(ret);
	}
}

class Sample_ : Func {
	this() { super("sample","get random sample from given array",[[aV],[aV,nV]],[xV,aV,noV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		if (v.length==2) {
			alias count = I!(v,1);

			auto smpl = cast(Value[])(arr.randomSample(count).array);
			return new Value(smpl);
		} 
		else {
			auto smpl = arr.randomSample(1).array;
			if (smpl.length==1) return smpl[0];
			else return new Value();
		}
	}
}

class Shuffle_ : Func {
	this() { super("shuffle","shuffle given array",[[aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		Value[] ret = arr.randomShuffle();

		return new Value(ret);
	}
}

class Sort_ : Func {
	this() { super("sort","sort given array",[[aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		Value arr = v[0];

		Value sorted = arr.arraySort();

		if (sorted !is null) return sorted;
		else throw new ERR_ArrayNotSortable(to!string(arr));
	}
}

class Sum_ : Func {
	this() { super("sum","return sum of elements of given array",[[aV]],[nV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		Value ret = new Value(0);

		foreach (val; arr) {
			if (val.type!=nV) throw new ERR_FunctionCallValueError("sum", 0, "number", val.type);
			ret = ret + val;
		}

		return ret;
	}
}

class Tail_ : Func {
	this() { super("tail","get last section of array excluding the first element",[[aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		if (arr.length>0) return new Value(arr.tail(arr.length-1));
		else return new Value(cast(Value[])([]));
	}
}

class Union_ : Func {
	this() { super("union","get union of two given arrays",[[aV,aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr1 = A!(v,0);
		alias arr2 = A!(v,1);

		Value[][] input = [ arr1, arr2 ];

		Value[] ret = multiwayUnion(input).array;

		return new Value(ret);
	}
}

class Uniq_ : Func {
	this() { super("uniq","get array by removing duplicates",[[aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr = A!(v,0);

		return v[0].removeDuplicatesFromArray();
	}
}

class Zip_ : Func {
	this() { super("zip","return array of element pairs using given arrays",[[aV,aV]],[aV]); }
	override Value execute(Expressions ex) {
		Value[] v = validate(ex);
		alias arr1 = A!(v,0);
		alias arr2 = A!(v,1);

		auto minCommonLength = min(arr1.length, arr2.length);

		Value[] ret = cast(Value[])([]);

		for (int i=0; i<minCommonLength; i++) {
			ret ~= new Value([arr1[i],arr2[i]]);
		}

		return new Value(ret);
	}
}
