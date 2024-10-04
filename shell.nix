{ pkgs ? import <nixpkgs> {} }: with pkgs; mkShell {
	packages = [
		ruby_3_2
		timidity
		alda
		soundfont-fluid
		ffmpeg_7
	];
	shellHook = ''
		export SOUNDFONT_FILENAME=${soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2
	'';
}
