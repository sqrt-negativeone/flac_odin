package mplayer

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
	
	fmt.println("Reading file:", file_name);
	if !ok {return;}
	audio := flac.decode_flac(data);
	fmt.println("Done.");
	
	fmt.println("Channels Count:", audio.channels_count);
	fmt.println("Sample Rate:", audio.sample_rate);
	fmt.println("Samples Count:", audio.samples_count);
	
}