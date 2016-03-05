void main()
{
	uint sampleRate = 4_000;

	size_t bufSize = sampleRate / (2 ^^ 8);

	import std.typecons : scoped;
	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT, sampleRate, bufSize, 0);

	version(noise)
	{
		import daud.gen : noise;
		auto wave = noise!float;
	}
	else version(wave)
	{
		float freq = 200;

		version(saw)
		{
			import daud.gen : WrappingSaw;
			auto form = new WrappingSaw!(float, float)(freq, sampleRate);
		}
		else version(sine)
		{
			import daud.gen : WrappingSine;
			auto form = new WrappingSine!(float, float)(freq, sampleRate);
		}

		auto wave = form;
	}

	while (true)
	{
		import std.range : take;
		import std.array : array;
		auto buf = wave.take(bufSize).array;

		static if (true)
		{
			import std.algorithm : each;
			import std.stdio : writeln;
			buf.each!writeln;
		}

		device.write(buf);

		version(wave)
		{
			wave.frequency = wave.frequency * 0.995;
		}
	}
}
