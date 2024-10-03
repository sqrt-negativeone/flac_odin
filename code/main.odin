package mplayer

import "base:runtime"
import "core:os"
import "core:fmt"
import "src:flac"


main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usegae:\n\t", os.args[0], " filename");
		return;
	}
	
	file_name := os.args[1];
	data, ok := os.read_entire_file_from_filename(file_name);
	defer delete(data);
	
	if !ok {return;}
	flac.decode_flac(data);
	
}