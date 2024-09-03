{ lib, fetchFromGitHub, rustPlatform, sqlx-cli }: rustPlatform.buildRustPackage rec {
	pname = "autochroma";
	version = "0.2.1";

	src = fetchFromGitHub {
		owner = "Astralchroma";
		repo = "Autochroma";
		rev = version;
		hash = "sha256-pUAszanuLp82DHA5otbnddfmmNl+UdV9UZDTORO3JCQ=";
	};

	cargoHash = "sha256-dtUm3T6XWCC29Alt3Sb47Ufnomvqy0TOK2mqjkfhEb0=";

	SQLX_OFFLINE = true;
}
