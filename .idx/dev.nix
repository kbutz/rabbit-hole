{ pkgs, ... }:
let
  python-with-packages = pkgs.python3.withPackages (ps: [
    ps.fastapi
    ps.uvicorn
    ps.wikipedia
  ]);
in
{
  channel = "stable-24.05";

  packages = [
    python-with-packages
  ];

  idx = {
    extensions = [
      "ms-python.python"
    ];

    previews = {
      enable = true;
      previews = {
        web = {
          command = [
            "${python-with-packages}/bin/uvicorn",
            "main:app",
            "--host",
            "0.0.0.0",
            "--port",
            "$PORT",
            "--reload"
          ];
          manager = "web";
        };
      };
    };
  };
}
