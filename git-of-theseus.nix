{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonApplication rec {
	pname = "git-of-theseus";
	version = "0.3.4";
	pyproject = true;

	src = fetchFromGitHub {
		owner = "erikbern";
		repo = "git-of-theseus";
		rev = "1d77f08";
		hash = "sha256-PUCZjMgTgAB996AsDDJXS8uCpR5Q1W2cECGV4htjhKI=";
	};

	build-system = with python3Packages; [
		setuptools
	];

	dependencies = with python3Packages; [
		gitpython
		numpy
		tqdm
		wcmatch
		pygments
		matplotlib
	];
}
