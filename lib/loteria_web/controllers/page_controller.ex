defmodule LoteriaWeb.PageController do
  use LoteriaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
