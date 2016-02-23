void main()
{
	import std.experimental.logger : log;

	uint sampleRate = 48_000;

	size_t bufSize = sampleRate / (2 ^^ 8);

	import std.typecons : scoped;
	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT, sampleRate, bufSize, 0);

	version(noise)
	{
		import daud.gen : noise;
		auto ns = noise!float;

		import daud.gen : repeatingGenerator;
		auto wave = repeatingGenerator(ns, bufSize);
	}
	else version(wave)
	{
		float freq = 100;

		version(saw)
		{
			import daud.gen : Saw;
			auto form = new Saw!(float, float)(freq, sampleRate);
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
		wave._generator._frequency += 0.01;

		import std.array : array;
		auto buf = wave.front.array;

		device.write(buf);

		wave.popFront();
	}
}
