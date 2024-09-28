package mplayer

import "core:os"
import "core:fmt"

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
	Right_Side,
	Mid_Side
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
	.Right_Side,
	.Mid_Side,
	.None,
	.None
}

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usegae:\n\t", os.args[0], " filename");
		return;
	}
	
	file_name := os.args[1];
	data, ok := os.read_entire_file_from_filename(file_name);
	defer delete(data);
	
	if !ok {return;}
	// fLaC marker
	// STREAMINFO block
	// ... metadata blocks (127 different kinds of metadata blocks)
	// audio frames
	assert(data[0] == 'f');
	assert(data[1] == 'L');
	assert(data[2] == 'a');
	assert(data[3] == 'C');
	
	streaminfo: Flac_Stream_Info;
	data = data[4:];
	md_blocks_count := 0;
	is_last_md_block := false;
	
	// NOTE(fakhri): parse meta data blocks
	for !is_last_md_block {
		md_blocks_count += 1;
		is_last_md_block = ((data[0] & 0x80) != 0);
		md_type := (data[0] & 0x7F);
		data = data[1:];
		// NOTE(fakhri): big endian
		md_size := (u32(data[0]) << 16) | (u32(data[1]) << 8) | u32(data[2]);
		
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
				
				streaminfo.min_block_size = (u16(data[0]) << 8) | u16(data[1]); data = data[2:];
				streaminfo.max_block_size = (u16(data[0]) << 8) | u16(data[1]); data = data[2:];
				
				streaminfo.min_frame_size = (u32(data[0]) << 16) | (u32(data[1]) << 8) | u32(data[2]); data = data[3:];
				streaminfo.max_frame_size = (u32(data[0]) << 16) | (u32(data[1]) << 8) | u32(data[2]); data = data[3:];
				
				streaminfo.sample_rate = (u32(data[0]) << 12) | (u32(data[1]) << 4) | (u32(data[2]) >> 4);
				streaminfo.nb_channels = (data[2] >> 1) & 0x3;
				streaminfo.bits_per_sample = ((data[2] & 0x1) << 4) | (data[3] >> 4);
				// 4 8 8 8 8
				streaminfo.samples_count = (u64(data[3] & 0x0F) << 32) | (u64(data[4]) << 24) | (u64(data[5]) << 16) | (u64(data[6]) << 8) | u64(data[7]);
				data = data[8:];
				
				// TODO(fakhri): test if this coversion is done correctly
				streaminfo.md5_check = u128((cast(^u128be)raw_data(data))^);
				data = data[16:];
				
				// NOTE(fakhri): streaminfo checks
				{
					assert(streaminfo.min_block_size >= 16);
					assert(streaminfo.max_block_size >= streaminfo.min_block_size);
				}
			}
			case 1: {
				// NOTE(fakhri): padding
				data = data[md_size:];
			}
			case 2: {
				// NOTE(fakhri): application
				data = data[md_size:];
			}
			case 3: {
				// NOTE(fakhri): seektable
				data = data[md_size:];
			}
			case 4: {
				// vorbis comment
				data = data[md_size:];
			}
			case 5: {
				// NOTE(fakhri): cuesheet
				data = data[md_size:];
			}
			case 6: {
				// NOTE(fakhri): Picture
				data = data[md_size:];
			}
			case: {
				data = data[md_size:];
				panic("Unkown block");
			}
		}
	}
	
	// NOTE(fakhri): decode frames
	for {
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
			sync_code := ((u16(data[0]) << 8) | u16(data[1])) & 0xFFFE;
			assert(sync_code == 0xFFF8);
			block_strat = Flac_Block_Strategy(data[1] & 0x01);
			
			block_size_bits  := (data[2] >> 4);
			sample_rate_bits := data[2] & 0x0F;
			channels_bits    := (data[3] >> 4);
			bit_depth_bits   := (data[3] >> 1) & 0x07;
			assert(data[3] & 0x01 == 0); // reserved bit must be 0
			data = data[4:];
			
			switch data[0] { // 0xxx_xxxx
				case 0..=0x7F: {
					coded_number = u64(data[0]);
				}
				case 0xC0..=0xDF: { // 110x_xxxx 10xx_xxxx
					assert(data[1] & 0xC0 == 0x80);
					coded_number = (u64(data[0] & 0x1F) << 6) | u64(data[1] & 0x3F);
					data = data[2:];
				}
				case 0xE0..=0xEF : { // 1110_xxxx 10xx_xxxx 10xx_xxxx
					assert(data[1] & 0xC0 == 0x80);
					assert(data[2] & 0xC0 == 0x80);
					coded_number = (u64(data[0] & 0x0F) << 12) | (u64(data[1] & 0x3F) << 6) | u64(data[2] & 0x3F);
					data = data[3:];
				}
				case 0xF0..=0xF7: { // 1111_0xxx 10xx_xxxx 10xx_xxxx 10xx_xxxx
					assert(data[1] & 0xC0 == 0x80);
					assert(data[2] & 0xC0 == 0x80);
					assert(data[3] & 0xC0 == 0x80);
					coded_number = (u64(data[0] & 0x07) << 18) | (u64(data[1] & 0x3F) << 12) | (u64(data[2] & 0x3F) << 6) | u64(data[3] & 0x3F);
					data = data[4:];
				}
				case 0xF8..=0xFB: { // 1111_10xx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 
					assert(data[1] & 0xC0 == 0x80);
					assert(data[2] & 0xC0 == 0x80);
					assert(data[3] & 0xC0 == 0x80);
					assert(data[4] & 0xC0 == 0x80);
					coded_number = (u64(data[0] & 0x03) << 24) | (u64(data[1] & 0x3F) << 18) | (u64(data[2] & 0x3F) << 12) | (u64(data[3] & 0x3F) << 6) | u64(data[4] & 0x3F);
					data = data[5:];
				}
				case 0xFC..=0xFD: { // 1111_110x 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 
					assert(data[1] & 0xC0 == 0x80);
					assert(data[2] & 0xC0 == 0x80);
					assert(data[3] & 0xC0 == 0x80);
					assert(data[4] & 0xC0 == 0x80);
					assert(data[5] & 0xC0 == 0x80);
					coded_number = (u64(data[0] & 0x01) << 30) | (u64(data[1] & 0x3F) << 24) | (u64(data[2] & 0x0F) << 18) | (u64(data[3] & 0x3F) << 12) | (u64(data[4] & 0x3F) << 6) | u64(data[5] & 0x3F);
					data = data[6:];
				}
				case 0xFE: {        // 1111_1110 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 10xx_xxxx 
					assert(block_strat == .Variable_Size);
					assert(data[1] & 0xC0 == 0x80);
					assert(data[2] & 0xC0 == 0x80);
					assert(data[3] & 0xC0 == 0x80);
					assert(data[4] & 0xC0 == 0x80);
					assert(data[5] & 0xC0 == 0x80);
					assert(data[6] & 0xC0 == 0x80);
					coded_number = (u64(data[1] & 0x3F) << 30) | (u64(data[2] & 0x3F) << 24) | (u64(data[3] & 0x0F) << 18) | (u64(data[4] & 0x3F) << 12) | (u64(data[5] & 0x3F) << 6) | u64(data[6] & 0x3F);
					data = data[7:];
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
					block_size = u32(data[0]) - 1;
					data = data[1:];
				}
				case 7: {
					block_size = u32((cast(^u16be)raw_data(data))^) - 1;
					data = data[2:]
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
					sample_rate = u32(data[0]) * 1000;
					data = data[1:];
				}
				case 0xD: {
					sample_rate = u32((cast(^u16be)raw_data(data))^);
					data = data[2:];
				}
				case 0xE: {
					sample_rate = 10 * u32((cast(^u16be)raw_data(data))^);
					data = data[2:];
				}
				case 0xF: {
					panic("forbidden sample rate bits pattern");
				}
			}
			
			nb_channels    = flac_block_channel_count[channels_bits];
			channel_config = flac_block_channel_config[channels_bits];
			block_crc = data[0];
			
			data = data[1:]
		}
		
		// NOTE(fakhri): decode subframes
		for _ in 0..<nb_channels {
			// TODO(fakhri): header
		}
		
		// NOTE(fakhri): decode footer
		{
		}
	}
}