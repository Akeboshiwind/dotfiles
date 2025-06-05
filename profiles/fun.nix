{ user, ... }:
{ ... }: {
  # Fun stuff :D

  imports = [
    (import ../modules/llm { inherit user; } )
  ];
}
