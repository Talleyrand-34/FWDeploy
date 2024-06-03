#!/usr/bin/env -S ERL_FLAGS=+B elixir
Mix.install([{:ex_doc, "~> 0.24", only: :dev, runtime: false}, {:earmark, "~> 1.4"}])

if System.get_env("DEPS_ONLY") == "true" do
  System.halt(0)
  Process.sleep(:infinity)
end



# --------------------------------------------------------------------------------
defmodule DeployMd do
  @moduledoc """
  Module to deploy Markdown files.
  """

  @doc """
  Process a Markdown file.
  """
  def md_to_html(file) do
    case File.read(file) do
      {:ok, content} ->
        # Convert markdown to HTML using Earmark
        {:ok, html_content, _} = Earmark.as_html(content)

        # Transform links in the HTML content
        transformed_html = TransformLinks.transform_links(html_content)

        {:ok, transformed_html}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Process Markdown files in a given directory and write HTML files.
  """
  def process_md_files(input_path, output_path) do
    md_files =
      File.ls!(input_path)
      |> Enum.filter(&(Path.extname(&1) == ".md"))

    if Enum.empty?(md_files) do
      IO.puts("No markdown files found in the directory: #{input_path}")
      System.halt(1)
    else
      # Enum.each(md_files, fn file ->
      #     IO.puts("Processing #{file}")
      #     {_, transformed_html} = md_to_html(Path.join([input_path, file]))
      #     write_path = Path.join([output_path, GenerateDefname.generate_defname(file) <> ".html"])
      #     File.write!(write_path, transformed_html)
      #     IO.puts("Processed and copied #{file} to #{write_path}")
      #   end)
      Task.async_stream(md_files, fn file ->
        IO.puts("Processing #{file}")
        {_, transformed_html} = md_to_html(Path.join([input_path, file]))
        write_path = Path.join([output_path, GenerateDefname.generate_defname(file) <> ".html"])
        File.write!(write_path, transformed_html)
        IO.puts("Processed and copied #{file} to #{write_path}")
      end)

      # Await all tasks with a timeout of 10 seconds
      |> Stream.run()

      # Task.await_many(tasks)
    end
  end
end

# --------------------------------------------------------------------------------
defmodule GenerateDefname do
  @moduledoc """
  Module to generate defname from a filename.
  """

  @doc """
  Function to generate defname from a filename.
  """

  def generate_defname([]), do: []

  def generate_defname(file) do
    defname =
      file
      |> String.replace_suffix(".md", "")
      |> String.downcase()
      |> String.replace(" ", "_")
      |> String.replace("-", "_")

    defname
  end
end

# --------------------------------------------------------------------------------
# Transform md references to html links
# --------------------------------------------------------------------------------
defmodule TransformLinks do
  @moduledoc """
  Module to transform links in a file.
  """

  @doc """
  Transforms [[*]] into "<a href=*.html>* </a>".
  """

  def transform_links(input) do
    Regex.replace(
      ~r/\[\[(.*?)\]\]/,
      input,
      fn _, match, _ ->
        "<a href=#{GenerateDefname.generate_defname(match)}.html>#{match} </a>"
      end,
      global: true
    )
  end

end

# --------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------
defmodule Main do
  @args [
    help: :boolean,
    input: :string,
    output: :string
  ]

  def main(args) do
    {parsed, args} = OptionParser.parse!(args, strict: @args)
    IO.inspect(parsed)
    IO.inspect(args)
    cmd(parsed, args)
  end

  defp cmd([help: true], _), do: IO.puts(@moduledoc)

  defp cmd(parsed, _args) do
    input_path = parsed[:input] || "./test/md/"
    output_path = parsed[:output] || "./test/html/"
    IO.puts("----")
    IO.inspect(input_path)
    IO.inspect(output_path)

    DeployMd.process_md_files(input_path, output_path)
  end
end

Main.main(System.argv())
