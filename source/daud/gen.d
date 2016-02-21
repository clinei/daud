module daud.gen;

T[] noise(T)(T lowerBound, T upperBound, size_t length)
{
	T[] buf;
	buf.length = length;

	import std.range : generate;
	import std.random : uniform;
	import std.range : take;
	import std.algorithm : copy;
	generate!(() => uniform!"[]"(lowerBound, upperBound)).take(buf.length).copy(buf[]);

	return buf;
}
