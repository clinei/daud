void main()
{
	import std.experimental.logger : log;

	short[2 ^^ 16] buf;

	import std.conv : to;
	auto a = short(-22050);
	auto b = short(22050);

	import std.range : generate;
	import std.random : uniform;
	import std.range : take;
	import std.algorithm : copy;
	generate!(() => uniform!"[]"(a, b)).take(buf.length).copy(buf[]);

	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = new AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.S16_LE);

	device.write(&buf);
}
