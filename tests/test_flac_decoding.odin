package test_flac

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "base:runtime"
import "src:flac"
import "core:testing"

appendix_d_example1_data := []u8 {
	0x66, 0x4c, 0x61, 0x43, 0x80, 0x00, 0x00, 0x22, 0x10, 0x00, 0x10, 0x00, // fLaC..."....
	0x00, 0x00, 0x0f, 0x00, 0x00, 0x0f, 0x0a, 0xc4, 0x42, 0xf0, 0x00, 0x00, // ........B...
	0x00, 0x01, 0x3e, 0x84, 0xb4, 0x18, 0x07, 0xdc, 0x69, 0x03, 0x07, 0x58, // ..>.....i..X
	0x6a, 0x3d, 0xad, 0x1a, 0x2e, 0x0f, 0xff, 0xf8, 0x69, 0x18, 0x00, 0x00, // j=......i...
	0xbf, 0x03, 0x58, 0xfd, 0x03, 0x12, 0x8b, 0xaa, 0x9a,                   // ..X......
}

appendix_d_example2_data := []u8 {
	0x66, 0x4c, 0x61, 0x43, 0x00, 0x00, 0x00, 0x22, 0x00, 0x10, 0x00, 0x10,  // fLaC..."....
	0x00, 0x00, 0x17, 0x00, 0x00, 0x44, 0x0a, 0xc4, 0x42, 0xf0, 0x00, 0x00,  // .....D..B...
	0x00, 0x13, 0xd5, 0xb0, 0x56, 0x49, 0x75, 0xe9, 0x8b, 0x8d, 0x8b, 0x93,  // ....VIu.....
	0x04, 0x22, 0x75, 0x7b, 0x81, 0x03, 0x03, 0x00, 0x00, 0x12, 0x00, 0x00,  // ."u{........
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ............
	0x00, 0x00, 0x00, 0x10, 0x04, 0x00, 0x00, 0x3a, 0x20, 0x00, 0x00, 0x00,  // .......: ...
	0x72, 0x65, 0x66, 0x65, 0x72, 0x65, 0x6e, 0x63, 0x65, 0x20, 0x6c, 0x69,  // reference li
	0x62, 0x46, 0x4c, 0x41, 0x43, 0x20, 0x31, 0x2e, 0x33, 0x2e, 0x33, 0x20,  // bFLAC 1.3.3
	0x32, 0x30, 0x31, 0x39, 0x30, 0x38, 0x30, 0x34, 0x01, 0x00, 0x00, 0x00,  // 20190804....
	0x0e, 0x00, 0x00, 0x00, 0x54, 0x49, 0x54, 0x4c, 0x45, 0x3d, 0xd7, 0xa9,  // ....TITLE=..
	0xd7, 0x9c, 0xd7, 0x95, 0xd7, 0x9d, 0x81, 0x00, 0x00, 0x06, 0x00, 0x00,  // ............
	0x00, 0x00, 0x00, 0x00, 0xff, 0xf8, 0x69, 0x98, 0x00, 0x0f, 0x99, 0x12,  // ......i.....
	0x08, 0x67, 0x01, 0x62, 0x3d, 0x14, 0x42, 0x99, 0x8f, 0x5d, 0xf7, 0x0d,  // .g.b=.B..]..
	0x6f, 0xe0, 0x0c, 0x17, 0xca, 0xeb, 0x21, 0x00, 0x0e, 0xe7, 0xa7, 0x7a,  // o.....!....z
	0x24, 0xa1, 0x59, 0x0c, 0x12, 0x17, 0xb6, 0x03, 0x09, 0x7b, 0x78, 0x4f,  // $.Y......{xO
	0xaa, 0x9a, 0x33, 0xd2, 0x85, 0xe0, 0x70, 0xad, 0x5b, 0x1b, 0x48, 0x51,  // ..3...p.[.HQ
	0xb4, 0x01, 0x0d, 0x99, 0xd2, 0xcd, 0x1a, 0x68, 0xf1, 0xe6, 0xb8, 0x10,  // .......h....
	0xff, 0xf8, 0x69, 0x18, 0x01, 0x02, 0xa4, 0x02, 0xc3, 0x82, 0xc4, 0x0b,  // ..i.........
	0xc1, 0x4a, 0x03, 0xee, 0x48, 0xdd, 0x03, 0xb6, 0x7c, 0x13, 0x30,        // .J,..H...|.0
}

