#!/usr/bin/env -S ERL_FLAGS=+B elixir
Mix.install([{:ex_doc, "~> 0.24", only: :dev, runtime: false}, {:earmark, "~> 1.4"}])

if System.get_env("DEPS_ONLY") == "true" do
  System.halt(0)
  Process.sleep(:infinity)
end

defmodule EmbeddedFiles do
  @moduledoc """
  Module for handling embedded files and creating HTML.
  """

  @doc """
  Creates an HTML file and copies necessary files to the destination.
  """
  def create_html_and_copy_files(input_path, output_path) do
    # Ensure the output directory exists
    File.mkdir_p!(output_path)

    # Create the HTML content
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Embedded Files</title>
    </head>
    <body>
        <h1>Embedded Files</h1>
        <p>This page contains embedded files.</p>
    </body>
    </html>
    """

    # Write the HTML content to a file
    html_file_path = Path.join(output_path, "index.html")
    File.write!(html_file_path, html_content)
    IO.puts("Created HTML file at #{html_file_path}")

    # Copy necessary files (e.g., PDFs, images) from input_path to output_path
    copy_files(input_path, output_path)
  end

  @doc """
  Copies necessary files from input_path to output_path.
  """
  defp copy_files(input_path, output_path) do
    # List all files in the input directory
    files_to_copy =
      File.ls!(input_path)
      |> Enum.filter(&valid_file_extension?/1)

    # Copy each valid file to the output directory
    Enum.each(files_to_copy, fn file ->
      source_file = Path.join(input_path, file)
      destination_file = Path.join(output_path, file)

      File.cp!(source_file, destination_file)
      IO.puts("Copied #{file} to #{destination_file}")
    end)
  end

  @doc """
  Checks if a file has a valid extension for copying.
  """
  defp valid_file_extension?(file) do
    ext = Path.extname(file)
    ext in [".pdf", ".jpg", ".png", ".gif"] # Add more extensions as needed
  end
end
defmodule OverloadHTML do
  @moduledoc """
  Add HTML features.
  """

  # Function to process flagged content and transform it into HTML (details/summary)
  def process_flagged_content(flagged_content) do
    # Split the flagged content into lines
    lines = String.split(flagged_content, "\n")

    # Transform lines into <details> and <summary> tags
    transformed_lines =
      lines
      |> Enum.map(fn line ->
        cond do
          String.starts_with?(line, "- ### ") -> "<h3>" <> String.trim_leading(line, "- ### ") <> "</h3>"
          String.starts_with?(line, "  - ") -> 
            item = String.trim_leading(line, "  - ")
            "<details>\n<summary>#{item}</summary>"
          String.starts_with?(line, "    - ") -> 
            item = String.trim_leading(line, "    - ")
            "#{item}\n</details>"
          true -> line
        end
      end)

    # Join the transformed lines back into a single string
    transformed_html = Enum.join(transformed_lines, "\n")

    # Wrap the transformed HTML in a <div> with the desired styles
    """
    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px;">
    #{transformed_html}
    </div>
    """
  end

  # Function to embed the transformed content back into the original content
  def embed_transformed_content(original_content) do
    # Define the flag to identify the section
    flag_start = "#!#!#!"
    flag_end = "#!#!#!"

    # Split the content using the flag
    split_content = String.split(original_content, ~r/#{flag_start}|#{flag_end}/)

    # Check if the split content has exactly three parts
    case split_content do
      [before_flag, flagged_content, after_flag] ->
        # Process flagged content manually
        transformed_html_flagged_content = process_flagged_content(flagged_content)

        # Process before and after content with Earmark
        {:ok, before_html, _} = Earmark.as_html(before_flag)
        {:ok, after_html, _} = Earmark.as_html(after_flag)

        # Embed the transformed content back into the original content
        final_content = before_html <> transformed_html_flagged_content <> after_html
        final_content

      _ ->
        # If the flag is not present, process the entire content with Earmark
        {:ok, html_content, _} = Earmark.as_html(original_content)
        html_content
    end
  end
end

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
        # Embed the transformed content back into the original content
        transformed_content = OverloadHTML.embed_transformed_content(content)

        # Transform links in the HTML content
        transformed_html = TransformLinks.transform_links(transformed_content)

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
      Task.async_stream(md_files, fn file ->
        #Process MD
        IO.puts("Processing #{file}")
        {_, transformed_html} = md_to_html(Path.join([input_path, file]))
        write_path = Path.join([output_path, GenerateDefname.generate_defname(file) <> ".html"])
        File.write!(write_path, transformed_html)
        IO.puts("Processed and copied #{file} to #{write_path}")
      end)
      |> Stream.run()
      # Process file embeding
      EmbeddedFiles.create_html_and_copy_files(input_path, output_path)

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
