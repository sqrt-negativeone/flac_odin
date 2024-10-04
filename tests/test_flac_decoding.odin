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
			
			fmt.println("Channels Count:", music_audio.channels_count);
			fmt.println("Sample Rate:",    music_audio.sample_rate);
			fmt.println("Samples Count:", music_audio.samples_count);
			fmt.println("----------------------------------------------------------------------");
		}
	}
	return;
}

@test
test_flac_decode_subset_test_files :: proc(t: ^testing.T) {
	filepath.walk("../tests/flac-test-files/subset", test_decoding_flac_file, nil);
}