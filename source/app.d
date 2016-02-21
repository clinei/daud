void main()
{
	import std.typecons : scoped;
	import daud.drivers.alsa : AudioDevice;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	auto device = scoped!AudioDevice(snd_pcm_stream_t.PLAYBACK, snd_pcm_format_t.FLOAT64, 1);

	import daud.gen : noise;
	auto buf = noise!double(-22050, 22050, 2 ^^ 16);

	device.write(buf);

	import core.thread : Thread;
	import core.time : seconds;
	Thread.sleep(1.seconds);
}
