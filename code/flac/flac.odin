package mplayer_flac

import "base:runtime"
import "core:os"
import "core:fmt"
import "src:audio"
import "src:bit_stream"

Flac_Stream_Info :: struct {
	min_block_size:  u16, // 16 bits
	max_block_size:  u16, // 16 bits
	min_frame_size:  u32, // 24 bits
	max_frame_size:  u32, // 24 bits
	sample_rate:     u32, // 20 bits
	nb_channels:     u8, // 3 bits
	bits_per_sample: u8, // 5 bits
	samples_count:   u64, // 36 bits
	md5_check:       u128,
}

Flac_Block_Strategy :: enum {
	Fixed_Size    = 0,
	Variable_Size = 1,
}

Flac_Stereo_Channel_Config :: enum {
	None,
	Left_Right,
	Left_Side,
	Side_Right,
	Mid_Side
}

Flac_Subframe_Constant  :: struct {};
Flac_Subframe_Verbatism :: struct {};
Flac_Subframe_Fixed_Prediction :: struct {order: u8};
Flac_Subframe_Linear_Prediction :: struct {order: u8};

Flac_Subframe_Type :: union {
	Flac_Subframe_Constant,
	Flac_Subframe_Verbatism,
	Flac_Subframe_Fixed_Prediction,
	Flac_Subframe_Linear_Prediction,
}

flac_sample_rates: []u32 = {
	88200,
	176400,
	192000,
	8000,
	16000,
	22050,
	24000,
	32000,
	44100,
	48000,
	96000,
}

flac_block_channel_count:  []u8 ={
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	2,
	2,
	2,
	0,
	0
}

flac_block_channel_config: []Flac_Stereo_Channel_Config = {
	.None,
	.Left_Right,
	.None,
	.None,
	.None,
	.None,
	.None,
	.None,
	.Left_Side,
	.Side_Right,
	.Mid_Side,
	.None,
	.None
}

Flac_Channel_Samples :: struct {
	samples: []i32,
}

