package mplayer

import "base:runtime"
import mem_virtual "core:mem/virtual"
import "core:mem"
import "core:math"
import "core:os"
import "core:fmt"
import "src:audio"
import "src:flac"

import ma "vendor:miniaudio"

Audio_Playback_Buffer :: struct {
	playback_done: bool,
	music_audio: audio.Music_Audio,
	samples_chunk: ^audio.Audio_Samples_Chunk,
	cursor_in_chunk: int,
}

audio_device_data :: proc "c" (device: ^ma.device, output_buf, input_buf: rawptr, frame_count: u32) {
	frame_count := frame_count;
	playback_buffer := cast(^Audio_Playback_Buffer)device.pUserData;
	
	output_buf_f32 := cast([^]f32)output_buf; 
	output_sample_index := 0;
	
	for !playback_buffer.playback_done && frame_count > 0 {
		samples_left_in_chunk := playback_buffer.samples_chunk.samples_count - playback_buffer.cursor_in_chunk;
		samples_to_read := math.min(samples_left_in_chunk, int(frame_count));
		channels_count := playback_buffer.music_audio.channels_count;
		
		for sample_index in 0..<samples_to_read {
			for ch_index in 0..<channels_count {
				samples := playback_buffer.samples_chunk.channels[ch_index].samples[playback_buffer.cursor_in_chunk:];
				output_buf_f32[output_sample_index] = samples[sample_index];
				output_sample_index += 1;
			}
		}
		
		frame_count -= u32(samples_to_read);
		playback_buffer.cursor_in_chunk += samples_to_read;
		if playback_buffer.cursor_in_chunk == playback_buffer.samples_chunk.samples_count {
			playback_buffer.samples_chunk = playback_buffer.samples_chunk.next;
			playback_buffer.cursor_in_chunk = 0;
		}
		
		if playback_buffer.samples_chunk == nil {
			playback_buffer.playback_done = true;
		}
	}
}


main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usegae:\n\t", os.args[0], " filename");
		return;
	}
	
	temp_arena: mem_virtual.Arena;
	if err := mem_virtual.arena_init_growing(&temp_arena, 2 * mem.Gigabyte); err != .None {
		panic("couldn't init growing temp arena");
	}
	context.temp_allocator = mem_virtual.arena_allocator(&temp_arena);
	
	file_name := os.args[1];
	data, ok := os.read_entire_file_from_filename(file_name);
	defer delete(data);
	
	fmt.println("Reading file:", file_name);
	if !ok {return;}
	flac_stream := flac.init_flac_stream(data);
	music_audio: audio.Music_Audio;
	music_audio.sample_rate = flac_stream.streaminfo.sample_rate;
	music_audio.channels_count = u32(flac_stream.streaminfo.nb_channels);
	
	for {
		runtime.free_all(context.temp_allocator);
		block_samples, block_size := flac.decode_one_block(&flac_stream, context.temp_allocator);
		if block_size == 0 {
			break;
		}
		
		nb_channels := u8(music_audio.channels_count);
		audio_samples_chunk := audio.make_audio_chunk(nb_channels, int(block_size));
		audio.push_audio_chunk(&music_audio, audio_samples_chunk);
		
		// NOTE(fakhri): copy the samples to result buffer
		{
			streaminfo := &flac_stream.streaminfo;
			
			range_min_val := (1 << (streaminfo.bits_per_sample - 1));
			range_max_val := (1 << (streaminfo.bits_per_sample - 1)) - 1;
			
			audio_samples_chunk.samples_count = int(block_size);
			for channel_index in 0..<nb_channels {
				for sample_index in 0..<int(block_size) {
					sample_value := f32(block_samples[channel_index].samples[sample_index]);
					sample_value = math.remap(sample_value, -f32(range_min_val), f32(range_max_val), -1, 1);
					audio_samples_chunk.channels[channel_index].samples[sample_index] = sample_value;
				}
			}
		}
		
	}
	
	fmt.println("Done.");
	
	fmt.println("Channels Count:", music_audio.channels_count);
	fmt.println("Sample Rate:", music_audio.sample_rate);
	fmt.println("Samples Count:", music_audio.samples_count);
	
	playback_buffer: Audio_Playback_Buffer = {
		music_audio = music_audio,
		samples_chunk = music_audio.first_sample_chunk,
		cursor_in_chunk = 0,
	};
	
	config := ma.device_config_init(.playback);
	config.playback.format   = .f32;  // Set to ma_format_unknown to use the device's native format.
	config.playback.channels = music_audio.channels_count;     // Set to 0 to use the device's native channel count.
	config.sampleRate        = music_audio.sample_rate; // Set to 0 to use the device's native sample rate.
	config.dataCallback      = audio_device_data; // Set to 0 to use the device's native sample rate.
	config.pUserData         = &playback_buffer; // Set to 0 to use the device's native sample rate.
	
	device: ma.device;
	if (ma.device_init(nil, &config, &device) != .SUCCESS) {
		fmt.println("failed to init miniaudio");
	}
	
	ma.device_start(&device);
	for !playback_buffer.playback_done {
	}
	
	ma.device_stop(&device);
}