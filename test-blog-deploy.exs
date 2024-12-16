# Load script.exs
Code.eval_file("blog-deploy.exs")

ExUnit.start()

defmodule AllTests do
  use ExUnit.Case

  # describe "DeployMd" do
  describe "process_md_file/1" do
    test "transforms Markdown to HTML" do
      markdown_path = "test/md/index.md"
      expected_html_path = "test/html/index_real.html"
      {:ok, html_content} = DeployMd.md_to_html(markdown_path)

      expected_html_content = File.read!(expected_html_path)

      assert html_content == expected_html_content
    end
  end

  # end

  # describe "GenerateDefname" do
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
end
