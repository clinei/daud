module daud.drivers.alsa;

final class AudioDevice
{
	import deimos.alsa.pcm : snd_pcm_t;
	snd_pcm_t* handle;

	import deimos.alsa.pcm : snd_pcm_hw_params_t;
	snd_pcm_hw_params_t* hw_params;

	string name = "default";

	import deimos.alsa.pcm : snd_pcm_stream_t;
	import deimos.alsa.pcm : snd_pcm_format_t;
	this(snd_pcm_stream_t stream_type, snd_pcm_format_t format, uint sample_rate = 48_000, ulong buffer_size = 1024, int async = 0)
	{
		import deimos.alsa.pcm : snd_pcm_open;
		import std.string : toStringz;
		if (int err = snd_pcm_open(&handle, name.toStringz(), stream_type, 0) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_malloc;
		if (int err = snd_pcm_hw_params_malloc(&hw_params) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_any;
		if (int err = snd_pcm_hw_params_any(handle, hw_params) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_set_access;
		import deimos.alsa.pcm : snd_pcm_access_t;
		if (int err = snd_pcm_hw_params_set_access(handle, hw_params, snd_pcm_access_t.RW_NONINTERLEAVED) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_set_format;
		if (int err = snd_pcm_hw_params_set_format(handle, hw_params, format) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_set_rate;
		if (int err = snd_pcm_hw_params_set_rate(handle, hw_params, sample_rate, 0) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_set_buffer_size;
		if (int err = snd_pcm_hw_params_set_buffer_size(handle, hw_params, buffer_size) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_set_channels;
		uint channels = 1;
		if (int err = snd_pcm_hw_params_set_channels(handle, hw_params, channels) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params;
		if (int err = snd_pcm_hw_params(handle, hw_params) < 0)
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_hw_params_free;
		snd_pcm_hw_params_free(hw_params);

		import deimos.alsa.pcm : snd_pcm_nonblock;
		if (int err = snd_pcm_nonblock(handle, async))
		{
			// throw
		}

		import deimos.alsa.pcm : snd_pcm_prepare;
		if (int err = snd_pcm_prepare(handle) < 0)
		{
			// throw
		}
	}

	~this()
	{
		import deimos.alsa.pcm : snd_pcm_close;
		snd_pcm_close(handle);
	}

	void write(Buffer)(auto ref Buffer buffer)
	{
		auto buffers = [buffer.ptr];
		import deimos.alsa.pcm : snd_pcm_writen;
		if (int err = snd_pcm_writen(handle, cast(void**)buffers.ptr, buffer.length) != buffer.length)
		{
			// throw
		}
	}
}
