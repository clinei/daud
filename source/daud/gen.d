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

interface Generator(T, F)
{
	void frequency(F frequency);
}

final class Saw(T, F) : Generator!(T, F)
{
	F _frequency;

	ulong _sampleRate;

	T _step;

	VariableStepIota!(T, T, T) _iota;

	T _scale;

	T _offset;

	this(F frequency = 440, ulong sampleRate = 48_000, T scale = 1, T offset = -(1 / 2))
	{
		_sampleRate = sampleRate;
		_scale = scale;
		_offset = offset;
		this.frequency(frequency);
	}

	void frequency(F frequency)
	{
		_frequency = frequency;
		_step = T(_frequency) / T(_sampleRate);

		_iota = typeof(_iota)(_offset, _scale - _offset, _step * _scale);
	}

	Saw!(T, F) dup()
	{
		return new Saw!(T, F)(_frequency, _sampleRate, _scale, _offset);
	}

	Saw!(T, F) save()
	{
		return dup;
	}

	alias _iota this;
}
unittest
{
	auto sw = new Saw!(float, float)(1, 4);

	import std.math : approxEqual;
	assert(sw.front.approxEqual(0));
}

struct RangeRepeat(R)
{
	R _range;

	R _curr;

	this(R range)
	{
		_range = range;
		reset();
	}

	enum bool empty = false;

	import std.range : ElementType;
	ElementType!R front()
	{
		return _curr.front;
	}

	void popFront()
	{
		if (!_curr.empty)
		{
			_curr.popFront();
		}
		else
		{
			reset();
		}
	}

	void reset()
	{
		_curr = _range.save();
	}
}
RangeRepeat!R rangeRepeat(R)(R range)
{
	return RangeRepeat!R(range);
}
unittest
{
	auto r = new Saw!(float, float)(1, 4);

	auto rep = rangeRepeat(r);
}

struct RepeatingGenerator(G : Generator!(T, F), T, F)
{
	G _generator;

	import std.range : ElementType;
	alias T = ElementType!G;

	RangeRepeat!G _repeat;

	size_t _frontSize;

	this(G generator, size_t frontSize = 1)
	{
		_generator = generator;
		_repeat = RangeRepeat!G(_generator);

		_frontSize = frontSize;
	}

	enum bool empty = false;

	import std.range : Take;
	Take!(typeof(_repeat)) front()
	{
		import std.experimental.logger : log;
		import std.range : take;
		return _repeat.take(_frontSize);
	}

	void popFront()
	{
		import std.range : popFrontN;
		_repeat.popFrontN(_frontSize);
	}

	void frequency(F frequency)
	{
		_generator.frequency = frequency;
	}
}
auto repeatingGenerator(G)(G generator, size_t frontSize = 1)
{
	import std.traits : TemplateArgsOf;
	alias args = TemplateArgsOf!G;
	return RepeatingGenerator!(G, args[0], args[1])(generator, frontSize);
}
/+
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
+/

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
