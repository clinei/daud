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

	import deimos.alsa.pcm : snd_pcm_t;
	snd_pcm_t* playback_handle;

	import deimos.alsa.pcm : snd_pcm_hw_params_t;
	snd_pcm_hw_params_t* hw_params;

	auto name = "default";

	import deimos.alsa.pcm : snd_pcm_open;
	import std.string : toStringz;
	import deimos.alsa.pcm : snd_pcm_stream_t;
	if (int err = snd_pcm_open(&playback_handle, name.toStringz(), snd_pcm_stream_t.PLAYBACK, 0) < 0)
	{
		log("cannot open device ", name);
		return;
	}
	scope(exit)
	{
		import deimos.alsa.pcm : snd_pcm_close;
		snd_pcm_close(playback_handle);
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_malloc;
	if (int err = snd_pcm_hw_params_malloc(&hw_params) < 0)
	{
		log("cannot allocate hw_params");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_any;
	if (int err = snd_pcm_hw_params_any(playback_handle, hw_params) < 0)
	{
		log("cannot initialize hw_params");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_set_access;
	import deimos.alsa.pcm : snd_pcm_access_t;
	if (int err = snd_pcm_hw_params_set_access(playback_handle, hw_params, snd_pcm_access_t.RW_INTERLEAVED) < 0)
	{
		log("cannot set access type");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_set_format;
	import deimos.alsa.pcm : snd_pcm_format_t;
	if (int err = snd_pcm_hw_params_set_format(playback_handle, hw_params, snd_pcm_format_t.S16_LE) < 0)
	{
		log("cannot set sample format");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_set_rate_near;
	uint sample_rate = 44100;
	int dir = 0;
	if (int err = snd_pcm_hw_params_set_rate_near(playback_handle, hw_params, &sample_rate, &dir) < 0)
	{
		log("cannot set sample rate");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_set_channels;
	uint channels = 2;
	if (int err = snd_pcm_hw_params_set_channels(playback_handle, hw_params, channels) < 0)
	{
		log("cannot set channel count");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params;
	if (int err = snd_pcm_hw_params(playback_handle, hw_params) < 0)
	{
		log("cannot set parameters");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_hw_params_free;
	snd_pcm_hw_params_free(hw_params);

	import deimos.alsa.pcm : snd_pcm_prepare;
	if (int err = snd_pcm_prepare(playback_handle) < 0)
	{
		log("cannot prepare audio interface");
		return;
	}

	import deimos.alsa.pcm : snd_pcm_writei;
	if (int err = snd_pcm_writei(playback_handle, &buf, buf.length) != buf.length)
	{
		log("write to audio interface failed");
		return;
	}
}
