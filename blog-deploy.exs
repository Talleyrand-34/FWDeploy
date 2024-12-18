#!/usr/bin/env -S ERL_FLAGS=+B elixir
Mix.install([{:ex_doc, "~> 0.24", only: :dev, runtime: false}, {:earmark, "~> 1.4"}])

if System.get_env("DEPS_ONLY") == "true" do
  System.halt(0)
  Process.sleep(:infinity)
end

defmodule PdfProcessor do
  def process_pdf_files(input_path, output_path) do
    # Ensure the output directory exists
    File.mkdir_p!(output_path)

    pdf_files =
      File.ls!(input_path)
      |> Enum.filter(&(Path.extname(&1) == ".pdf"))

    if Enum.empty?(pdf_files) do
      IO.puts("No PDF files found in the directory: #{input_path}")
    else
      Task.async_stream(pdf_files, fn file ->
        # Construct full paths for input and output
        input_file_path = Path.join(input_path, file)
        input_curated_file_path = Path.join(input_path, GenerateDefname.generate_defname(file) <> ".pdf")
        output_file_path = Path.join(output_path, GenerateDefname.generate_defname(file) <> ".html")

        # Process PDF
        IO.puts("Processing #{file}")

        # Call pdf_to_html to generate HTML for the PDF
        transformed_html = pdf_to_html(input_curated_file_path)

        # Write the generated HTML to the output path
        File.write!(output_file_path, transformed_html)

        # Copy the original PDF file to the output path
        File.cp!(input_file_path, Path.join(output_path, file))

        # Inform about successful processing
        IO.puts("Processed and copied #{file} to #{output_file_path}")
      end)
      |> Stream.run()
    end
  end

  def pdf_to_html(file) do
    # Generate an HTML string that includes an iframe for the PDF
    pdf_file_name = Path.basename(file)  # Get just the file name (e.g., "document.pdf")
    
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>PDF Viewer</title>
        <style>
            body, html {
                margin: 0;
                padding: 0;
                height: 100%; /* Full height for body and html */
            }
            .pdfviewer {
                width: 100%; /* Full width */
                height: 100vh; /* Full viewport height */
                border: none; /* Remove border */
            }
        </style>
    </head>
    <body>
        <object data="#{pdf_file_name}" type="application/pdf" width="100%" height="600px" class="pdfviewer">
            <p>Your browser does not support PDFs. <a href="#{pdf_file_name}">Download the PDF</a>.</p>
        </object>
    </body>
    </html>
    """
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
      |> String.replace_suffix(".pdf", "")
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
    PdfProcessor.process_pdf_files(input_path,output_path)
  end
end

Main.main(System.argv())
