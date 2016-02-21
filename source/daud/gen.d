module daud.gen;

auto noise(T)()
{
	import std.range : generate;
	import std.random : uniform;
	import std.range : take;
	return generate!(() => uniform!"[]"(T(-1), T(1)));
}

auto sine(T)(uint frequency, ulong sampleRate)
{
	import std.math : PI;
	import std.algorithm : map;
	import std.math : sin;
	return saw!T(frequency, sampleRate, 2 * PI).map!sin;
}

auto saw(T)(uint frequency, ulong sampleRate, T scale = 1)
{
	// bigger frequency => smaller period

	import core.time : seconds;
	auto period = 1.seconds / frequency;

	// smaller period => bigger step

	T step = 1.seconds.total!"hnsecs" / T(period.total!"hnsecs") / T(sampleRate);

	import std.range : iota;
	import std.math : PI;
	import std.algorithm : map;
	import std.math : sin;
	return iota!(T, T, T)(0, scale, step * scale);
}
