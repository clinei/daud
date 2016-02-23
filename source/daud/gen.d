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

	VariableStepIota!(T, T, T) _iota;

	this(F frequency = 440, ulong sampleRate = 48_000, T scale = 1, T offset = 0)
	{
		_sampleRate = sampleRate;

		this.frequency(frequency);
		_iota = typeof(_iota)(offset, scale - offset, step * scale);

	}
	this(F frequency, ulong sampleRate, typeof(_iota) iota)
	{
		_sampleRate = sampleRate;
		_iota = iota;
		this.frequency = frequency;
	}

	T step()
	{
		return T(_frequency) / T(_sampleRate);
	}

	F frequency()
	{
		return _frequency;
	}
	void frequency(F frequency)
	{
		_frequency = frequency;
		_iota.step = step;
	}

	Saw!(T, F) dup()
	{
		return new Saw!(T, F)(_frequency, _sampleRate, _iota);
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

	assert(!sw.empty);

	import std.math : approxEqual;
	assert(sw.front.approxEqual(0));
	sw.popFront();
	assert(sw.front.approxEqual(0.25));
	sw.popFront();
	assert(sw.front.approxEqual(0.5));

	assert(!sw.empty);

	sw.popFront();
	assert(sw.front.approxEqual(0.75));
	sw.popFront();
	assert(sw.front.approxEqual(1));

	assert(sw.empty);
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
	auto sw = new Saw!(float, float)(1, 4);

	auto rep = rangeRepeat(sw);
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
		import std.range : takeExactly;
		return _repeat.takeExactly(_frontSize);
	}

	void popFront()
	{
		import std.range : popFrontN;
		_repeat.popFrontN(_frontSize);
	}

	F frequency()
	{
		return _generator.frequency;
	}
	// `cont` is hack
	void frequency(F frequency, T cont)
	{
		import std.experimental.logger : log;

		// is wrong at 2000
// 		auto prev = _repeat.front;
		auto prev = cont;
		_generator.frequency = frequency;

		_repeat.reset();

		import std.algorithm : countUntil;
		auto n = _repeat.countUntil!("a > b")(prev);

		static if (false)
		{
			log(prev);
			log(_repeat.front);
		}
	}
}
auto repeatingGenerator(G : Generator!(T, F), T, F)(G generator, size_t frontSize = 1)
{
	return RepeatingGenerator!(G, T, F)(generator, frontSize);
}

unittest
{
	auto sw = new Saw!(float, float)(1, 4);

	auto gen = repeatingGenerator(sw, 2);

	/+
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
	+/
}

// TODO: optimize for unsigned step
struct VariableStepIota(L, H, S)
{
	import std.traits : CommonType;
	alias T = CommonType!(L, H);
	private
	{
		L _low;
		H _high;
		T _curr;
	}
	S step;

	this(L low, H high, S step, T curr)
	{
		_low = low;
		_high = high;
		this.step = step;

		_curr = curr;
	}
	this(L low, H high, S step)
	{
		import std.traits : isSigned;
		static if (isSigned!S)
		{
			if (step > 0)
			{
				this(low, high, step, low);
			}
			else
			{
				this(low, high, step, high);
			}
		}
		else
		{
			this(low, high, step, low);
		}
	}

	bool empty()
	{
		import std.traits : isSigned;
		static if (isSigned!S)
		{
			if (step > 0)
			{
				return _curr >= _high || _curr < _low;
			}
			else if (step <= 0)
			{
				return _curr > _high || _curr <= _low;
			}
			else
			{
				return true;
			}
		}
		else
		{
			return _curr >= _high;
		}
	}

	T front()
	{
		return _curr;
	}

	/++
	probably does a lot more than is needed,
	but guarantees staying within bounds,
	even when they are `type.max` or `type.min`
	++/
	void popFront()
	{
		import std.traits : isSigned;
		static if (isSigned!S)
		{
			if (step > 0 && (_high - step < _curr))
			{
				_curr = _high;
			}
			else if (step <= 0 && (_low + step > _curr))
			{
				_curr = _low;
			}
			else
			{
				_curr += step;
			}
		}
		else
		{
			if (_high - step < _curr)
			{
				_curr = _high;
			}
			else
			{
				_curr += step;
			}
		}
	}

	// FIXME: doesn't work for negative step
	size_t length()
	{
		import std.math : ceil;
		import std.conv : to;
		return ceil((_high - _curr) / step).to!size_t;
	}
}
auto variableStepIota(L, H, S)(L low, H high, S step)
{
	return variableStepIota(low, high, step, low);
}
auto variableStepIota(L, H, S, C)(L low, H high, S step, C curr)
{
	import std.traits : CommonType;
	alias T = CommonType!(L, H, S, C);
	return VariableStepIota!(T, T, T)(low, high, step, curr);
}
unittest
{
	auto r = variableStepIota(-1, 1, 0.1, -0.2);

	import std.math : approxEqual;
	assert(r.front.approxEqual(-0.2));

	r.popFront();
	r.popFront();
	r.popFront();
	assert(r.front.approxEqual(0.1));

	r.step = -0.2;
	r.popFront();
	r.popFront();
	r.popFront();
	assert(r.front.approxEqual(-0.5));
}
