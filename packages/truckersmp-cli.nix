# Copied from <https://github.com/iuricarras/nur-packages/blob/master/pkgs/truckersmp-cli/default.nix> as the package
# was broken and trying to override NUR repositories proved difficult. 
# 
# The license from the source is as follows:
# 
# MIT License
# 
# Copyright (c) 2018 Francesco Gazzetta
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

{
	fetchFromGitHub,
	lib,
	pkgs,
	pkgsCross,
	python312Packages,
	SDL2,
	steamcmd
}: let truckersmp-cli = python312Packages.buildPythonApplication {
	pname = "truckersmp-cli";
	version = "0.10.2.1";

	src = fetchFromGitHub {
		repo = "truckersmp-cli";
		owner = "truckersmp-cli";
		rev = "a50d9c06d19a4f7ef393a70611c91d4e7cf9a86e";
		sha256 = "sha256-BeSPmcbK5GTUWlT3Fhm0MDfA0Go8JlCxl/PHgUN3sX0=";
	};

	postPatch = ''
		substituteInPlace truckersmp_cli/variables.py --replace \
			'libSDL2-2.0.so.0' '${SDL2}/lib/libSDL2.so'

		substituteInPlace truckersmp_cli/steamcmd.py --replace \
			'steamcmd_path = os.path.join(Dir.steamcmddir, "steamcmd.sh")' \
			'steamcmd_path = "${steamcmd}/bin/steamcmd"'

		substituteInPlace truckersmp_cli/utils.py --replace \
			'"""Download files."""' 'print(files_to_download)'

		substituteInPlace truckersmp_cli/utils.py --replace \
			'[(newpath, dest, md5), ]' \
			'[(newpath, dest["abspath"], md5), ]'
		
		${pkgsCross.mingwW64.buildPackages.gcc}/bin/x86_64-w64-mingw32-gcc truckersmp-cli.c -o truckersmp_cli/truckersmp-cli.exe
	'';

	nativeBuildInputs = [ pkgsCross.mingwW64.buildPackages.gcc ];

	buildInputs = [ SDL2 steamcmd ];

	propagatedBuildInputs = with python312Packages; [ vdf ];
}; in pkgs.buildFHSEnv {
	pname = "truckersmp-cli";
	version = "0.10.2.1";
	targetPkgs = pkgs: [ truckersmp-cli ];
	runScript = "truckersmp-cli";

	meta = {
		description = "A simple launcher for TruckersMP to play ATS or ETS2 in multiplayer.";
		homepage = "https://github.com/truckersmp-cli/truckersmp-cli";
		license = lib.licenses.mit;
	};
}
