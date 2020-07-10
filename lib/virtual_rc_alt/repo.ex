defmodule VirtualRcAlt.Repo do
  use Ecto.Repo,
    otp_app: :virtual_rc_alt,
    adapter: Ecto.Adapters.Postgres
end