appendix_d_example3_data := []u8 {
	0x66, 0x4c, 0x61, 0x43, 0x80, 0x00, 0x00, 0x22, 0x10, 0x00, 0x10, 0x00, // fLaC..."....
	0x00, 0x00, 0x1f, 0x00, 0x00, 0x1f, 0x07, 0xd0, 0x00, 0x70, 0x00, 0x00, // .........p..
	0x00, 0x18, 0xf8, 0xf9, 0xe3, 0x96, 0xf5, 0xcb, 0xcf, 0xc6, 0xdc, 0x80, // ............
	0x7f, 0x99, 0x77, 0x90, 0x6b, 0x32, 0xff, 0xf8, 0x68, 0x02, 0x00, 0x17, // ..w.k2..h...
	0xe9, 0x44, 0x00, 0x4f, 0x6f, 0x31, 0x3d, 0x10, 0x47, 0xd2, 0x27, 0xcb, // .D.Oo1=.G.'.
	0x6d, 0x09, 0x08, 0x31, 0x45, 0x2b, 0xdc, 0x28, 0x22, 0x22, 0x80, 0x57, // m..1E+.("".W
	0xa3,                                                                   // .
	
}

@test
test_flac_decode_appendix_d_example1 :: proc(t: ^testing.T) {
	music_audio := flac.decode_flac(appendix_d_example1_data);
}

@test
test_flac_decode_appendix_d_example2 :: proc(t: ^testing.T) {
	music_audio := flac.decode_flac(appendix_d_example2_data);
}

@test
test_flac_decode_appendix_d_example3 :: proc(t: ^testing.T) {
	music_audio := flac.decode_flac(appendix_d_example3_data);
}


test_decoding_flac_file :: proc(info: os.File_Info, in_err: os.Errno, user_data: rawptr) -> (err: os.Errno, skip_dir: bool) {
	if !info.is_dir {
		temp := runtime.default_temp_allocator_temp_begin();
		defer runtime.default_temp_allocator_temp_end(temp);
		temp_alloc := runtime.arena_allocator(temp.arena);
		
		file_ext := filepath.ext(info.fullpath);
		if file_ext == ".flac" {
			fmt.println("decoding: ", info.fullpath);
			data := os.read_entire_file_from_filename(info.fullpath, temp_alloc) or_return;
			music_audio := flac.decode_flac(data, temp_alloc);
		}
	}
	return;
}

@test
test_flac_decode_subset_test_files :: proc(t: ^testing.T) {
	// filepath.walk("../tests/flac-test-files/subset", test_decoding_flac_file, nil);
}

