package mplayer

import "base:runtime"
import mem_virtual "core:mem/virtual"
import "core:mem"
import "core:math"
import "core:os"
import "core:fmt"
import "src:flac"

import ma "vendor:miniaudio"

Audio_Playback_Buffer :: struct {
	playback_done: bool,
	samples: []f32,
}

audio_device_data :: proc "c" (device: ^ma.device, output_buf, input_buf: rawptr, frame_count: u32) {
	frame_count := frame_count;
	playback_buffer := cast(^Audio_Playback_Buffer)device.pUserData;
	
	channels_count := int(device.playback.channels);
	samples_left := len(playback_buffer.samples);
	samples_to_read := math.min(samples_left, channels_count * int(frame_count));
	if samples_left == 0 {
		playback_buffer.playback_done = true;
		return;
	}
	
	mem.copy(output_buf, raw_data(playback_buffer.samples), samples_to_read * size_of(f32));
	playback_buffer.samples = playback_buffer.samples[samples_to_read:];
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
	
	samples: [dynamic]f32;
	defer delete(samples);
	
	for {
		runtime.free_all(context.temp_allocator);
		block_samples, block_size := flac.decode_one_block(&flac_stream, context.temp_allocator);
		if block_size == 0 {
			break;
		}
		
		nb_channels := len(block_samples);
		
		// NOTE(fakhri): copy the samples to result buffer
		{
			streaminfo := &flac_stream.streaminfo;
			
			resample_factor := (1 << (streaminfo.bits_per_sample - 1));
			
			for sample_index in 0..<int(block_size) {
				for channel_index in 0..<nb_channels {
					sample_value := f32(block_samples[channel_index].samples[sample_index]) / f32(resample_factor);
					append(&samples, sample_value);
				}
			}
		}
	}
	
	fmt.println("Done.");
	
	fmt.println("Channels Count:", flac_stream.streaminfo.nb_channels);
	fmt.println("Sample Rate:", flac_stream.streaminfo.sample_rate);
	
	playback_buffer: Audio_Playback_Buffer = {
		samples = samples[:],
	};
	
	config := ma.device_config_init(.playback);
	config.playback.format   = .f32;  // Set to ma_format_unknown to use the device's native format.
	config.playback.channels = u32(flac_stream.streaminfo.nb_channels);     // Set to 0 to use the device's native channel count.
	config.sampleRate        = flac_stream.streaminfo.sample_rate; // Set to 0 to use the device's native sample rate.
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