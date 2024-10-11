package flac_odin

import "base:runtime"
import mem_virtual "core:mem/virtual"
import "core:mem"
import "core:os"
import "core:fmt"
import "core:time"
import "src:flac"

import ma "vendor:miniaudio"

Audio_Playback_Buffer :: struct {
	playback_done: bool,
	flac_stream: ^flac.Flac_Stream,
}

audio_device_data :: proc "c" (device: ^ma.device, output_buf, input_buf: rawptr, frame_count: u32) {
	context = runtime.default_context();
	playback_buffer := cast(^Audio_Playback_Buffer)device.pUserData;
	channels_count := int(device.playback.channels);
	
	streamed_samples, frames_count := flac.read_samples(playback_buffer.flac_stream, int(frame_count));
	defer delete(streamed_samples);
	
	if frames_count == 0 {
		playback_buffer.playback_done = true;
		return;
	}
	
	mem.copy(output_buf, raw_data(streamed_samples), frames_count * channels_count * size_of(f32));
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
	flac_stream: flac.Flac_Stream;
	flac.init_flac_stream(&flac_stream, data);
	
	samples: [dynamic]f32;
	defer delete(samples);
	fmt.println("Done.");
	
	fmt.println("Channels Count:", flac_stream.streaminfo.nb_channels);
	fmt.println("Sample Rate:", flac_stream.streaminfo.sample_rate);
	
	playback_buffer: Audio_Playback_Buffer = {
		flac_stream = &flac_stream,
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
		time.sleep(1000);
	}
	
	ma.device_stop(&device);
}