decode_flac :: proc(data: []u8) -> (result: audio.Music_Audio)
{
	using bit_stream;
	
	// fLaC marker
	// STREAMINFO block
	// ... metadata blocks (127 different kinds of metadata blocks)
	// audio frames
	bitstream: bit_stream.Bit_Stream = {
		data = data,
		byte_index = 0,
		bits_left  = 8,
	}
	
	assert(bitstream_read_u8(&bitstream) == 'f');
	assert(bitstream_read_u8(&bitstream) == 'L');
	assert(bitstream_read_u8(&bitstream) == 'a');
	assert(bitstream_read_u8(&bitstream) == 'C');
	
	streaminfo: Flac_Stream_Info;
	
	md_blocks_count := 0;
	is_last_md_block := false;
	
	// NOTE(fakhri): parse meta data blocks
	for !is_last_md_block {
		md_blocks_count += 1;
		
		is_last_md_block = bool(bitstream_read_bits_unsafe(&bitstream, 1));
		md_type := u8(bitstream_read_bits_unsafe(&bitstream, 7));
		
		// NOTE(fakhri): big endian
		md_size := bitstream_read_u24be(&bitstream);
		// md_size := (u32(data[0]) << 16) | (u32(data[1]) << 8) | u32(data[2]);
		
		
		assert(md_type != 127);
		if md_blocks_count == 1 {
			// NOTE(fakhri): make sure the first meta data block is a streaminfo block
			// as per specification
			assert(md_type == 0);
		}
		
		switch md_type {
			case 0: {
				// NOTE(fakhri): streaminfo block
				assert(md_blocks_count == 1); // NOTE(fakhri): make sure we only have 1 streaminfo block
				
				streaminfo.min_block_size = bitstream_read_u16be(&bitstream);
				streaminfo.max_block_size = bitstream_read_u16be(&bitstream);
				
				streaminfo.min_frame_size = bitstream_read_u24be(&bitstream);
				streaminfo.max_frame_size = bitstream_read_u24be(&bitstream);
				
				streaminfo.sample_rate     = u32(bitstream_read_bits_unsafe(&bitstream, 20));
				streaminfo.nb_channels     = u8(bitstream_read_bits_unsafe(&bitstream, 3)) + 1;
				streaminfo.bits_per_sample = u8(bitstream_read_bits_unsafe(&bitstream, 5)) + 1;
				streaminfo.samples_count   = bitstream_read_bits_unsafe(&bitstream, 36);
				
				streaminfo.md5_check = bitstream_read_u128(&bitstream);
				
				// NOTE(fakhri): streaminfo checks
				{
					assert(streaminfo.min_block_size >= 16);
					assert(streaminfo.max_block_size >= streaminfo.min_block_size);
				}
			}
			case 1: {
				// NOTE(fakhri): padding
				bitstream_skip_bytes(&bitstream, int(md_size));
			}
			case 2: {
				// NOTE(fakhri): application
				bitstream_skip_bytes(&bitstream, int(md_size));
			}
			case 3: {
				// NOTE(fakhri): seektable
				bitstream_skip_bytes(&bitstream, int(md_size));
			}
			case 4: {
				// vorbis comment
				bitstream_skip_bytes(&bitstream, int(md_size));
			}
			case 5: {
				// NOTE(fakhri): cuesheet
				bitstream_skip_bytes(&bitstream, int(md_size));
			}
			case 6: {
				// NOTE(fakhri): Picture
				bitstream_skip_bytes(&bitstream, int(md_size));
			}
			case: {
				bitstream_skip_bytes(&bitstream, int(md_size));
				panic("Unkown block");
			}
		}
	}
	
	// NOTE(fakhri): decode frames
	for !bitstream_is_empty(&bitstream) {
		// TODO(fakhri): each frame can be decoded in parallel
		
		block_crc: u8;
		channel_config: Flac_Stereo_Channel_Config;
		nb_channels := streaminfo.nb_channels;
		sample_rate := streaminfo.sample_rate;
		bits_depth := streaminfo.bits_per_sample;
		block_size: u32;
		
		coded_number: u64 = 0;
		block_strat: Flac_Block_Strategy;
		
		// NOTE(fakhri): decode header
		{
			sync_code := bitstream_read_bits_unsafe(&bitstream, 15);
			assert(sync_code == 0x7ffc); // 0b111111111111100
			block_strat = Flac_Block_Strategy(bitstream_read_bits_unsafe(&bitstream, 1));
			
			block_size_bits  := bitstream_read_bits_unsafe(&bitstream, 4);
			sample_rate_bits := bitstream_read_bits_unsafe(&bitstream, 4);
			channels_bits    := bitstream_read_bits_unsafe(&bitstream, 4);
			bit_depth_bits   := bitstream_read_bits_unsafe(&bitstream, 3);
			assert(bitstream_read_bits_unsafe(&bitstream, 1) == 0); // reserved bit must be 0
			
			coded_byte0 := bitstream_read_u8(&bitstream);
			switch coded_byte0 { // 0xxx_xxxx
				case 0..=0x7F: {
					coded_number = u64(coded_byte0);
				}
				case 0xC0..=0xDF: { // 110x_xxxx 10xx_xxxx
					coded_byte1 := bitstream_read_u8(&bitstream);;
					assert(coded_byte1 & 0xC0 == 0x80);
					coded_number = (u64(coded_byte0 & 0x1F) << 6) | u64(coded_byte1 & 0x3F);
				}
				case 0xE0..=0xEF : { // 1110_xxxx 10xx_xxxx 10xx_xxxx
					coded_byte1 := bitstream_read_u8(&bitstream);;
					coded_byte2 := bitstream_read_u8(&bitstream);;
					
					assert(coded_byte1 & 0xC0 == 0x80);
					assert(coded_byte2 & 0xC0 == 0x80);
					coded_number = (u64(coded_byte0 & 0x0F) << 12) | (u64(coded_byte1 & 0x3F) << 6) | u64(coded_byte2 & 0x3F);
				}
				case 0xF0..=0xF7: { // 1111_0xxx 10xx_xxxx 10xx_xxxx 10xx_xxxx
					coded_byte1 := bitstream_read_u8(&bitstream);;
					coded_byte2 := bitstream_read_u8(&bitstream);;
					coded_byte3 := bitstream_read_u8(&bitstream);;
					
					assert(coded_byte1 & 0xC0 == 0x80);
					assert(coded_byte2 & 0xC0 == 0x80);
					assert(coded_byte3 & 0xC0 == 0x80);
					coded_number = (u64(coded_byte0 & 0x07) << 18) | (u64(coded_byte1 & 0x3F) << 12) | (u64(coded_byte2 & 0x3F) << 6) | u64(coded_byte3 & 0x3F);
				}
				case 0xF8..=0xFB: { // 1111_10xx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 
					coded_byte1 := bitstream_read_u8(&bitstream);;
					coded_byte2 := bitstream_read_u8(&bitstream);;
					coded_byte3 := bitstream_read_u8(&bitstream);;
					coded_byte4 := bitstream_read_u8(&bitstream);;
					
					assert(coded_byte1 & 0xC0 == 0x80);
					assert(coded_byte2 & 0xC0 == 0x80);
					assert(coded_byte3 & 0xC0 == 0x80);
					assert(coded_byte4 & 0xC0 == 0x80);
					coded_number = ((u64(coded_byte0 & 0x03) << 24) | 
						(u64(coded_byte1 & 0x3F) << 18) | 
						(u64(coded_byte2 & 0x3F) << 12) | 
						(u64(coded_byte3 & 0x3F) << 6)  |
						u64(coded_byte4 & 0x3F));
				}
				case 0xFC..=0xFD: { // 1111_110x 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 
					coded_byte1 := bitstream_read_u8(&bitstream);;
					coded_byte2 := bitstream_read_u8(&bitstream);;
					coded_byte3 := bitstream_read_u8(&bitstream);;
					coded_byte4 := bitstream_read_u8(&bitstream);;
					coded_byte5 := bitstream_read_u8(&bitstream);;
					
					assert(coded_byte1 & 0xC0 == 0x80);
					assert(coded_byte2 & 0xC0 == 0x80);
					assert(coded_byte3 & 0xC0 == 0x80);
					assert(coded_byte4 & 0xC0 == 0x80);
					assert(coded_byte5 & 0xC0 == 0x80);
					
					coded_number = ((u64(coded_byte0 & 0x01) << 30) | 
						(u64(coded_byte1 & 0x3F) << 24) | 
						(u64(coded_byte2 & 0x0F) << 18) | 
						(u64(coded_byte3 & 0x3F) << 12) | 
						(u64(coded_byte4 & 0x3F) << 6)  | 
						u64(coded_byte5 & 0x3F));
				}
				case 0xFE: {        // 1111_1110 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 
					coded_byte1 := bitstream_read_u8(&bitstream);;
					coded_byte2 := bitstream_read_u8(&bitstream);;
					coded_byte3 := bitstream_read_u8(&bitstream);;
					coded_byte4 := bitstream_read_u8(&bitstream);;
					coded_byte5 := bitstream_read_u8(&bitstream);;
					coded_byte6 := bitstream_read_u8(&bitstream);;
					
					assert(block_strat == .Variable_Size);
					
					assert(coded_byte1 & 0xC0 == 0x80);
					assert(coded_byte2 & 0xC0 == 0x80);
					assert(coded_byte3 & 0xC0 == 0x80);
					assert(coded_byte4 & 0xC0 == 0x80);
					assert(coded_byte5 & 0xC0 == 0x80);
					assert(coded_byte6 & 0xC0 == 0x80);
					
					coded_number = ((u64(coded_byte1 & 0x3F) << 30) | 
						(u64(coded_byte2 & 0x3F) << 24) | 
						(u64(coded_byte3 & 0x0F) << 18) | 
						(u64(coded_byte4 & 0x3F) << 12) | 
						(u64(coded_byte5 & 0x3F) << 6) | 
						u64(coded_byte6 & 0x3F));
				}
			}
			
			switch block_size_bits {
				case 0: {
					// NOTE(fakhri): reserved
					panic("block size using reserved bit");
				}
				case 1: {
					block_size = 192;
				}
				case 2..=5: {
					block_size = 144 << block_size_bits;
				}
				case 6: {
					block_size = u32(bitstream_read_u8(&bitstream)) + 1;
				}
				case 7: {
					block_size = u32(bitstream_read_u16le(&bitstream)) + 1;
				}
				case: {
					block_size = 1 << block_size_bits;
				}
			}
			
			switch sample_rate_bits {
				case 0: {
					// NOTE(fakhri): nothing
				}
				case 1..=11: {
					sample_rate = flac_sample_rates[sample_rate_bits - 1]
				}
				case 0xC: {
					sample_rate = u32(bitstream_read_u8(&bitstream)) * 1000;
				}
				case 0xD: {
					sample_rate = u32(bitstream_read_u16be(&bitstream));
				}
				case 0xE: {
					sample_rate = 10 * u32(bitstream_read_u16be(&bitstream));
				}
				case 0xF: {
					panic("forbidden sample rate bits pattern");
				}
			}
			
			nb_channels    = flac_block_channel_count[channels_bits];
			channel_config = flac_block_channel_config[channels_bits];
			block_crc = bitstream_read_u8(&bitstream);
		}
		
		temp := runtime.default_temp_allocator_temp_begin();
		defer runtime.default_temp_allocator_temp_end(temp);
		temp_alloc := runtime.arena_allocator(temp.arena);
		block_samples := make([]Flac_Channel_Samples, nb_channels, temp_alloc);
		
		// NOTE(fakhri): decode subframes
		for channel_index in 0..<nb_channels {
			block_channel_samples := &block_samples[channel_index];
			block_channel_samples.samples = make([]i32, block_size, temp_alloc);
			
			wasted_bits: u8;
			subframe_type: Flac_Subframe_Type;
			
			if bitstream_read_bits_unsafe(&bitstream, 1) != 0 {
				panic("first bit must start with 0");
			}
			subframe_type_bits := bitstream_read_bits_unsafe(&bitstream, 6);
			switch subframe_type_bits {
				case 0: {
					subframe_type = Flac_Subframe_Constant{};
				}
				case 1: {
					subframe_type = Flac_Subframe_Verbatism{};
				}
				case 0x08..=0xC: {
					subframe_type = Flac_Subframe_Fixed_Prediction{order =  u8(subframe_type_bits) - 8};
				}
				case 0x20..=0x3F: {
					subframe_type = Flac_Subframe_Linear_Prediction{order =  u8(subframe_type_bits) - 31};
				}
			}
			
			if bitstream_read_bits_unsafe(&bitstream, 1) == 1 { // NOTE(fakhri): has wasted bits
				wasted_bits = 1;
				
				for bitstream_read_bits_unsafe(&bitstream, 1) != 1 {
					wasted_bits += 1;
				}
			}
			else {
				// TODO(fakhri): is 0 encoded as unary in case we don't have wasted bits too?
			}
			
			sample_bit_depth := bits_depth - u8(wasted_bits);
			
			switch channel_config {
				case .Left_Side, .Mid_Side: {
					// NOTE(fakhri): increase bit depth by 1 in case this is a side channel
					if channel_index == 1 {
						sample_bit_depth += 1;
					}
				}
				case .Side_Right: {
					if channel_index == 0 {
						sample_bit_depth += 1;
					}
				}
				case .None, .Left_Right:;
			}
			
			switch v in subframe_type {
				case Flac_Subframe_Constant: {
					sample_value := bitstream_read_sample_unencoded(&bitstream, sample_bit_depth, wasted_bits);
					
					for i in 0..<block_size {
						block_channel_samples.samples[i] = sample_value;
					}
				}
				case Flac_Subframe_Verbatism: {
					for i in 0..<block_size {
						block_channel_samples.samples[i] = bitstream_read_sample_unencoded(&bitstream, sample_bit_depth, wasted_bits);
					}
				}
				case Flac_Subframe_Fixed_Prediction: {
					for i in 0..<v.order {
						block_channel_samples.samples[i] = bitstream_read_sample_unencoded(&bitstream, sample_bit_depth, wasted_bits);
					}
					
					flac_decode_coded_residuals(&bitstream, block_channel_samples, block_size, int(v.order));
					samples := block_channel_samples.samples;
					switch v.order {
						case 0: {
						}
						case 1: {
							for i in u32(v.order)..<block_size do samples[i] += samples[i - 1];
						}
						case 2: {
							for i in u32(v.order)..<block_size do samples[i] += 2 * samples[i - 1] - samples[i - 2];
						}
						case 3: {
							for i in u32(v.order)..<block_size do samples[i] += 3 * samples[i - 1] - 3 * samples[i - 2] + samples[i - 3];
						}
						case 4: {
							for i in u32(v.order)..<block_size do samples[i] += 4 * samples[i - 1] - 6 * samples[i - 2] + 4 * samples[i - 3] - samples[i - 4];
						}
						case: {
							panic("invalid order");
						}
					}
				}
				case Flac_Subframe_Linear_Prediction: {
					for i in 0..<v.order {
						block_channel_samples.samples[i] = bitstream_read_sample_unencoded(&bitstream, sample_bit_depth, wasted_bits);
					}
					
					predictor_coef_precision_bits := bitstream_read_bits_unsafe(&bitstream, 4);
					assert(predictor_coef_precision_bits != 0xF);
					predictor_coef_precision_bits += 1;
					right_shift := bitstream_read_bits_unsafe(&bitstream, 5);
					
					coefficients := make([]i32, v.order, temp_alloc);
					for i in 0..<v.order {
						coefficients[i] = bitstream_read_sample_unencoded(&bitstream, u8(predictor_coef_precision_bits), 0);
					}
					
					flac_decode_coded_residuals(&bitstream, block_channel_samples, block_size, int(v.order));
					samples := block_channel_samples.samples;
					for i in u32(v.order)..<block_size {
						predictor_value: i32;
						for c, j in coefficients {
							sample_val := samples[int(i) - j - 1];
							predictor_value += c * sample_val;
						}
						predictor_value >>= right_shift;
						samples[i] += predictor_value;
					}
				}
			}
		}
		
		// NOTE(fakhri): undo channel decoration
		switch channel_config {
			case .Left_Side: {
				for i in 0..<block_size {
					block_samples[1].samples[i] += block_samples[0].samples[i];
				}
			}
			case .Side_Right: {
				for i in 0..<block_size {
					block_samples[0].samples[i] += block_samples[1].samples[i];
				}
			}
			case .Mid_Side: {
				for i in 0..<block_size {
					mid := block_samples[0].samples[i];
					dif := block_samples[1].samples[i];
					
					block_samples[0].samples[i] = (2 * mid + dif) >> 1;
					block_samples[1].samples[i] = (2 * mid - dif) >> 1;
				}
			}
			case .None, .Left_Right: // nothing
		}
		
		// NOTE(fakhri): decode footer
		{
			bitstream_advance_to_next_byte_boundary(&bitstream);
			crc := bitstream_read_bits_unsafe(&bitstream, 16);
		}
	}
	
	return;
}


