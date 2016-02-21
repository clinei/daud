void main()
{
	import std.typecons : scoped;
	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT);

	size_t bufSize = 2 ^^ 16;

	version(noise)
	{
		import daud.gen : noise;
		auto ns = noise!float;

		import std.range : take;
		auto wave = ns.take(bufSize);
	}
	else version(wave)
	{
		uint freq = 440;

		version(saw)
		{
			import daud.gen : saw;
			auto form = saw!float(freq, 48_000);
		}
		else version(sine)
		{
			import daud.gen : sine;
			auto form = sine!float(freq, 48_000);
		}

		import std.range : repeat;
		import std.array : join;
		auto wave = form.repeat(bufSize / form.length).join();
	}

	import std.array : array;
	auto buf = wave.array;

	device.write(buf);
}
