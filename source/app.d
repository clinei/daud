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

void main()
{
	import std.typecons : scoped;
	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT64);

	version(dynbuf)
	{
		auto buf = noise!double(-22050, 22050, 2 ^^ 16);
	}
	else
	{
		double[2 ^^ 16] buf;

		import std.conv : to;
		auto a = double(-22050);
		auto b = double(22050);

		import std.range : generate;
		import std.random : uniform;
		import std.range : take;
		import std.algorithm : copy;
		generate!(() => uniform!"[]"(a, b)).take(buf.length).copy(buf[]);
	}

	device.write(buf);
}