flac_decode_coded_residuals :: proc(bitstream: ^bit_stream.Bit_Stream, block_samples: ^Flac_Channel_Samples, block_size: u32, order: int) {
	using bit_stream;
	params_bits: u8;
	escape_code: u8;
	switch bitstream_read_bits_unsafe(bitstream, 2) {
		case 0: {
			params_bits = 4;
			escape_code = 0xF;
		}
		case 1: {
			params_bits = 5;
			escape_code = 0x1F;
		}
		case: {
			panic("reserved");
		}
	}
	
	partition_order := bitstream_read_bits_unsafe(bitstream, 4);
	partition_count := 1 << partition_order;
	sample_index := order;
	for part_index in 0..<partition_count {
		residual_samples_count := (block_size >> partition_order) - u32((part_index == 0)? order:0);
		paramter := u8(bitstream_read_bits_unsafe(bitstream, params_bits));
		if paramter == escape_code {
			// NOTE(fakhri): escape partition
			residual_bits_precision := u8(bitstream_read_bits_unsafe(bitstream, 5));
			if residual_bits_precision != 0 {
				for res_index in 0..<residual_samples_count {
					block_samples.samples[sample_index] = bitstream_read_sample_unencoded(bitstream, residual_bits_precision, 0);
					sample_index += 1;
				}
			}
		} else {
			// TODO(fakhri): check appendix D from the specification
			for _ in 0..<residual_samples_count {
				msp: i32 = 0;
				for bitstream_read_bits_unsafe(bitstream, 1) == 0 {
					msp += 1;
				}
				lsp := i32(bitstream_read_bits_unsafe(bitstream, paramter));
				
				sample_value: i32 = 0;
				folded_sample_value := (msp << paramter) | lsp;
				sample_value = folded_sample_value >> 1;
				if folded_sample_value & 1 == 1 {
					sample_value = ~sample_value;
				}
				
				block_samples.samples[sample_index] = sample_value;
				sample_index += 1;
			}
		}
	}
}
