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
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT64, 1);

	auto buf = noise!double(-22050, 22050, 2 ^^ 16);

	device.write(buf);

	import core.thread : Thread;
	import core.time : seconds;
	Thread.sleep(1.seconds);
}
