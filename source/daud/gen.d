module daud.gen;

auto noise(T)()
{
	import std.range : generate;
	import std.random : uniform;
	import std.range : take;
	return generate!(() => uniform!"[]"(T(-1), T(1)));
}

auto sine(T, F)(F frequency, ulong sampleRate)
{
	import std.math : PI;
	import std.algorithm : map;
	import std.math : sin;
	return saw!T(frequency, sampleRate, 2 * PI, 0).map!sin;
}

auto saw(T, F)(F frequency, ulong sampleRate, T scale = 1, T offset = -(1 / 2))
{
	T step = T(frequency) / T(sampleRate);

	version(PhobosIota)
	{
		import std.range : iota;
		return iota!(T, T, T)(offset, scale - offset, step * scale);
	}
	else
	{
		return variableStepIota(offset, scale - offset, step * scale);
	}
}

auto repeatingGenerator(R)(R range, size_t frontSize = 1)
{
	return RepeatingGenerator!R(range, frontSize);
}

struct RepeatingGenerator(R)
{
	R _range;

	import std.range : ElementType;
	alias T = ElementType!R;

	import std.range : repeat;
	import std.algorithm : joiner;
	typeof(_range.repeat.joiner) _repeat;

	size_t _frontSize;

	this(R range, size_t frontSize = 1)
	{
		_range = range;
		_repeat = _range.repeat.joiner;

		_frontSize = frontSize;
	}

	enum bool empty = false;

	import std.range : Take;
	Take!(typeof(_repeat)) front()
	{
		import std.range : take;
		return _repeat.take(_frontSize);
	}

	void popFront()
	{
		import std.range : popFrontN;
		_repeat.popFrontN(_frontSize);
	}
}
unittest
{
	auto r = [1, 2, 3, 4, 5];
	auto gen = repeatingGenerator(r, 2);

	import std.algorithm : equal;
	assert(gen.front.equal([1, 2]));

	gen.popFront();
	assert(gen.front.equal([3, 4]));

	gen.popFront();
	assert(gen.front.equal([5, 1]));

	gen.popFront();
	assert(gen.front.equal([2, 3]));

	gen.popFront();
	assert(gen.front.equal([4, 5]));

	gen.popFront();
	assert(gen.front.equal([1, 2]));
}

private
struct VariableStepIota(B, E, S)
{
	import std.traits : CommonType;
	alias T = CommonType!(B, E);
	private
	{
		B begin;
		E end;
		T curr;
	}
	S step;

	this(B begin, E end, S step)
	{
		this.begin = begin;
		this.end = end;
		this.step = step;

		curr = begin;
	}

	bool empty()
	{
		return curr >= end;
	}

	T front()
	{
		return curr;
	}

	void popFront()
	{
		curr += step;
	}

	size_t length()
	{
		import std.math : ceil;
		import std.conv : to;
		return ceil((end - curr) / step).to!size_t;
	}
}
auto variableStepIota(B, E, S)(B begin, E end, S step)
{
	import std.traits : CommonType;
	alias T = CommonType!(B, E, S);
	return VariableStepIota!(T, T, T)(begin, end, step);
}
unittest
{
	auto r = variableStepIota(0, 1, 0.1);

	assert(r.front == 0);

	r.popFront();
	r.popFront();
	r.popFront();
	import std.math : approxEqual;
	assert(r.front.approxEqual(0.3));

	r.step = 0.2;
	r.popFront();
	r.popFront();
	assert(r.front.approxEqual(0.7));
}
