package mplayer_bitsream


Bit_Stream :: struct {
	data: []u8,
	byte_index: int,
	bits_left: u8, // bits left in current byte
}

bitstream_is_empty :: proc(bitstream: ^Bit_Stream) -> bool {
	result := bitstream.byte_index == len(bitstream.data);
	return result;
}

bitstream_advance_to_next_byte_boundary :: proc(bitstream: ^Bit_Stream) {
	if bitstream.bits_left < 8 {
		bitstream.byte_index += 1;
		bitstream.bits_left = 8;
	}
}

bitstream_read_bits_unsafe :: proc(bitstream: ^Bit_Stream, bits: u8) -> (result: u64) {
	bits := bits;
	assert(bits <= 64);
	bytes_needed := (bits / 8) + u8(bool(bits % 8));
	
	// NOTE(fakhri): align to byte boundary
	if bitstream.bits_left != 8 && bits > bitstream.bits_left {
		bits_to_read := bitstream.bits_left;
		result = bitstream_read_bits_unsafe(bitstream, bits_to_read);
		bits -= bits_to_read;
		assert(bitstream.bits_left == 8);
	}
	
	for bits >= 8 {
		result <<= 8;
		result |= u64(bitstream.data[bitstream.byte_index]);
		bitstream.byte_index += 1;
		bits -= 8;
	}
	
	if bits != 0 && bits <= bitstream.bits_left {
		result <<= bits;
		result |= u64((bitstream.data[bitstream.byte_index] >> (bitstream.bits_left - bits)) & ((1 << bits) - 1));
		bitstream.bits_left -= bits;
		if bitstream.bits_left == 0 {
			bitstream.bits_left = 8;
			bitstream.byte_index += 1;
		}
	}
	
	return result;
}

bitstream_read_sample_unencoded :: proc(bitstream: ^Bit_Stream, sample_bit_depth, wasted_bits: u8) -> i32 {
	sample_value := i32(bitstream_read_bits_unsafe(bitstream, sample_bit_depth) << wasted_bits);
	bits_width := sample_bit_depth + wasted_bits;
	sample_sign_bit := i32(sample_value & (1 << (bits_width - 1)));
	mask_bits := i32(sample_sign_bit << (32 - bits_width));
	mask_bits >>= 32 - bits_width;
	sample_value |= mask_bits;
	return i32(sample_value);
}

bitstream_read_u8 :: proc(bitstream: ^Bit_Stream) -> (result: u8) {
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	result = data[byte_index];
	byte_index += 1;
	return;
}

bitstream_read_u16be :: proc(bitstream: ^Bit_Stream) -> (result: u16) {
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	result = (u16(data[byte_index]) << 8) | u16(data[byte_index + 1]);
	byte_index += 2;
	return;
}

bitstream_read_u16le :: proc(bitstream: ^Bit_Stream) -> (result: u16) {
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	result = (u16(data[byte_index + 1]) << 8) | u16(data[byte_index]);
	byte_index += 2;
	return;
}

bitstream_read_u24be :: proc(bitstream: ^Bit_Stream) -> (result: u32) {
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	result = (u32(data[byte_index]) << 16) | (u32(data[byte_index + 1]) << 8) | u32(data[byte_index + 2]);
	byte_index += 3;
	return;
}

bitstream_read_u32be :: proc(bitstream: ^Bit_Stream) -> (result: u32) {
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	result = (u32(data[byte_index]) << 24) | (u32(data[byte_index + 1]) << 16) | (u32(data[byte_index + 2]) << 8) | u32(data[byte_index + 3]);
	byte_index += 4;
	return;
}


bitstream_read_u128 :: proc(bitstream: ^Bit_Stream) -> (result: u128) {
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	// TODO(fakhri): test if this cast produces correct result?
	result = u128((cast(^u128be)raw_data(data[byte_index:]))^);
	byte_index += 16;
	return;
}

bitstream_skip_bytes :: proc(bitstream: ^Bit_Stream, bytes_count: int){
	using bitstream;
	
	// NOTE(fakhri): make sure we are at byte boundary
	assert(bits_left == 8);
	byte_index += bytes_count;
	return;
}
