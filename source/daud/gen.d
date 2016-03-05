module daud.gen;

auto noise(T)()
{
	import std.range : generate;
	import std.random : uniform;
	import std.range : take;
	return generate!(() => uniform!"[]"(T(-1), T(1)));
}

interface Generator(T, F)
{
	void frequency(F frequency);
}

final class WrappingSine(T, F) : Generator!(T, F)
{
	WrappingSaw!(T, F) _saw;

	this(F frequency = 440, uint sampleRate = 48_000)
	{
		_saw = new typeof(_saw)(frequency, sampleRate);
	}

	enum bool empty = false;

	T front()
	{
		import std.math : sin, PI;
		return sin( (_saw.front / T.max + 1) * PI * 2);
	}

	void popFront()
	{
		_saw.popFront();
	}

	F frequency()
	{
		return _saw.frequency * 2;
	}
	void frequency(F newFrequency)
	{
		_saw.frequency = newFrequency / 2;
	}
}
auto wrappingSine(T, F)(F frequency, uint sampleRate = 48_000)
{
	return new WrappingSine!(T, F)(frequency, sampleRate);
}

final class WrappingSaw(T, F) : Generator!(T, F)
{
	F _frequency;

	uint _sampleRate;

	WrappingIota!T _iota;

	this(F frequency = 440, uint sampleRate = 48_000)
	{
		_sampleRate = sampleRate;
		this.frequency(frequency);
	}

	enum bool empty = false;

	T front()
	{
		return _iota.front;
	}

	void popFront()
	{
		_iota.popFront();
	}

	T step()
	{
		return T(_frequency) / T(_sampleRate) * T.max;
	}

	F frequency()
	{
		return _frequency;
	}
	void frequency(F newFrequency)
	{
		_frequency = newFrequency;
		_iota.step = this.step;
	}
}
auto wrappingSaw(T, F)(F frequency, uint sampleRate = 48_000)
{
	return new WrappingSaw!(T, F)(frequency, sampleRate);
}

struct WrappingIota(T)
{
	import std.traits : isFloatingPoint;
	static if (isFloatingPoint!T)
	{
		T _curr = -T.max;
	}
	else
	{
		T _curr = T.min;
	}
	T _step;

	this(T step)
	{
		this.step(step);
		{
			_curr = -T.max;
		}
	}

	this(T step, T curr)
	{
		this(step);
		_curr = curr;
	}

	T step()
	{
		return _step;
	}
	void step(T newStep)
	{
		_step = newStep;
	}

	enum bool empty = false;

	T front()
	{
		return _curr;
	}

	void popFront()
	{
		import std.traits : isFloatingPoint;
		static if (isFloatingPoint!T)
		{
			if (_curr + step == T.infinity)
			{
				auto over = _step - (T.max - _curr);
				_curr = -T.max + over;
			}
			else if (_curr + _step == -T.infinity)
			{
				auto under = _step + (T.max + _curr);
				_curr = T.max - under;
			}
			else
			{
				_curr += step;
			}
		}
		else
		{
			_curr += _step;
		}
	}
}
