defmodule EventsourceEx.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eventsource_ex,
      version: "2.0.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: "An EventSource (Server-Sent Events) client.",
      name: "EventsourceEx",
      source_url: "https://github.com/cwc/eventsource_ex"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 1.5"},

      {:ex_doc, "~> 0.25.5", only: :dev, runtime: false, optional: true},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false, optional: true},
      {:mox, "~> 1.0", only: :test},
    ]
  end

  defp package do
    [
      name: :eventsource_ex,
      maintainers: ["cwc"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/cwc/eventsource_ex"}
    ]
  end
end