@test
test_flac_decode_blocksize_4096 :: proc(t: ^testing.T) {
	file_name := "../tests/flac-test-files/subset/01 - blocksize 4096.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_4608 :: proc(t: ^testing.T) {
	file_name := "../tests/flac-test-files/subset/02 - blocksize 4608.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_16 :: proc(t: ^testing.T) {
	file_name := "../tests/flac-test-files/subset/03 - blocksize 16.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_192 :: proc(t: ^testing.T) {
	file_name := "../tests/flac-test-files/subset/04 - blocksize 192.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_254 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/05 - blocksize 254.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_512 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/06 - blocksize 512.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_725 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/07 - blocksize 725.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_1000 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/08 - blocksize 1000.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_1937 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/09 - blocksize 1937.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_blocksize_2304 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/10 - blocksize 2304.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_partition_order_8 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/11 - partition order 8.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_qlp_precision_15 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/12 - qlp precision 15 bit.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_qlp_precision_2 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/13 - qlp precision 2 bit.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_wasted_bits :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/14 - wasted bits.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_only_verbatism_subframes :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/15 - only verbatim subframes.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_part_order_8_with_escape_parts :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/16 - partition order 8 containing escaped partitions.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_all_fixed_orders :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/17 - all fixed orders.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_precision_search :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/18 - precision search.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_35467Hz :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/19 - samplerate 35467Hz.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_39kHz :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/20 - samplerate 39kHz.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_22050Hz :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/21 - samplerate 22050Hz.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_12bps :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/22 - 12 bit per sample.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_8bps :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/23 - 8 bit per sample.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_variable_block_size_file_created_with_flake_revision_264 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/24 - variable blocksize file created with flake revision 264.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_variable_block_size_file_created_with_flake_revision_264_modified_to_create_smaller_blocks :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/25 - variable blocksize file created with flake revision 264, modified to create smaller blocks.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_var_blocksize_with_created_with_cuetool :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/26 - variable blocksize file created with CUETools.Flake 2.1.6.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_old_format_variable_block_size_created_with_flake :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/27 - old format variable blocksize file created with Flake 0.11.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_high_res_audio_default_settings :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/28 - high resolution audio, default settings.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_high_res_audio_blocksize_16384 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/29 - high resolution audio, blocksize 16384.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_high_resolution_audio_blocksize_13456 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/30 - high resolution audio, blocksize 13456.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_high_resolution_audio_using_only_32nd_order_predictors :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/31 - high resolution audio, using only 32nd order predictors.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_high_resolution_audio_partition_order_8_containing_escape_partition :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/32 - high resolution audio, partition order 8 containing escaped partitions.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_high_resolution_audio_partition_order_8_containing_escaped_partitions :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/33 - samplerate 192kHz.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_192kHz :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/34 - samplerate 192kHz, using only 32nd order predictors.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_192kHz_using_only_32nd_order_predictors :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/35 - samplerate 134560Hz.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_134560Hz :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/36 - samplerate 384kHz.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_samplerate_384kHz :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/37 - 20 bit per sample.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_20_bit_per_sample :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/38 - 3 channels (3.0).flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_3_channels_3_0 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/39 - 4 channels (4.0).flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_4_channels_4_0 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/40 - 5 channels (5.0).flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_5_channels_5_0 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/41 - 6 channels (5.1).flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_6_channels_5_1 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/42 - 7 channels (6.1).flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_7_channels_6_1 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/43 - 8 channels (7.1).flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_8_channels_7_1 :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/44 - 8-channel surround, 192kHz, 24 bit, using only 32nd order predictors.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_8_channel_surround_192kHz_24_bit_using_only_32nd_order_predictors :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/45 - no total number of samples set.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_no_total_number_of_samples_set :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/46 - no min-max framesize set.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_no_min_max_framesize_set :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/47 - only STREAMINFO.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	defer delete(data);
	music_audio := flac.decode_flac(data);
	
}

@test
test_flac_decode_only_STREAMINFO :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/48 - Extremely large SEEKTABLE.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_Extremely_large_SEEKTABLE :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/49 - Extremely large PADDING.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_Extremely_large_PADDING :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/50 - Extremely large PICTURE.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_Extremely_large_PICTURE :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/51 - Extremely large VORBISCOMMENT.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_Extremely_large_VORBISCOMMENT :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/52 - Extremely large APPLICATION.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_Extremely_large_APPLICATION :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/53 - CUESHEET with very many indexes.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_CUESHEET_with_very_many_indexes :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/54 - 1000x repeating VORBISCOMMENT.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_1000x_repeating_VORBISCOMMENT :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/55 - file 48-53 combined.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_file_48_53_combined :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/56 - JPG PICTURE.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_JPG_PICTURE :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/57 - PNG PICTURE.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_PNG_PICTURE :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/58 - GIF PICTURE.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_GIF_PICTURE :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/59 - AVIF PICTURE.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_AVIF_PICTURE :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/60 - mono audio.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_mono_audio :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/61 - predictor overflow check, 16-bit.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_predictor_overflow_check_16bit :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/62 - predictor overflow check, 20-bit.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_predictor_overflow_check_20bit :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/63 - predictor overflow check, 24-bit.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}

@test
test_flac_decode_predictor_overflow_check_24bit :: proc(t:^testing.T) {
	file_name := "../tests/flac-test-files/subset/64 - rice partitions with escape code zero.flac";
	data, ok := os.read_entire_file_from_filename(file_name);
	music_audio := flac.decode_flac(data);
}