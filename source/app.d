void main()
{
	uint sampleRate = 48_000;

	size_t bufSize = sampleRate / (2 ^^ 0);

	import std.typecons : scoped;
	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT, sampleRate, bufSize, 1);

	version(noise)
	{
		import daud.gen : noise;
		auto ns = noise!float;

		import daud.gen : repeatingGenerator;
		auto wave = repeatingGenerator(ns, bufSize);
	}
	else version(wave)
	{
		float freq = 31.415;

		version(saw)
		{
			import daud.gen : saw;
			auto form = saw!float(freq, sampleRate);
		}
		else version(sine)
		{
			import daud.gen : sine;
			auto form = sine!float(freq, sampleRate);
		}

		import daud.gen : repeatingGenerator;
		auto gen = repeatingGenerator(form, bufSize);

		auto wave = gen;
	}

	while (true)
	{
		import std.array : array;
		auto buf = wave.front.array;

		device.write(buf);

		wave.popFront();
	}
}
