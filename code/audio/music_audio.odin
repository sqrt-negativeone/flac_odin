package flac_odin_audio


MAX_CHANNEL_COUNT :: 8

Channel_Samples :: struct {
	samples: []f32,
}

Audio_Samples_Chunk :: struct {
	next: ^Audio_Samples_Chunk,
	channels: [MAX_CHANNEL_COUNT]Channel_Samples,
	samples_count: int,
}


Music_Audio :: struct {
	sample_rate: u32,
	channels_count: u32,
	samples_count: int,
	first_sample_chunk: ^Audio_Samples_Chunk,
	last_sample_chunk:  ^Audio_Samples_Chunk,
}


make_audio_chunk :: proc(channels_count: u8, samples_count: int, allocator := context.allocator) -> (chunk: ^Audio_Samples_Chunk) {
	chunk = new(Audio_Samples_Chunk, allocator);
	chunk.next = nil;
	for i in 0..<channels_count {
		chunk.channels[i].samples = make([]f32, samples_count, allocator);
	}
	
	return;
}

push_audio_chunk :: proc(audio: ^Music_Audio, chunk: ^Audio_Samples_Chunk) {
	assert(audio != nil);
	assert(chunk != nil);
	if audio.first_sample_chunk == nil {
		audio.first_sample_chunk = chunk;
		audio.last_sample_chunk  = chunk;
	}
	else {
		assert(audio.last_sample_chunk != nil);
		audio.last_sample_chunk.next = chunk;
		audio.last_sample_chunk = chunk;
	}
	audio.samples_count += len(chunk.channels[0].samples);
}
