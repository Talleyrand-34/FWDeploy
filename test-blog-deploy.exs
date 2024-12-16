# Load script.exs
Code.eval_file("blog-deploy.exs")

ExUnit.start()

defmodule AllTests do
  use ExUnit.Case
  alias PdfProcessor
  alias GenerateDefname

  describe "process_md_file/1" do
    test "transforms Markdown to HTML" do
      markdown_path = "test/md/index.md"
      expected_html_path = "test/html/index_real.html"
      {:ok, html_content} = DeployMd.md_to_html(markdown_path)

      expected_html_content = File.read!(expected_html_path)

      assert html_content == expected_html_content
    end
  end


  describe "generate_defname/1" do
    test "generates defname from filename" do
      assert GenerateDefname.generate_defname("README.md") == "readme"
    end

    test "handles filenames with spaces" do
      assert GenerateDefname.generate_defname("My File.md") == "my_file"
    end
    test "handles -" do
      assert GenerateDefname.generate_defname("My-File.md") == "my_file"
    end

    test "handles uppercase filenames" do
      assert GenerateDefname.generate_defname("TestFile.md") == "testfile"
    end

    test "handles filenames with multiple periods" do
      assert GenerateDefname.generate_defname("file.name.md") == "file.name"
    end

    test "returns empty string for empty filename" do
      assert GenerateDefname.generate_defname("") == ""
    end
  end

  describe "TransformLinks" do
    use ExUnit.Case

    import TransformLinks, only: [transform_links: 1]
    import GenerateDefname, only: [generate_defname: 1]

    test "transforms links correctly" do
      input = "This is a [[link1]] and this is [[link2]]."

      expected_output =
        "This is a <a href=link1.html>link1 </a> and this is <a href=link2.html>link2 </a>."

      actual_output = transform_links(input)

      assert actual_output == expected_output
    end

    test "generates definition name correctly" do
      file = "My File.md"
      expected_defname = "my_file"

      actual_defname = generate_defname(file)

      assert actual_defname == expected_defname
    end
  end
    describe "PdfProcessor" do

    test "processes PDF files and generates corresponding HTML" do#, %{input_path: input_path, output_path: output_path} do
    input_path= "test/md/"
    output_path= "test/html/"
      # Create a sample PDF file in the input directory for testing
      # sample_pdf = Path.join(input_path, "intro-fisica-cuantica.pdf")
      # File.write!(sample_pdf, "Sample PDF content")

      # Call the function to process PDF files
      PdfProcessor.process_pdf_files(input_path, output_path)

      # Check if the HTML file was created correctly
      expected_html_file = Path.join(output_path, "intro_fisica_cuantica.html")
      assert File.exists?(expected_html_file)

      # Read the generated HTML content for verification
      generated_html_content = File.read!(expected_html_file)
      expected_html_content = """
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
          <object data="intro_fisica_cuantica.pdf" type="application/pdf" width="100%" height="600px" class="pdfviewer">
              <p>Your browser does not support PDFs. <a href="intro_fisica_cuantica.pdf">Download the PDF</a>.</p>
          </object>
      </body>
    </html>
      """

      assert generated_html_content == expected_html_content

    end

    # test "handles case with no PDF files", %{input_path: input_path, output_path: output_path} do
    #   # Call the function when there are no PDFs to process
    #   assert capture_io(fn ->
    #     PdfProcessor.process_pdf_files(input_path, output_path)
    #   end) =~ "No PDF files found in the directory:"
    # end

  end
end

